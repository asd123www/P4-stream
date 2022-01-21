from scapy.all import *
from multiprocessing.connection import Listener
import time
import logging
from scapy.config import conf
from threading import Thread
from struct import unpack
import pickle
import re
from src.emitter import Emitter
from src.utils import *

class Emitter_Server(object):

	class Query:
		pass

	def __init__(self, conf, formats):
		self.conf = conf
		self.formats = formats
		# use formats to generate queries
		self.queries = []
		self.em_cnt = 0

		for format in formats:
			query = Emitter_Server.Query()
			query.qid = format.qid
			query.qname = format.qname
			query.spark_build = self.spark_build(format.spark_code)
			query.emitter = self.emitter_func(format.em_format)
			self.queries.append(query)
		
		self.emitter = Emitter(self.conf, self.queries)

	def spark_build(self, spark_code):
		def func(kvs):
			return eval(spark_code)

		return func

	def emitter_func(self, format):
		def func(data):
			self.em_cnt += 1
			return data

		return func

	def start(self):
		self.emitter.start()
	
	def stop(self):
		if self.emitter != None:
			self.emitter.stop()

	def clear(self):
		self.em_cnt = 0

	def get_result(self):
		
		return "Emitter : totally recv messages: %d" % self.em_cnt
	

if __name__ == "__main__":
	from config.config_hw import em_conf

	listener = Listener((em_conf["server_addr"], em_conf["server_port"]))
	print("listening, waiting for monitor")
	conn = listener.accept()
	try:
		# currently do not receive conf from monitor
		# use em_conf directly
		conf, formats = em_conf, conn.recv()
		
		if conf["server_addr"] != em_conf["server_addr"]:
			print("invalid conf")
			exit(1)

		em_server = Emitter_Server(conf, formats)
		em_server_thread = Thread(name="em_server", target=em_server.start)
		em_server_thread.start()
		conn.send("ready")
		print("=== ready ===")

		while True:
			msg = conn.recv()
			if msg == "stop":
				em_server.stop()
				conn.send(em_server.get_result())
				break
				
			if msg == "clear":
				em_server.clear()
				conn.send("clear ack")
				break

	except:
		print("invalid conf")
		if em_server != None:
			em_server.stop()
		exit(1)
