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

    bit<32> est_11;
    bit<32> est_12;
    bit<32> est_13;
    bit<32> est_14;
    bit<32> est_15;

    bit<1> c_1;
    bit<1> c_2;
    bit<1> c_3;
    bit<1> c_4;
    bit<1> c_5;

    bit<1> above_threshold;

    bit<1> flag;
}

#include "parser.p4"

//#include "API_common.p4"
//#include "API_O1_hash.p4"
//#include "API_O2_hash.p4"
//#include "API_O3_tcam.p4"
//#include "API_O5_salu.p4"
//#include "API_O6_flowkey.p4"
#include "API_threshold.p4"


control CM_UPDATE_KEY(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_1.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_1.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
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
        
    GET_THRESHOLD() get_threshold;

    action flag1(){
        ig_md.flag = 1;
    }
    action flag0(){
        ig_md.flag = 0;
    }
    table stflag{
        key = {
            ig_md.flag : exact;
        }
        actions = {
            flag1;
            flag0;
        }
        size = 2;
        default_action = flag0();
    }
 
    CM_UPDATE_KEY(32w0x30243f0b) update_1;
    CM_UPDATE_KEY(32w0x0f79f523) update_2;
    CM_UPDATE_KEY(32w0x6b8cb0c5) update_3;

    action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.kvs.val_word.val_word_1.data = ig_md.est_3;
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
    action a2(){
        ig_md.est_2 = ig_md.est_1;
    }
    action a3(){
        ig_md.est_3 = ig_md.est_2;
    }
    
    
    table t2{
        key = {
            ig_md.c_2 : exact;
        }
        actions = {
            a2;
            NoAction;
        }
        size = 2;
        default_action = NoAction();
    }
    
    table t3{
        key = {
            ig_md.c_3 : exact;
        }
        actions = {
            a3;
            NoAction;
        }
        size = 2;
        default_action = NoAction();
    }
   

    apply {
        stflag.apply();
        get_threshold.apply(hdr, ig_md);
        update_1.apply(hdr, ig_md.flag, ig_md.est_1);
        update_2.apply(hdr, ig_md.flag, ig_md.est_2);
        update_3.apply(hdr, ig_md.flag, ig_md.est_3);   
        
        //hit_key.apply(hdr, ig_md, ig_tm_md);
        ig_md.est_12 = ig_md.est_2 - ig_md.est_1;
        ig_md.c_2 = (bit<1>) (ig_md.est_12 >> 31);
        t2.apply();
        ig_md.est_13 = ig_md.est_3 - ig_md.est_2;
        ig_md.c_3 = (bit<1>) (ig_md.est_13 >> 31);
        t3.apply();

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

