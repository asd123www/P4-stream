# sender_server is used to write apps that need to perf

from scapy.all import *
from multiprocessing.connection import Listener, Client
import time, datetime
import logging
from scapy.config import conf
from threading import Thread
from struct import unpack
import pickle
import re
from src.utils import *

class SenderServer(object):
	def __init__(self, conf):
		self.conf = conf
		self.client = Client((self.conf["sd_addr"], self.conf["sd_port"]))

		self.queries = self.client.recv()
		self.formats = {}
		for query in self.queries:
			self.formats[query.qid] = query.qconf["is_hash"]
		
		# contains all hashed keys
		self.hash_dict = {}
		self.client.send("ready")

		while True:
			self.client.recv()

	def start(self):
		self.send_cnt = 0
		self.client.send(("start", None))
		assert (self.client.recv("start ack"))
		
		self.start_time = datetime.now()
	
	def send(self, p, qid):
		key, val = p
		is_hash = self.formats[qid]
		if is_hash:
			key_len = 8
			hash_key = hash(key)
			self.hash_dict[hash_key] = key
		else:
			key_len = len(key)
		val_len = 4

		length = 4 + key_len + val_len
		data = pack("!H", qid)
		data += pack("!H", length)
		data += pack("!H", key_len)
		data += pack("!H", val_len)
		if is_hash:
			data += pack("!Q", hash_key)
		else:
			data += pack(str(key_len) + "s", bytes(key, encoding="ASCII"))
		data += pack("!I", val)

		sendp(Ether() / IP(src=self.conf["src_addr"], dst=self.conf["dst_addr"]) / UDP(sport=self.conf["src_port"], dport=self.conf["dst_port"]) / data, iface=self.conf["send_iface"], verbose=0)

		self.send_cnt += 1
	
	def finish(self):
		self.end_time = datetime.now()
		t = self.end_time - self.start_time
		self.client.send(("finish", (t, self.send_cnt)))
		self.client.send(t)
		print(self.hash_dict)
