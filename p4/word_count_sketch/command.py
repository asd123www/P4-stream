bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.clear()
bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.add_with_ipv4_forward(hdr_ipv4_dst_addr=ip("10.1.100.2"), hdr_ipv4_dst_addr_p_length=32, dst_addr=mac("8e:cd:61:c6:12:5c"), port=1)
bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm.dump()

bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.clear()
bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.add_with_tbl_get_threshold_act(qid=1, threshold=10)
bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold.dump()

bfrt.simple_l3.pipe.SwitchIngress.t2.clear()
bfrt.simple_l3.pipe.SwitchIngress.t2.add_with_a2(c_2 = 0)
bfrt.simple_l3.pipe.SwitchIngress.t2.dump()

bfrt.simple_l3.pipe.SwitchIngress.t3.clear()
bfrt.simple_l3.pipe.SwitchIngress.t3.add_with_a3(c_3 = 0)
bfrt.simple_l3.pipe.SwitchIngress.t3.dump()


import time

flag = 0
while True:
    curtime = int(time.time())
    if flag:
        bfrt.simple_l3.pipe.SwitchIngress.update_1.cs_table2.clear()
        bfrt.simple_l3.pipe.SwitchIngress.update_2.cs_table2.clear()
        bfrt.simple_l3.pipe.SwitchIngress.update_3.cs_table2.clear()
        bfrt.simple_l3.pipe.SwitchIngress.stflag.clear()
        flag = 0
    else:
        bfrt.simple_l3.pipe.SwitchIngress.update_1.cs_table1.clear()
        bfrt.simple_l3.pipe.SwitchIngress.update_2.cs_table1.clear()
        bfrt.simple_l3.pipe.SwitchIngress.update_3.cs_table1.clear()
        bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 0)
        bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 1)
        flag = 1
    while True:
        if curtime != int(time.time()):
            break