from scapy.all import *
from multiprocessing.connection import Listener
import time
import logging
from scapy.config import conf
from threading import Thread
from struct import unpack
import pickle
import re
from src.spark_driver import SparkDriver
from src.utils import *

class Emitter(object):
	# queries has functions: spark_build, emitter_func
	def __init__(self, em_conf, queries):
		self.conf = em_conf
		self.queries = queries
		self.listener = Listener((self.conf["spark_addr"], self.conf["spark_port"]))
		self.sniff_iface = self.conf["sniff_iface"]
		
		self._stop_event = threading.Event()

		# create a logger for the object
		self.logger = get_logger(__name__, logging.INFO)
		
		# start spark threads
		print("Waiting for socket")
		self.spark_conns = {}
		self.spark_threads = {}
		self.spark_drivers = {}
		for query in self.queries:
			# create a sparkdriver for each query
			spark_driver = SparkDriver(self.conf, query)
			spark_thread = Thread(name="spark%i" % query.qid, target=spark_driver.start)
			
			spark_thread.start()
			spark_conn = self.listener.accept()
			# print("setup connection with query %i" % qid)
			self.spark_drivers[query.qid] = spark_driver
			self.spark_conns[query.qid] = spark_conn
			self.spark_threads[query.qid] = spark_thread


	def start(self):

		print("Sniffing on interface: ", self.sniff_iface)
		while True:
			if self._stop_event.is_set():
				break

			sniff(iface=str(self.sniff_iface), prn=lambda x: self.process_packet(x), timeout=1)

		self.listener.close()
		for query in self.queries:
			self.spark_drivers[query.qid].stop()
			self.spark_threads[query.qid].join(1)
		
	
	def stop(self):
		self._stop_event.set()

	def process_packet(self, p):
		
		if not 'UDP' in p:
			print("not an UDP packet")
			return

		data = p['UDP'].load
		# print("[Emitter] ", data)
		src_port = p['UDP'].sport
		dst_port = p['UDP'].dport

		# extract header
		qid = unpack('!H', data[0:2])[0]
		length = unpack('!H', data[2:4])[0]

		self.logger.info(data)
		for query in self.queries:
			if qid == query.qid:
				# parse kvs
				kvs = query.emitter(data[4:4+length])
				# send kvs to spark
				# rdd_packet = (src_port, dst_port, qid, kvs)
				spark_conn = self.spark_conns[qid]

				spark_conn.send_bytes(bytes(kvs, encoding='utf-8'))
				return

if __name__ == '__main__':
	from app.wordcount import emitter

	em_conf = {
		"sniff_iface" : "enp129s0f1",
		"spark_addr" : "localhost",
		"spark_port" : 3002,
		"log_path": "log/",
	}

	emitter = Emitter(em_conf, [])
	emitter.start()