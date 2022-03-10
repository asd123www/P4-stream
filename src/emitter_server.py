from scapy.all import *
from multiprocessing.connection import Listener
import time
import logging
from scapy.config import conf
from threading import Thread
from struct import unpack
import pickle
import re
import traceback
from src.emitter import Emitter
from src.utils import *

# emitter端调用, 处理switch发出的包格式, 转为Spark格式后发给Spark做处理.

class Emitter_Server(object):

	class Query:
		pass

	def __init__(self, conf, formats):
		self.conf = conf
		self.formats = formats
		# use formats to generate queries
		self.queries = []
		self.em_cnt = 0

		'''
		应该之后还得加上query的信息.
		因为我们需要Stream processing端自动生成的代码.
		但是还是先写完框架在说.

		2022.3.10: 我们的架构退化成了host端手动的代码, 等融合AF_stream的时候在自动生成.
		for format in formats:
			query = Emitter_Server.Query()
			query.qid = format["qid"]
			query.qname = format["qname"]
			query.spark_build = self.spark_build(format["spark_code"])
			query.emitter = self.emitter_func(format["em_format"])
			self.queries.append(query)'''
		
		self.emitter = Emitter(self.conf, self.queries)
	
	'''
	def spark_build(self, spark_code):
		def func(data): # 处理data的过程会不会成为瓶颈?
			def kv_split(x):
				kv = x[4:].split(' ')
				return kv[0], int(kv[1])

			kvs = data.map(kv_split)
			return eval(spark_code) # run the Spark code.

		return func

	def emitter_func(self, em_format):
		def func(data):
			# print("[Emitter Server] ", data)
			self.em_cnt += 1
			key_len = unpack("!H", data[0:2])[0]
			val_len = unpack("!H", data[2:4])[0]
			# currently fix it to origin
			em_format = "origin"
			if em_format == "origin":
				key = str(unpack(str(key_len) + "s", data[4:4+key_len])[0], encoding="ASCII")
			else:
				key = em_format
			
			val = unpack("!I", data[4+key_len:4+key_len+val_len])[0]
			return key+' '+str(val)+'\n'

		return func'''
	
	def start(self):
		self.emitter.start()
	
	def stop(self):
		if self.emitter != None:
			self.emitter.stop()

	def clear(self):
		self.em_cnt = 0

	def get_result(self):
		
		return self.em_cnt
	

if __name__ == "__main__":
	from config.config_hw import em_conf

	# control message exchange with Monitor, performance dull.
	listener = Listener((em_conf["server_addr"], em_conf["server_port"]))
	print("listening, waiting for monitor")
	conn = listener.accept()
	try:
		print("=== accepted ===")
		formats = conn.recv()

		em_server = Emitter_Server(em_conf, formats)
		em_server_thread = Thread(name="em_server", target=em_server.start) # run the emitter.
		em_server_thread.start()
		conn.send("ready")
		print("=== ready ===")

		# the control message is low-perform-demand, so just keep the python. 
		while True:
			msg = conn.recv()
			if msg == "stop":
				print("received stop event")
				# wait for all messages to be processed
				time.sleep(5)
				em_server.stop()
				conn.send(em_server.get_result())
				break
				
			if msg == "clear":
				print("--- clear ---")
				em_server.clear()
				conn.send("clear ack")

	except:
		traceback.print_exc()
	finally:
		print("=== exit ===")
		if em_server != None:
			em_server.stop()
		exit(0)
