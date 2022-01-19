#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"

struct metadata_t {
	bit<16> sampling_hash_value;
    bit<10> level;
    bit<16> base;
    bit<32> threshold;

    bit<16> key_hash_1;
    bit<16> key_hash_2;
    bit<16> key_hash_3;
    bit<16> key_hash_4;
    bit<16> key_hash_5;
    

    bit<16> index_1;
    bit<16> index_2;
    bit<16> index_3;
    bit<16> index_4;
    bit<16> index_5;

    // bit<5> res_all;
    bit<16> res_all;
    bit<1> res_1;
    bit<1> res_2;
    bit<1> res_3;
    bit<1> res_4;
    bit<1> res_5;

    bit<32> est_1;
    bit<32> est_2;
    bit<32> est_3;
    bit<32> est_4;
    bit<32> est_5;

    bit<1> c_1;
    bit<1> c_2;
    bit<1> c_3;
    bit<1> c_4;
    bit<1> c_5;

    bit<1> above_threshold;
}

#include "parser.p4"

#include "API_common.p4"
//#include "API_O1_hash.p4"
//#include "API_O2_hash.p4"
//#include "API_O3_tcam.p4"
//#include "API_O5_salu.p4"
//#include "API_O6_flowkey.p4"
#include "API_threshold.p4"

control CM_HASH_KEY(
    inout header_t hdr,
    out bit<16> hash_output)(bit<32> polynomial) {
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    Hash<bit<16>>(HashAlgorithm_t.CUSTOM, poly1) hash1;
    apply {
        hash_output = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
}
control CM_UPDATE_KEY(
  in bit<16> hash_key,
  in bit<32> val,
  out bit<32> est)
{

    Register<bit<32>, bit<16>>(32w65536) cs_table;

    RegisterAction<bit<32>, bit<16>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + val;
            result = register_data;
        }
    };

    apply {
        est = cs_action.execute(hash_key);
    }
}



control heavy_key_hit (
    inout header_t hdr,
    inout metadata_t ig_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md){
    // threshold table
    action tbl_threshold_above_action() {
        ig_md.above_threshold = 1;
    }

    table tbl_threshold {
        key = {
            ig_md.c_1 : exact;
            ig_md.c_2 : exact;
            ig_md.c_3 : exact;
            ig_md.c_4 : exact;
            ig_md.c_5 : exact;
        }
        actions = {
            tbl_threshold_above_action;
        }
        size = 512;
    }
    apply {

        ig_md.est_1 = ig_md.est_1 - ig_md.threshold;
        ig_md.est_2 = ig_md.est_2 - ig_md.threshold;
        ig_md.est_3 = ig_md.est_3 - ig_md.threshold;
        ig_md.est_4 = ig_md.est_4 - ig_md.threshold;
        ig_md.est_5 = ig_md.est_5 - ig_md.threshold;

        ig_md.c_1 = (bit<1>) (ig_md.est_1 >> 31);
        ig_md.c_2 = (bit<1>) (ig_md.est_2 >> 31);
        ig_md.c_3 = (bit<1>) (ig_md.est_3 >> 31);
        ig_md.c_4 = (bit<1>) (ig_md.est_4 >> 31);
        ig_md.c_5 = (bit<1>) (ig_md.est_5 >> 31);

        tbl_threshold.apply();
    }
}

control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
        
    GET_THRESHOLD() get_threshold;

    CM_HASH_KEY(32w0x30243f0b) hash_1;
    CM_HASH_KEY(32w0x0f79f523) hash_2;
    CM_HASH_KEY(32w0x6b8cb0c5) hash_3;
    CM_HASH_KEY(32w0x00390fc3) hash_4;
    CM_HASH_KEY(32w0x298ac673) hash_5;

    CM_UPDATE_KEY() update_1;
    CM_UPDATE_KEY() update_2;
    CM_UPDATE_KEY() update_3;
    CM_UPDATE_KEY() update_4;
    CM_UPDATE_KEY() update_5;


    heavy_key_hit() hit_key;

    action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.kvs.val_word.val_word_1.data = ig_md.threshold;
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
        default_action = NoAction();
    }

    apply {
        get_threshold.apply(hdr, ig_md);

        hash_1.apply(hdr, ig_md.key_hash_1);
        hash_1.apply(hdr, ig_md.key_hash_2);
        hash_1.apply(hdr, ig_md.key_hash_3);
        hash_1.apply(hdr, ig_md.key_hash_4);
        hash_1.apply(hdr, ig_md.key_hash_5);

        update_1.apply(ig_md.key_hash_1, hdr.kvs.val_word.val_word_1.data, ig_md.est_1);
        update_2.apply(ig_md.key_hash_2, hdr.kvs.val_word.val_word_1.data, ig_md.est_2);
        update_3.apply(ig_md.key_hash_3, hdr.kvs.val_word.val_word_1.data, ig_md.est_3);
        update_4.apply(ig_md.key_hash_4, hdr.kvs.val_word.val_word_1.data, ig_md.est_4);
        update_5.apply(ig_md.key_hash_5, hdr.kvs.val_word.val_word_1.data, ig_md.est_5);
        
        hit_key.apply(hdr, ig_md, ig_tm_md);

        if(ig_md.above_threshold == 1) {
            
            ipv4_lpm.apply();
        }
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

