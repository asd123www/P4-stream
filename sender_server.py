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
		while True:
			self.client.recv()

	def start(self):
		self.send_cnt = 0
		self.client.send(("start", None))
		assert (self.client.recv("start ack"))
		
		self.start_time = datetime.now()
	
	def send(self, p):
		sendp(p, iface=self.conf["send_iface"], verbose=0)
		self.send_cnt += 1
	
	def finish(self):
		self.end_time = datetime.now()
		t = self.end_time - self.start_time
		self.client.send(("finish", (t, self.send_cnt)))
		self.client.send(t)
	
