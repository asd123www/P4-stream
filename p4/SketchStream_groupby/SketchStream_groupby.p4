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

    bit<32> result1;
    bit<32> result2;
    bit<32> result3;

    bit<32> diff1;
    bit<32> diff2;
    bit<32> diff3;
}

#include "parser.p4"



// 得到最小值的Sketch.
control CountMin_Array(
    inout header_t hdr,
	inout metadata_t ig_md,
    in bit<HASH_WIDTH> idx,
    out bit<32> dest_field) {
    
    Register<bit<32>, bit<HASH_WIDTH>> (ARRAY_LENGTH, 0x7FFFFFFF) cs_table; // initial value is INT_MAX.

    RegisterAction<bit<32>, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            if (hdr.kvs.val_word.val_word_1.data < register_data) {
                register_data = hdr.kvs.val_word.val_word_1.data;
            }
            result = register_data;
        }
    };

    apply {
        dest_field = cs_action.execute(idx);
    }
}


// 整一个长度为8的.
control SketchStream_groupby(
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
    
    CountMin_Array() A1;
    CountMin_Array() A2;
    CountMin_Array() A3;

    apply {
        tbl_hash0.apply();
        tbl_hash1.apply();
        tbl_hash2.apply();


        A1.apply(hdr, ig_md, ig_md.hash_idx1, ig_md.result1);
        A2.apply(hdr, ig_md, ig_md.hash_idx2, ig_md.result2);
        A3.apply(hdr, ig_md, ig_md.hash_idx3, ig_md.result3);
        ig_md.diff1 = max(ig_md.result1, ig_md.result2);
        hdr.kvs.val_word.val_word_1.data = max(ig_md.diff1, ig_md.result3);
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

    SketchStream_groupby() func_1;

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