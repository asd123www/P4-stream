#py部分和CM基本一样
bfrt.test_bloom_filter.pipe.SwitchIngress.ipv4_lpm.clear()
bfrt.test_bloom_filter.pipe.SwitchIngress.ipv4_lpm.add_with_ipv4_forward(hdr_ipv4_dst_addr=ip("10.1.100.2"), hdr_ipv4_dst_addr_p_length=32, dst_addr=mac("ff:ff:ff:ff:ff:ff"), port=60)
bfrt.test_bloom_filter.pipe.SwitchIngress.ipv4_lpm.dump()

bfrt.test_bloom_filter.pipe.SwitchIngress.get_threshold.tbl_get_threshold.clear()
bfrt.test_bloom_filter.pipe.SwitchIngress.get_threshold.tbl_get_threshold.add_with_tbl_get_threshold_act(qid=1, threshold=10)
bfrt.test_bloom_filter.pipe.SwitchIngress.get_threshold.tbl_get_threshold.dump()

bfrt.test_bloom_filter.pipe.SwitchIngress.t2.clear()
bfrt.test_bloom_filter.pipe.SwitchIngress.t2.add_with_a2(c_2 = 1)
bfrt.test_bloom_filter.pipe.SwitchIngress.t2.dump()

bfrt.test_bloom_filter.pipe.SwitchIngress.t3.clear()
bfrt.test_bloom_filter.pipe.SwitchIngress.t3.add_with_a3(c_3 = 1)
bfrt.test_bloom_filter.pipe.SwitchIngress.t3.dump()


import time

flag = 0
while True:
    curtime = int(time.time())
    if flag:
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table2.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table2.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table2.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.stflag.clear()
        flag = 0
    else:
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table1.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table1.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.update.bf_table1.clear()
        bfrt.test_bloom_filter.pipe.SwitchIngress.stflag.add_with_flag1(flag = 0)
        bfrt.test_bloom_filter.pipe.SwitchIngress.stflag.add_with_flag1(flag = 1)
        flag = 1
    while True:
        if curtime != int(time.time()):
            break