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
	class EchoServer(object):
		def __init__(self, sd_server):
			self.sd_server = sd_server
			self.echo_cnt = 0
			self.last_time = None
			self._stop_event = threading.Event()
			self.listener = Listener((self.sd_server.conf["echo_addr"], self.sd_server.conf["echo_port"]))
			self.conn = self.listener.accept()
				
		def start(self):
			while True:
				if self.conn.poll(1):
					self.conn.recv()
					self.echo_cnt += 1
					self.last_time = datetime.now()

				else if self._stop_event.is_set():
					break
		def stop(self):
			self._stop_event.set()

	
	def __init__(self, conf):
		self.conf = conf
		self.client = Client((self.conf["sd_addr"], self.conf["sd_port"]))

		if self.conf["echo"]:
			self.echo_server = SenderServer.EchoServer(self)
			self.echo_thread = Thread(name="echo server", target=self.echo_server.start)
			self.echo_thread.start()

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
		print("=== start ===")
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

		packet = Ether() / IP(src=self.conf["src_addr"], dst=self.conf["dst_addr"]) / UDP(sport=self.conf["src_port"], dport=self.conf["dst_port"]) / data
		sendp(packet, iface=self.conf["send_iface"], verbose=0)

		self.send_bytes += len(packet) 
		self.send_cnt += 1
	
	def finish(self):
		print("=== finish ===")
		if self.conf["echo"]:
			self.echo_server.stop()
			# wait for all messages to be processed
			time.sleep(2)
			# this is the time that the last message is echoed
			self.end_time = self.echo_server.last_time
		else:
			# this is only the time that last message is sent
			self.end_time = datetime.now()

		t = self.end_time - self.start_time
		self.client.send(("finish", (t, self.send_cnt, self.send_bytes)))
		self.client.send(t)
		print(self.hash_dict)
