# sender_server is used to write apps that need to perf

from scapy.all import *
from multiprocessing.connection import Listener, Client
import time, datetime
import logging
from scapy.config import conf
from threading import Thread
from struct import pack, unpack
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
			print("echoserver: waiting for echo emitter")
			self.conn = self.listener.accept()
			print("echoserver accepted")
				
		def start(self):
			while True:
				if self.conn.poll(1):
					_ = self.conn.recv()
					self.echo_cnt += 1
					if self.echo_cnt <= 10:
						print("echo received:", _)
					self.last_time = datetime.datetime.now()

				elif self._stop_event.is_set():
					break
		def stop(self):
			self._stop_event.set()

	
	def __init__(self, conf):
		self.conf = conf
		self.listener = Listener((self.conf["server_addr"], self.conf["server_port"]))
		print("listening, waiting for monitor")
		self.conn = self.listener.accept()
		print("accepted")

		if self.conf["echo"]:
			self.echo_server = SenderServer.EchoServer(self)
			self.echo_thread = Thread(name="echo server", target=self.echo_server.start)
			self.echo_thread.start()
		if self.conf["to_file"]:
			if not os.path.exists("log/"):
				os.mkdir("log/")
			self.file = open("log/send.log", "wb")

		self.queries = self.conn.recv()
		self.formats = {}
		for query in self.queries:
			self.formats[query.qid] = query.qconf["is_hash"]
		
		# contains all hashed keys
		self.hash_dict = {}
		self.conn.send("ready")

	def start(self):
		print("=== start ===")
		self.send_cnt = 0
		self.send_bytes = 0
		self.conn.send(("start", None))
		assert (self.conn.recv() == "start ack")
		
		self.start_time = datetime.datetime.now()
	
	def send(self, p, qid):
		key, val = p
		is_hash = self.formats[qid]
		if is_hash:
			hash_key = hash(key)
			self.hash_dict[hash_key] = key
			key = hex(hash_key)
			
		key_len = len(key)
		if key_len & 3:
			key_suf = 4 - (key_len & 3)
			key = key + '_' * key_suf
			key_len += key_suf
		val_len = 4

		length = 4 + key_len + val_len
		data = pack("!H", qid)
		data += pack("!H", length)
		data += pack("!H", key_len)
		data += pack("!H", val_len)
		data += pack(str(key_len) + "s", bytes(key, encoding="ASCII"))
		data += pack("!I", val)

		packet = Ether() / IP(src=self.conf["src_addr"], dst=self.conf["dst_addr"]) / UDP(sport=self.conf["src_port"], dport=self.conf["dst_port"]) / data
		
		if self.conf["to_file"]:

		sendp(packet, iface=self.conf["send_iface"], verbose=0)

		self.send_bytes += len(packet) 
		self.send_cnt += 1
	
	def finish(self):
		print("=== finish ===")
		if self.conf["echo"]:
			self.echo_server.stop()
			# wait for all messages to be processed
			time.sleep(5)
			# this is the time that the last message is echoed
			self.end_time = self.echo_server.last_time
			if self.end_time == None:
				self.end_time = datetime.datetime.now()
		else:
			# this is only the time that last message is sent
			self.end_time = datetime.datetime.now()

		t = self.end_time - self.start_time
		t = t.seconds + t.microseconds / 1000 / 1000
		self.conn.send(("finish", (t, self.send_cnt, self.send_bytes)))
		self.conn.send(t)
		print(self.hash_dict)
