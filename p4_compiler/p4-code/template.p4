#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"
#include "commonEgress.p4"

const int FlowAID = 16w1;
const int FlowBID = 16w2;
struct metadata_t {
    bit<32> hash_idx1; // index hash.
    bit<32> hash_idx2; // index hash.
    bit<32> hash_idx3; // index hash.
    bit<32> hash_idx4; // index hash.
    bit<32> hash_32; // JOIN: Finger-Print hash.

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



<replace_with_multi_application_definition>


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
    
<replace_with_multi_application_declaration>

    apply {
        // there is some disturbing pkts!!!
        if (hdr.udp.isValid()) {
<replace_with_multi_application_call>
        }

        ipv4_lpm.apply();
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