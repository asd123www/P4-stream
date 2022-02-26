bfrt.word_count_sketch.pipe.SwitchIngress.ipv4_lpm.add_with_ipv4_forward(dst_addr=ip("10.1.100.2"), dst_addr_p_length=32, new_dst_addr=mac("ff:ff:ff:ff:ff:ff"), port=60)
bfrt.word_count_sketch.pipe.SwitchIngress.ipv4_lpm.dump()


bfrt.word_count_sketch.pipe.SwitchIngress.get_threshold.tbl_get_threshold.add_with_tbl_get_threshold_act(qid=1, threshold=10)
bfrt.word_count_sketch.pipe.SwitchIngress.get_threshold.tbl_get_threshold.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t2.add_with_a2(c_2 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t2.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t3.add_with_a3(c_3 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t3.dump()
