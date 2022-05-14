#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"


#define HASH_WIDTH 12
#define ARRAY_LENGTH 32w4096
const int FlowAID = 16w1;
const int FlowBID = 16w2;

// bit<32>访问65536是否存在不确定性?
struct metadata_t {
    bit<HASH_WIDTH> hash_idx1; // index hash.
    bit<HASH_WIDTH> hash_idx2; // index hash.
    bit<HASH_WIDTH> hash_idx3; // index hash.

    bit sgn;
    bit insert;
}

#include "parser.p4"




control BloomFilter(
		inout header_t hdr,
		inout metadata_t ig_md,
        in bit<HASH_WIDTH> idx) {
            
    Register<bit, bit<HASH_WIDTH>>(ARRAY_LENGTH, 0) cs_table; // initial value is 0.

    RegisterAction<bit, bit<HASH_WIDTH>, bit>(cs_table) insert_action = {
        void apply(inout bit register_data, out bit result) {
            register_data = 1;
            result = register_data;
        }
    };
    RegisterAction<bit, bit<HASH_WIDTH>, bit>(cs_table) query_action = {
        void apply(inout bit register_data, out bit result) {
            result = register_data;
        }
    };

    apply {
        if (ig_md.insert == 1) { // insert.
            ig_md.sgn = insert_action.execute(idx);
        } else { // query.
            ig_md.sgn = query_action.execute(idx);
        }
    }
}



// 整一个长度为8的.
control Cheetah_join(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    CRCPolynomial<bit<32>>(32w0x6b8cb0c5, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly0;
    CRCPolynomial<bit<32>>(32w0x30243f0b, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly1;
    CRCPolynomial<bit<32>>(32w0x0f79f523, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly2;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly2) hash0;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly2) hash2;

    action apply_hash0() {
        ig_md.hash_idx1 = hash0.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    action apply_hash1() {
        ig_md.hash_idx2 = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    action apply_hash2() {
        ig_md.hash_idx3 = hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    table tbl_hash0 {
        actions = {
            apply_hash0;
        }
        const default_action = apply_hash0();
        size = 512;
    }

    table tbl_hash1 {
        actions = {
            apply_hash1;
        }
        const default_action = apply_hash1();
        size = 512;
    }

    table tbl_hash2 {
        actions = {
            apply_hash2;
        }
        const default_action = apply_hash2();
        size = 512;
    }

    BloomFilter() A1;
    BloomFilter() A2;
    BloomFilter() A3;
    BloomFilter() B1;
    BloomFilter() B2;
    BloomFilter() B3;

    apply {
        tbl_hash0.apply();
        tbl_hash1.apply();
        tbl_hash2.apply();

        if (hdr.my_header.qid >= 16w32768) {// high bits for second transmit like cheetah_join.
            ig_md.insert = 1;

            if ((hdr.my_header.qid | FlowAID) == 0xFFFF) { // first pass of flow A.
                A1.apply(hdr, ig_md, ig_md.hash_idx1);
                A2.apply(hdr, ig_md, ig_md.hash_idx2);
                A3.apply(hdr, ig_md, ig_md.hash_idx3);
            } else { // first pass of flow B.
                B1.apply(hdr, ig_md, ig_md.hash_idx1);
                B2.apply(hdr, ig_md, ig_md.hash_idx2);
                B3.apply(hdr, ig_md, ig_md.hash_idx3);
            }
            drop(); // we don't need them.
        } else {
            ig_md.insert = 0;

            if (hdr.my_header.qid == FlowAID) { // second pass of flow A.
                B1.apply(hdr, ig_md, ig_md.hash_idx1);
                if (ig_md.sgn == 0) {
                    drop();
                } else {
                    B2.apply(hdr, ig_md, ig_md.hash_idx2);
                    if (ig_md.sgn == 0) {
                        drop();
                    } else {
                        B3.apply(hdr, ig_md, ig_md.hash_idx3);
                        if (ig_md.sgn == 0) {
                            drop();
                        }
                    }
                }
            } else {
                A1.apply(hdr, ig_md, ig_md.hash_idx1);
                if (ig_md.sgn == 0) {
                    drop();
                } else {
                    A2.apply(hdr, ig_md, ig_md.hash_idx2);
                    if (ig_md.sgn == 0) {
                        drop();
                    } else {
                        A3.apply(hdr, ig_md, ig_md.hash_idx3);
                        if (ig_md.sgn == 0) {
                            drop();
                        }
                    }
                }
            }
        }
    }
}




control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 512;
        default_action = NoAction;
    }

    Cheetah_join() func_1;

    apply {
        // there is some disturbing pkts!!!
        if (hdr.udp.isValid()) func_1.apply(hdr, ig_md, ig_dprsr_md);

        ipv4_lpm.apply();
        
    }
}


/********  G L O B A L   E G R E S S   M E T A D A T A  *********/

parser EgressParser(packet_in        pkt,
    /* User */
    out empty_header_t          hdr,
    out empty_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control EgressDeparser(packet_out pkt,
    /* User */
    inout empty_header_t                       hdr,
    in    empty_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    EgressParser(),
    EmptyEgress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;