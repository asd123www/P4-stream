bfrt.word_count_sketch.pipe.SwitchIngress.ipv4_lpm.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.ipv4_lpm.add_with_ipv4_forward(hdr_ipv4_dst_addr=ip("10.1.100.2"), hdr_ipv4_dst_addr_p_length=32, dst_addr=mac("8e:cd:61:c6:12:5c"), port=1)
bfrt.word_count_sketch.pipe.SwitchIngress.ipv4_lpm.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.get_threshold.tbl_get_threshold.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.get_threshold.tbl_get_threshold.add_with_tbl_get_threshold_act(qid=1, threshold=10)
bfrt.word_count_sketch.pipe.SwitchIngress.get_threshold.tbl_get_threshold.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t2.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.t2.add_with_a2(c_2 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t2.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t3.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.t3.add_with_a3(c_3 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t3.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t4.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.t4.add_with_a4(c_4 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t4.dump()

bfrt.word_count_sketch.pipe.SwitchIngress.t5.clear()
bfrt.word_count_sketch.pipe.SwitchIngress.t5.add_with_a5(c_5 = 0)
bfrt.word_count_sketch.pipe.SwitchIngress.t5.dump()
