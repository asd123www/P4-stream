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
from p4_compiler.P4Generator import P4Generator
from src.spark_generator import SparkGenerator


class Monitor(object):
	def __init__(self, conf, queries):
		self.conf = conf
		self.queries = queries

		# split task
		p4_queries = []
		spark_queries = []
		for query in queries:
			p4_query, spark_query, success = query.split()
			assert(success)
			p4_queries.append(p4_query)
			spark_queries.append(spark_query)

		# Generate .p4 file, format, command.py
		# p4_code, sh_code, em_formats = "", "", [{"qid":0, "qname":"test", "em_format":"origin"}]
		p4_code, sh_code, em_formats = P4Generator(p4_queries).solve()

		# Generate spark file
		# em_formats = []
		em_formats = SparkGenerator(em_formats, spark_queries).solve()
		# print(em_formats)
		# exit(0)

		# connect to switch
		print("=== connecting to switch ===")
		self.p4_conn = Client((self.conf["p4_conf"]["server_addr"], self.conf["p4_conf"]["server_port"]))
		self.p4_conn.send((p4_code, sh_code))
		assert (self.p4_conn.recv() == "ready")
		print("=== connected to switch ===")

		# we should prepare the receiver first!
		# connect to emitter
		print("=== connecting to emitter ===")
		self.em_conn = Client((self.conf["em_conf"]["server_addr"], self.conf["em_conf"]["server_port"]))
		self.em_conn.send(em_formats)
		assert (self.em_conn.recv() == "ready")

		# waiting for sender
		print("=== connecting to sender ===")
		self.sd_client = Client((self.conf["sd_conf"]["server_addr"], self.conf["sd_conf"]["server_port"]))
		self.sd_client.send(queries)
		assert (self.sd_client.recv() == "ready")

		print("=== connected to emitter and sender ===")

		
		while True:
			if self.poll():
				# finished
				break

	def poll(self):
		# 轮询sender返回的信息, 如果任务结束则结束.
		if self.sd_client.poll(1):
			opt, arg = self.sd_client.recv()
			if opt == "start":
				self.em_conn.send("clear")
				assert (self.em_conn.recv() == "clear ack")
				print("=== start ===")
				self.sd_client.send("start ack")
			
			if opt == "finish":
				t, cnt, bcnt = arg
				print("=== finish ===")
				print("total msg : %d, bytes: %d, time : %f" % (cnt, bcnt, t))
				print("throughput %f msg/s" % (cnt/t))
				print("sender throughput %f bytes/s" % (bcnt/t))
				self.em_conn.send("stop")
				em_cnt = self.em_conn.recv()
				print(em_cnt)
				print("emitter received msg: %d" % em_cnt)
				print("emitter throughput %f msg/s" % (em_cnt/t))
				print("emitter msg / sender msg = %f" % (em_cnt / cnt))
				self.sd_client.send("stop")
				self.p4_conn.send("stop")
				
				return True
		
		return False

if __name__ == "__main__":
	from config.config_hw import conf

	monitor = Monitor(conf, [])