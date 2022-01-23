control reduce_origin_sum_3_4096_1(
        inout header_t hdr,
        inout metadata_t ig_md) {

    CSum_UPDATE_KEY(32w0x30243f0b) update_1_0;
    CSum_UPDATE_KEY(32w0x0f79f523) update_1_1;
    CSum_UPDATE_KEY(32w0x6b8cb0c5) update_1_2;

    action a2() {
        ig_md.est_2 = ig_md.est_1;
    }
    action a3() {
        ig_md.est_3 = ig_md.est_2;
    }

    table t2 {
        key = {
            ig_md.c_2 : exact;
        }
        actions = {
            a2;
            NoAction;
        }
        default_action = NoAction();
    }
    table t3 {
        key = {
            ig_md.c_3 : exact;
        }
        actions = {
            a3;
            NoAction;
        }
        default_action = NoAction();
    }

    apply {
        hdr.kvs.val_word.val_word_1.data = hdr.kvs.val_word.val_word_1.data;
        update_1_0.apply(hdr, ig_md.flag, ig_md.est_1);
        update_1_1.apply(hdr, ig_md.flag, ig_md.est_2);
        update_1_2.apply(hdr, ig_md.flag, ig_md.est_3);
        ig_md.est_12 = ig_md.est_2 - ig_md.est_1;
        ig_md.c_2 = (bit<1>) (ig_md.est_12 >> 31);
        t2.apply();
        ig_md.est_13 = ig_md.est_3 - ig_md.est_2;
        ig_md.c_3 = (bit<1>) (ig_md.est_13 >> 31);
        t3.apply();
    }
}


control filter_origin_32w3_ge_2(
        inout header_t hdr,
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    apply {
        if(hdr.kvs.val_word.val_word_1.data < 32w3)
            drop();
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

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

	action flag1() {
		ig_md.flag = 1;
	}
	action flag0() {
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

	action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
		ig_tm_md.ucast_egress_port = port;
		hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
		hdr.ethernet.dst_addr = dst_addr;
		hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
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

	reduce_origin_sum_3_4096_1()  func_0;
	filter_origin_32w3_ge_2()  func_1;

	apply {
		stflag.apply();

		func_0.apply(hdr, ig_md);
		func_1.apply(hdr, ig_md, ig_dprsr_md);

		ipv4_lpm.apply();
	}
}
