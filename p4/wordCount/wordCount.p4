/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif


#include "egress.p4"
#include "commonHeaders.p4"

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/
typedef bit<256> word_t;

typedef bit<32> value_t;
typedef bit<16> queryId_t;
typedef bit<16> length_t;

header word_h { // the wordCount only have one kv, so ... 
    queryId_t qid;
    length_t length;

    length_t key_len;
    length_t val_len;

    word_t word;
    value_t value;
}

struct metadata_t {
    /* empty */
}

struct header_t {
    ethernet_h ethernet;
    ipv4_h ipv4;
    udp_h udp;
    word_h kv;
}


// what's the intrinsic metadata......
parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition reject;
    }

    state parse_port_metadata {
        pkt.advance(PORT_METADATA_SIZE);
        transition accept;
    }
}

parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    // TofinoIngressParser() tofino_parser;

    state start {
        /* TNA-specific Code for simple cases */
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE); 
        // transition parse_ethernet;
        // tofino_parser.apply(packet, ig_intr_md);
        transition parse_ethernet;
    }
    
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_IPV4: parse_ipv4;
            default: reject; // 这里reject的效果是?
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP: parse_udp;
            default: accept;
        }
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        pkt.extract(hdr.kv);
        transition accept;
    }
}


control hashIDArray(in word_t key,
                    in hash32_t hashID,
                    out hash32_t est) {

    Hash<hash16_t>(HashAlgorithm_t.CRC16) crc16; // the hash table, (,) is the definition of function.

    Register<hash32_t, hash16_t>(32w65536, 0) cs_table; // initial value is 0.

    // in register action you can't do complex operation such as crc32.get().
    RegisterAction<hash32_t, hash16_t, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            if (register_data == 32w0) register_data = hashID;
            result = register_data;
        }
    };

    apply {
        est = cs_action.execute(crc16.get({key}));
    }
}

control valueUpdate(in word_t key,
                    in value_t val,
                    inout value_t est) {
    Hash<hash16_t>(HashAlgorithm_t.CRC16) crc16; // the hash table, (,) is the definition of function.

    Register<value_t, hash16_t>(32w65536, 0) cs_table;

    RegisterAction<value_t, hash16_t, value_t>(cs_table) cs_action = {
        void apply(inout value_t register_data, out value_t result) {
            result = register_data + val;
            if (result > 32w10) {
                register_data = 32w0;
            }
            else {
                register_data = result;
                result = 32w0;
            }
        }
    };

    apply {
        est = cs_action.execute(crc16.get({key}));
    }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
************************************************************·*************/

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
        default_action = NoAction();
    }

    hashIDArray() idAccess;
    valueUpdate() valAccess;

    Hash<hash32_t>(HashAlgorithm_t.CRC32) crc32;
// 判断包的数量 / timestamp 满足一个条件就发包... 
    apply {
        if (hdr.ipv4.isValid()) {
            ipv4_lpm.apply();
            if (hdr.udp.isValid()) { // we need word count.
                // 手动顺序查找.
                // bit<16> idx = crc16.get({hdr.kv.word});
                // bit<32> hashID = crc32.get({hdr.kv.word});
                value_t val = 32w0;
                hash32_t hashID;
                hash32_t retHashID;

                hashID = crc32.get({hdr.kv.word});
                idAccess.apply(hdr.kv.word, hashID, retHashID);

                if (hashID == retHashID) { // hit.
                    valAccess.apply(hdr.kv.word, hdr.kv.value, val);
                    if (val == 32w0) { // drop the packet. We stored the info.
                        drop();
                    }
                    else {
                        hdr.kv.value = val;
                    }
                }
                else {
                    drop();
                }
            }
        }
    }
}
// 动态对象

control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t  ig_intr_dprsr_md
                              ) {
    apply {
        pkt.emit(hdr);
    }
}

// we need to use tofino architecture.
Pipeline(
    SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    EgressParser(),
    EmptyEgress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;