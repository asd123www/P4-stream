import sys,os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re

from src.utils import *
# from psutil import net_if_addrs


# compile the P4 code ...
class P4Driver(object):
	def __init__(self, p4_conf):
		self.conf = p4_conf
		# self.interfaces = net_if_addrs()

		# create a logger for the object
		self.logger = get_logger(__name__, logging.INFO)
	
	def compile(self):
		print("=============================================")
		print("             start compiling")
		print("=============================================")
		if self.conf["hw"] == True:
			cmd = ' '.join(['bash', 
				os.path.join(self.conf["p4_path"], 'compile_hw.sh'),
				self.conf["app"]
			])
		else:
			cmd = ' '.join(['bash', 
				os.path.join(self.conf["p4_path"], 'compile.sh'),
				self.conf["app"]
			])
		print("cmd:", cmd)
		success, out = get_out(cmd)
		self.logger.info(out)
		assert(success)
		print("=============================================")
		print("             finish compiling")
		print("=============================================")
	
	def start_model(self):
		
		print("=============================================")
		print("              starting model")
		print("=============================================")
		
		cmd = ' '.join(['sudo',
				'bash', 
				os.path.join(self.conf["p4_path"], 'model.sh'),
				self.conf["app"]
		])
		print("cmd:", cmd)
		success, out = get_out(cmd)
		self.logger.info(out)
		assert(success)
		print("=============================================")
		print("               model started")
		print("=============================================")
		
	def start_driver(self):
		
		print("=============================================")
		print("             starting driver")
		print("=============================================")
		if self.conf["hw"] == True:
			cmd = ' '.join([
				'bash', 
				os.path.join(self.conf["p4_path"], 'driver_hw.sh'),
				self.conf["app"]
			])
		else:
			cmd = ' '.join(['sudo',
				'bash', 
				os.path.join(self.conf["p4_path"], 'driver.sh'),
				self.conf["app"]
			])
		print("cmd:", cmd)
		success, out = get_out(cmd)
		self.logger.info(out)
		assert(success)
		print("=============================================")
		print("             driver started")
		print("=============================================")

	def send_command(self):
		print("=============================================")
		print("             sending command")
		print("=============================================")
		if self.conf["hw"] == True:
			cmd = ' '.join([
				'bash', 
				os.path.join(self.conf["p4_path"], 'shell_hw.sh'),
				self.conf["app"]
			])
		else:
			cmd = ' '.join(['sudo',
				'bash', 
				os.path.join(self.conf["p4_path"], 'shell.sh'),
				self.conf["app"]
			])
		print("cmd:", cmd)
		success, out = get_out(cmd)
		self.logger.info(out)
		assert(success)
		print("=============================================")
		print("              command sent")
		print("=============================================")
		
	def start(self):
		# start everything
		self.compile()
		if self.conf["hw"] != True:
			self.p4_model_thread = Thread(name="p4_model", target=self.start_model)
			self.p4_model_thread.start()
		self.p4_driver_thread = Thread(name="p4_driver", target=self.start_driver)
		self.p4_driver_thread.start()
		time.sleep(3)
		self.p4_driver_command_thread = Thread(name="p4_command", target=self.send_command)
		self.p4_driver_command_thread.start()

		if self.conf["hw"] != True: self.p4_model_thread.join()
		self.p4_driver_command_thread.join()
		self.p4_driver_thread.join(10)

	def exit(self):
		async_raise(self.p4_driver_thread.ident, SystemExit)


if __name__ == "__main__":
	if len(sys.argv) < 2:
		print("require at least 1 arg")
		exit(1)
	
	from config.config_hw import p4_conf
	p4_conf.update({
		"app":sys.argv[1]
	})
	p4driver = P4Driver(p4_conf=p4_conf)
	p4driver.start()
	
	try:
		while True:
			a = input()
			if a == "exit":
				break
	finally:
		p4driver.exit()
