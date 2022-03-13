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
    