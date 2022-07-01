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
    bit<12> hash_idx;
    bit<32> hash1;
    bit<32> hash2;

    bit<32> ret1;
    bit<32> ret2;

    bit<8> is_equal0;
    bit<8> is_equal1;
}

#include "parser.p4"


control CacheArray(
        inout header_t hdr, 
        inout metadata_t ig_md)(bit<1> xor) {
    
    // cs_table1 & cs_table2 should have the same length.
    Register<bit<32>, bit<12>>(32w4096, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<12>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            result = register_data;

            if (xor == 1w0) 
                register_data = ig_md.ret1;
            else
                register_data = ig_md.ret2;
        }
    };

    apply {
        if (xor == 1w0) {
            ig_md.ret1 = cs_action.execute(ig_md.hash_idx);
            if (ig_md.ret1 == ig_md.hash1) ig_md.is_equal0 = 8w1;
        }
        else {
            ig_md.ret2 = cs_action.execute(ig_md.hash_idx);
            if (ig_md.ret2 == ig_md.hash2) ig_md.is_equal1 = 8w1;
        }
    }
}

control CacheLine(
        inout header_t hdr, 
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action apply_assign() {
        ig_md.is_equal0 = 8w0;
        ig_md.is_equal1 = 8w0;
    }


    table tbl_assign {
        actions = {
            apply_assign;
        }
        const default_action = apply_assign();
        size = 512;
    }

    CacheArray(1w0) array1;
    CacheArray(1w1) array2;

    apply {
        if (ig_dprsr_md.drop_ctl == 0) {
            tbl_assign.apply();

            array1.apply(hdr, ig_md);
            array2.apply(hdr, ig_md);

            if (ig_md.is_equal0 == 8w1 && ig_md.is_equal1 == 8w1) {// && ig_md.ret2 == ig_md.hash2) { // hit, drop the pkt.
                drop();
            }
        }
    }
}

control DistinctOperator(
        inout header_t hdr, 
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    CRCPolynomial<bit<32>>(32w0x6b8cb0c5, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly0;
    CRCPolynomial<bit<32>>(32w0x30243f0b, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly1;
    CRCPolynomial<bit<32>>(32w0x0f79f523, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly2;
    Hash<bit<12>>(HashAlgorithm_t.CRC32, poly1) hash0;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, poly2) hash2;

    action apply_hash0() {
        ig_md.hash_idx = hash0.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    action apply_hash1() {
        ig_md.hash1 = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    action apply_hash2() {
        ig_md.hash2 = hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
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

    action apply_assign() {
        ig_md.ret1 = ig_md.hash1;
        ig_md.ret2 = ig_md.hash2;
    }


    table tbl_assign {
        actions = {
            apply_assign;
        }
        const default_action = apply_assign();
        size = 512;
    }


    // cheetah default: w = 2, d = 4096.
    // Only LRU is tested, no FIFO thing.
    // Cache依赖性太强了, 开四个就15个stage了.
    CacheLine() array1;
    CacheLine() array2;

    apply {
        tbl_hash0.apply();
        tbl_hash1.apply();
        tbl_hash2.apply();

        tbl_assign.apply();
        array1.apply(hdr, ig_md, ig_dprsr_md);
        array2.apply(hdr, ig_md, ig_dprsr_md);
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

    DistinctOperator() func_1;

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