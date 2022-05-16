from inspect import trace
import sys,os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re
from getopt import getopt
import traceback

from src.utils import *
from src.p4_driver import P4Driver

class P4Server(object):
	def __init__(self, conf, p4_code, sh_code):
		self.conf = conf
		self.conf["app"] = self.conf["tmp_name"]
		self.path = os.path.join(self.conf["p4_path"],self.conf["tmp_name"])
		if not os.path.exists(self.path):
			os.mkdir(self.path)
		self.p4_file = os.path.join(self.path, self.conf["tmp_name"] + ".p4")

		with open(self.p4_file, "w") as f:
			f.write(p4_code)
		
		self.sh_file = os.path.join(self.path, "command_hw.py")
		
		with open(self.sh_file, "w") as f:
			f.write(sh_code)
		
		# 配置好的端口文件, 直接读之前的即可.
		with open(os.path.join(self.conf["p4_path"], "simple_l3_zcq", "shell_hw.txt"), "r") as f:
			sh_hw = f.read()
		
		with open(os.path.join(self.path, "shell_hw.txt"), "w") as f:
			f.write(sh_hw)
		
		time.sleep(2)
		self.p4_driver = P4Driver(p4_conf=self.conf)

	def start(self):
		self.p4_driver.start()
		
	def exit(self):
		self.p4_driver.exit()


if __name__ == "__main__":
	
	from config.config_hw import p4_conf

	try:
		opts, args = getopt(sys.argv[1:], '-s:-d', ['suffix', 'debug'])
	except:
		print("getopt error")
	
	debug = False

	for opt, arg in opts:
		if opt in ('-s', '--suffix'):
			print(opt, arg)
			p4_conf.update({
				"tmp_name": p4_conf["tmp_name"] + "_" + arg
			})

		if opt in ('-d', '--debug'):
			debug = True

	listener = Listener((p4_conf["server_addr"], p4_conf["server_port"]))
	print("listening, waiting for monitor")
	conn = listener.accept()
	try:
		p4_code, sh_code = conn.recv()  # receive the code from monitor.
		if debug:
			with open(os.path.join(p4_conf["p4_path"], "simple_l3_zcq","simple_l3_zcq.p4")) as f:
				p4_code = f.read()

			with open(os.path.join(p4_conf["p4_path"], "simple_l3_zcq","command_hw.py")) as f:
				sh_code = f.read()
				sh_code = re.sub("simple_l3_zcq", p4_conf["tmp_name"], sh_code)
		else:
			sh_code = re.sub("simple_l3", p4_conf["tmp_name"], sh_code)

		p4_server = P4Server(p4_conf, p4_code, sh_code)
		p4_server.start()
		conn.send("ready")

		while True:
			msg = conn.recv()
			if msg == "stop":
				print("receive stop event")
				break

	except:
		traceback.print_exc()
	
	finally:
		print("=== exit ===")
		p4_server.exit()
		exit(0)
