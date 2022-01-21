import sys,os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re

from src.utils import *
from src.p4_driver import P4Driver
# from src.p4_generator import P4Generator


class Monitor(object):
	def __init__(self, conf, queries):
		self.conf = conf
		self.queries = queries

		# split task

		# Generate spark file
		self.spark_code = ""

		# Generate .p4 file, format, command.py
		self.p4_code, self.em_format, self.sh_code = "", {}, ""

		# connect to switch
		"""
		print("=== connecting to switch ===")
		self.p4_conn = Client((self.conf["p4_conf"]["server_addr"], self.conf["p4_conf"]["server_port"]))
		self.p4_conn.send((self.p4_code, self.sh_code))
		assert (self.p4_conn.recv() == "ready")
		print("=== connected to switch ===")
		"""

		# connect to emitter
		print("=== connecting to emitter ===")
		self.em_conn = Client((self.conf["em_conf"]["server_addr"], self.conf["em_conf"]["server_port"]))
		self.em_conn.send(self.em_format)
		assert (self.em_conn.recv() == "ready")
		print("=== connected to emitter ===")

		# waiting for sender
		print("=== waiting for sender")
		sd_listener = Listener((self.conf["sd_conf"]["server_addr"], self.conf["sd_conf"]["server_port"]))
		self.sd_conn = sd_listener.accept()
		
		while True:
			if self.poll():
				break

	def poll(self):
		if self.sd_conn.poll(1):
			opt, arg = self.sd_conn.recv()
			if opt == "start":
				self.em_conn.send("clear")
				assert (self.em_conn.recv() == "clear ack")
				print("=== start ===")
				self.sd_conn.send("start ack")
			
			if opt == "finish":
				t, cnt = arg
				print("=== finish ===")
				print("total msg : %d, time : %f" % (cnt, t))
				print("throughput %f msg/s" % cnt/t)
				self.em_conn.send("stop")
				em_result = self.em_conn.recv()
				print(em_result)
				self.sd_conn.send("stop")
				
				return True
		
		return False

if __name__ == "__main__":
	from config.config_hw import conf

	monitor = Monitor(conf, [])

