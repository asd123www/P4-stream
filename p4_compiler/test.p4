control map_origin_identity_32w0_add_1(
        inout header_t hdr,
        inout metadata_t ig_md) {

    apply {
        ig_md.value1 = 32w0 + hdr.kvs.val_word.val_word_1.data;
    }
}


control filter_identity_32w0_ge_2(
        inout header_t hdr,
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    apply {
        if(ig_md.value1 < 32w0)
            drop();
    }
}


control map_identity_add3_32w3_add_3(
        inout header_t hdr,
        inout metadata_t ig_md) {

    apply {
        ig_md.value2 = 32w3 + ig_md.value1;
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

	map_origin_identity_32w0_add_1()  func_0;
	filter_identity_32w0_ge_2()  func_1;
	map_identity_add3_32w3_add_3()  func_2;

	apply {
		stflag.apply();

		func_0.apply(hdr, ig_md);
		func_1.apply(hdr, ig_md, ig_dprsr_md);
		func_2.apply(hdr, ig_md);

		hdr.kvs.val_word.val_word_1.data = ig_md.value2;
		ipv4_lpm.apply();
	}
}
