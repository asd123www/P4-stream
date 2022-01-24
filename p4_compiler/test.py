bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.clear()
bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.add_with_tbl_get_threshold_act(qid=0, threshold=10)
bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.dump()


bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.clear()
bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.add_with_ipv4_forward(hdr_ipv4_dst_addr=ip("10.1.100.2"), hdr_ipv4_dst_addr_p_length=32, dst_addr=mac("8e:cd:61:c6:12:5c"), port=60)
bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.dump()


