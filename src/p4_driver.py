import os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re

from src.utils import *
from psutil import net_if_addrs

class P4Driver(object):
	def __init__(self, p4_conf):
		self.conf = p4_conf
		self.interfaces = net_if_addrs()

		# create a logger for the object
		self.logger = get_logger(__name__, logging.INFO)
	
	def compile(self):
		print("=============================================")
		print("             start compiling")
		print("=============================================")
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
		