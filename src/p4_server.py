import sys,os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re
from getopt import getopt

from src.utils import *
from src.p4_driver import P4Driver

class P4Server(object):
	def __init__(self, conf, p4_code, sh_code):
		self.conf = conf
		if not os.path.exists(self.conf["tmp_name"]):
			os.mkdir(self.conf["tmp_name"])
		self.p4_file = os.path.join(self.conf["p4_path"], self.conf["tmp_name"], self.conf["tmp_name"] + ".p4")

		with open(self.p4_file, "w") as f:
			f.write(p4_code)
		
		self.sh_file = os.path.join(self.conf["p4_path"], self.conf["tmp_name"], "command.py")
		
		with open(self.sh_file, "w") as f:
			f.write(sh_code)
		
		with open(os.path.join(self.conf["p4_path"], "simple_l3", "shell_hw.txt")) as f:
			sh_hw = f.read()
		
		with open(os.path.join(self.conf["p4_path"], self.conf["tmp_name"], "shell_hw.txt")) as f:
			f.write(sh_hw)
		
		self.p4_driver = P4Driver(p4_conf=self.conf)

	def start(self):
		self.p4_driver.start()
		
	def exit(self):
		self.p4_driver.exit()


if __name__ == "__main__":
	
	from config.config_hw import p4_conf

	try:
		opts, args = getopt(sys.argv[1:], '-s-d', ['suffix', 'debug'])
	except:
		print("getopt error")
	
	debug = False

	for opt, arg in opts:
		if opt in ('-s', '--suffix'):
			p4_conf.update({
				"tmp_name": p4_conf["tmp_name"] + "_" + "arg"
			})

		if opt in ('-d', '--debug'):
			debug = True

	listener = Listener((p4_conf["server_addr"], p4_conf["server_port"]))
	print("listening, waiting for monitor")
	conn = listener.accept()
	try:
		# currently do not receive conf from monitor
		# use p4_conf directly
		conf, p4_code, sh_code = conn.recv()
		if debug:
			conf = p4_conf
			with open(os.path.join(conf["p4_path"], "simple_l3_zcq","simple_l3_zcq.p4")) as f:
				p4_code = f.read()
			with open(os.path.join(conf["p4_path"], "simple_l3_zcq","command_hw.py")) as f:
				sh_code = f.read()
		
		if conf["server_addr"] != p4_conf["server_addr"]:
			print("invalid conf")
			exit(1)

		p4_server = P4Server(conf, p4_code, sh_code)
		p4_server.start()
		conn.send("ready")

		while True:
			msg = conn.recv()
			if msg == "stop":
				break

	except:
		print("invalid conf")
	
	finally:
		p4_server.exit()
		exit(0)
