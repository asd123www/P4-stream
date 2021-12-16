import sys
import os
sys.path.append(".")
from random import randint
from scapy.all import *
from struct import pack, unpack
import numpy as np
from src.runtime import Runtime
from config.config import conf

words = ["pie", "a", "banana", "apple", "responsbility"]

probs = np.array([10, 5, 3, 2, 7], dtype=float)
probs /= np.sum(probs)

WORDCOUNT_QID = 1

class WordCount(object):

	def __init__(self, conf):
		self.conf = conf
		if "qname" not in self.conf.keys():
			self.qname = "WordCount"
		else:
			self.qname = self.conf["qname"]
		if "qid" not in self.conf.keys():
			self.qid = WORDCOUNT_QID
		else:
			self.qid = self.conf["qid"]
		

	def emitter(self, packet):
		# kv 0
		key_len = unpack("!H", packet[0:2])
		val_len = unpack("!H", packet[2:4])
		assert(val_len == 4)
		# key - str: word
		key = str(unpack("s", packet[4:4+key_len]), encoding="ASCII")
		# val - int: count 
		val = unpack("!I", packet[4+key_len:4+key_len+val_len])

		return {key:val}


	def sender(self):
		
		# construct payload
		r = random.random()
		
		for i in range(0, len(probs)):
			r -= probs[i]
			if r <= 0:
				word = words[i]
				break
		
		key_len = len(word)
		# print(type(word), word)
		val_len = 4
		length = 4 + key_len + val_len
		data = pack("!H", self.qid)
		data += pack("!H", length)
		data += pack("!H", key_len)
		data += pack("!H", val_len)
		data += pack("s", bytes(word, encoding="ASCII"))
		data += pack("!I", 1)
		
		return Ether() / IP(src=self.conf["src_addr"], dst=self.conf["dst_addr"]) / UDP(sport=self.conf["src_port"], dport=self.conf["dst_port"]) / data
		
	def spark_build(self, kvs):
		
		return kvs

	def output(self, kvs):
		print("received word count result: ", kvs)
	
if __name__ == '__main__':

	q_conf = {
		"qid":WORDCOUNT_QID,
		"src_addr":"10.1.100.1",
		"src_port":1111,
		"dst_addr":"10.1.100.2",
		"dst_port":2222,
	}
	conf["q_conf"] = q_conf
	conf["p4_app"] = "simple_l3"
	query = WordCount(q_conf)
	Runtime(conf, [query])
