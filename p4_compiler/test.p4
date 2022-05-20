import time

flag = 0
while True:
	curtime = int(time.time())
	if flag:
		bfrt.simple_l3.pipe.SwitchIngress.stflag.clear()
		flag = 0
	else:
		bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 0)
		bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 1)
		flag = 1
	while True:
		if curtime != int(time.time()):
			break
