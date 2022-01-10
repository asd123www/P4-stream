parser SwitchIngressParser(
        packet_in pkt,
        out header_t hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
        // transition parse_ipv4;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN : parse_vlan;
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_vlan {
        pkt.extract(hdr.vlan_tag);
        transition select(hdr.vlan_tag.ether_type) {
            ETHERTYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IP_PROTOCOLS_UDP : parse_udp;
        //    IP_PROTOCOLS_TCP : parse_tcp;
            default : reject;
        }
    }

    state parse_tcp {
        pkt.extract(hdr.tcp);
        transition accept;
    }

    state parse_udp {
        pkt.extract(hdr.udp);
        transition accept;
    }
    
    state parse_my_header {
        pkt.extract(hdr.my_header);
        transition select(hdr.my_header.qid) {
            QID_WORD_COUNT  : parse_kvs_head;
            default : reject;
        }
    }

    state parse_kvs_head {
        pkt.extract(hdr.kvs.kvs_header);
        transition select(hdr.kvs.kvs_header.key_len) {
            16w0x0004  : parse_key_word_1;
            16w0x0008  : parse_key_word_2;
            16w0x000c  : parse_key_word_3;
            16w0x0010  : parse_key_word_4;
            16w0x0014  : parse_key_word_5;
            16w0x0018  : parse_key_word_6;
            16w0x001c  : parse_key_word_7;
            16w0x0020  : parse_key_word_8;
            default : reject;
        }
    }
    state parse_key_word_8 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        pkt.extract(hdr.kvs.key_word.key_word_4);
        pkt.extract(hdr.kvs.key_word.key_word_5);
        pkt.extract(hdr.kvs.key_word.key_word_6);
        pkt.extract(hdr.kvs.key_word.key_word_7);
        pkt.extract(hdr.kvs.key_word.key_word_8);
        transition parse_key_word_0;
    }
    state parse_key_word_7 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        pkt.extract(hdr.kvs.key_word.key_word_4);
        pkt.extract(hdr.kvs.key_word.key_word_5);
        pkt.extract(hdr.kvs.key_word.key_word_6);
        pkt.extract(hdr.kvs.key_word.key_word_7);
        transition parse_key_word_0;
    }
    state parse_key_word_6 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        pkt.extract(hdr.kvs.key_word.key_word_4);
        pkt.extract(hdr.kvs.key_word.key_word_5);
        pkt.extract(hdr.kvs.key_word.key_word_6);
        transition parse_key_word_0;
    }
    state parse_key_word_5 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        pkt.extract(hdr.kvs.key_word.key_word_4);
        pkt.extract(hdr.kvs.key_word.key_word_5);
        transition parse_key_word_0;
    }
    state parse_key_word_4 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        pkt.extract(hdr.kvs.key_word.key_word_4);
        transition parse_key_word_0;
    }
    state parse_key_word_3 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        pkt.extract(hdr.kvs.key_word.key_word_3);
        transition parse_key_word_0;
    }
    state parse_key_word_2 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        pkt.extract(hdr.kvs.key_word.key_word_2);
        transition parse_key_word_0;
    }
    state parse_key_word_1 {
        pkt.extract(hdr.kvs.key_word.key_word_1);
        transition parse_key_word_0;
    }
    state parse_key_word_0 {
        transition select(hdr.kvs.kvs_header.val_len) {
            16w0x0004  : parse_val_word_1;
        //    16w0x0008  : parse_val_word_2;
        //    16w0x000c  : parse_val_word_3;
        //    16w0x0010  : parse_val_word_4;
        //    16w0x0014  : parse_val_word_5;
        //    16w0x0018  : parse_val_word_6;
        //    16w0x001c  : parse_val_word_7;
        //    16w0x0020  : parse_val_word_8;
            default : reject;
        }
    }

    state parse_val_word_8 {
        pkt.extract(hdr.kvs.val_word.val_word_8);
        transition parse_val_word_7;
    }
    state parse_val_word_7 {
        pkt.extract(hdr.kvs.val_word.val_word_7);
        transition parse_val_word_6;
    }
    state parse_val_word_6 {
        pkt.extract(hdr.kvs.val_word.val_word_6);
        transition parse_val_word_5;
    }
    state parse_val_word_5 {
        pkt.extract(hdr.kvs.val_word.val_word_5);
        transition parse_val_word_4;
    }
    state parse_val_word_4 {
        pkt.extract(hdr.kvs.val_word.val_word_4);
        transition parse_val_word_3;
    }
    state parse_val_word_3 {
        pkt.extract(hdr.kvs.val_word.val_word_3);
        transition parse_val_word_2;
    }
    state parse_val_word_2 {
        pkt.extract(hdr.kvs.val_word.val_word_2);
        transition parse_val_word_1;
    }
    state parse_val_word_1 {
        pkt.extract(hdr.kvs.val_word.val_word_1);
        transition accept;
    }
}

control SwitchIngressDeparser(packet_out pkt,
                              inout header_t hdr,
                              in metadata_t ig_md,
                              in ingress_intrinsic_metadata_for_deparser_t 
                                ig_intr_dprsr_md
                              ) {

    apply {
        pkt.emit(hdr);
    }
}