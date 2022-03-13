	action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
		ig_tm_md.ucast_egress_port = port;
		hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
		hdr.ethernet.dst_addr = dst_addr;
		hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
	}
