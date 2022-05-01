#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"


// bit<32>访问65536是否存在不确定性?
struct metadata_t {
    bit<32> key;
    bit<32> value;


    bit<12> hash_idx;
    bit<32> hash;

    bit <8> is_equal;
}

#include "parser.p4"


control CacheIdentity(
        inout header_t hdr, 
        inout metadata_t ig_md) {
    
    // cs_table1 & cs_table2 should have the same length.
    Register<bit<32>, bit<12>>(32w4096, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<12>, bit<8>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<8> result) {
            if (register_data == ig_md.key) {
                result = 8w1;
            }
            else {
                result = 8w0;
            }

            register_data = ig_md.key;
        }
    };

    apply {
        ig_md.is_equal = cs_action.execute(ig_md.hash_idx);
    }
}

control CacheValue(
        inout header_t hdr, 
        inout metadata_t ig_md) {
    
    // cs_table1 & cs_table2 should have the same length.
    Register<bit<32>, bit<12>>(32w4096, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<12>, bit<8>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<8> result) {
            if (ig_md.is_equal == 8w0) { // the key is different.
                register_data = ig_md.value;
                result = 8w0;
            }
            else { // the key is the same.
                if (ig_md.value <= register_data) { // GroupBy Max.
                    result = 8w1; // drop it.
                }
                else { // this pkt is bigger.
                    register_data = ig_md.value;
                    result = 8w0;
                }
            }
        }
    };

    apply {
        ig_md.is_equal = cs_action.execute(ig_md.hash_idx);
    }
}

control CacheLine(
        inout header_t hdr, 
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) (bit<8> incre) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    CRCPolynomial<bit<32>>(32w0x6b8cb0c5, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly;
    Hash<bit<12>>(HashAlgorithm_t.CRC32, poly) hash;
    
    action apply_hash() {
        ig_md.hash = ig_md.hash + (bit<32>)incre;
        ig_md.hash_idx = hash.get(ig_md.hash);
    }

    table tbl_hash {
        actions = {
            apply_hash;
        }
        const default_action = apply_hash();
        size = 512;
    }


    CacheIdentity() Id;
    CacheValue() Value;

    apply {
        tbl_hash.apply();

        if (ig_dprsr_md.drop_ctl == 0) {
            Id.apply(hdr, ig_md);
            Value.apply(hdr, ig_md);

            if (ig_md.is_equal == 8w1) drop();
        }
    }
}

control GroupByOperator(
        inout header_t hdr, 
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    
    CRCPolynomial<bit<32>>(32w0x30243f0b, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, poly) hash;

    action apply_hash() {
        ig_md.hash = hash.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    table tbl_hash {
        actions = {
            apply_hash;
        }
        const default_action = apply_hash();
        size = 512;
    }

    action apply_storing() {
        ig_md.key = ig_md.hash;
        ig_md.value = hdr.kvs.val_word.val_word_1.data;
    }

    table store_value {
        actions = {
            apply_storing;
        }
        const default_action = apply_storing();
        size = 512;
    }


    CacheLine(8w3) array1;
    CacheLine(8w2) array2;
    CacheLine(8w2) array3;
    // CacheLine(8w2) array4;

    apply {
        tbl_hash.apply();
        store_value.apply();

        /*
        之前的写法在这里赋值, 但是发现写成table之后stage数量减少的很多, 为什么?
        ig_md.key = ig_md.hash;
        ig_md.value = hdr.kvs.val_word.val_word_1.data;
        */

        array1.apply(hdr, ig_md, ig_dprsr_md);
        array2.apply(hdr, ig_md, ig_dprsr_md);
        array3.apply(hdr, ig_md, ig_dprsr_md);
        // array4.apply(hdr, ig_md, ig_dprsr_md);
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

    GroupByOperator() func_1;

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