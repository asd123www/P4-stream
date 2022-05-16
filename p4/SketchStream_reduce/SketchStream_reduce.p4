#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"


#define HASH_WIDTH 12
const int FlowAID = 16w1;
const int FlowBID = 16w2;

struct metadata_t {
    bit<32> hash_idx1; // index hash.
    bit<32> hash_idx2; // index hash.
    bit<32> hash_idx3; // index hash.
    bit<32> hash_idx4; // index hash.
    bit<32> hash_32;// JOIN: Finger-Print hash.

    bit<32> tmp0;
    bit<32> tmp1;
    bit<32> tmp2;
    bit<32> tmp3;
    bit<32> tmp4;
    bit<32> tmp5;
    bit<32> tmp6; // JOIN: compare if-in hash.
    bit<32> tmp7;
    bit<8> num; // JOIN: if-in: stage number.

    bit sgn1;
    bit sgn2;
    bit sgn3;
    bit sgn4;
}

#include "parser.p4"
#include "SketchStream.p4"


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
    
    
    // #define ARRAY_LENGTH 32w4096
    SketchStream_reduce(8w4, 32w4096, 32w4095) func_1;

    apply {
        // there is some disturbing pkts!!!
        if (hdr.udp.isValid()) func_1.apply(hdr, ig_md, hdr.kvs.val_word.val_word_1.data);

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