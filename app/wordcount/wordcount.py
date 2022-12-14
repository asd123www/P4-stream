import sys
import os
sys.path.append(".")
from random import randint
from scapy.all import *
from struct import pack, unpack
import numpy as np
from src.runtime import Runtime

current_path = os.path.abspath(__file__)

words = ["pie", "a", "banana", "apple", "responsbility"]

probs = np.array([10, 5, 3, 2, 7], dtype=float)
probs /= np.sum(probs)

WORDCOUNT_QID = 1
WORDCOUNT_THRESH = 3

q_conf = {
	"qid":WORDCOUNT_QID,
	"src_addr":"10.1.100.1",
	"src_port":1111,
	"dst_addr":"10.1.100.2",
	"dst_port":2222,
	"sd_iter":100
}

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
		self.sd_iter = self.conf["sd_iter"]
		self.thresh = WORDCOUNT_THRESH

	def emitter(self, packet):
		# kv 0
		key_len = unpack("!H", packet[0:2])[0]
		val_len = unpack("!H", packet[2:4])[0]

		assert(val_len == 4)
		# key - str: word
		key = str(unpack(str(key_len) + "s", packet[4:4+key_len])[0], encoding="ASCII")
		# val - int: count 
		val = unpack("!I", packet[4+key_len:4+key_len+val_len])[0]

		return key+';'+str(val)+'\n'


	def sender(self):
		
		# construct payload
		r = random.random()
		
		for i in range(0, len(probs)):
			r -= probs[i]
			if r <= 0:
				word = words[i]
				break
		
		key_len = len(word)
		# Currently, we pad all words to 32B
		word = word + (''*(32-key_len))
		key_len = 32
		# print(type(word), word)
		val_len = 4
		length = 4 + key_len + val_len
		data = pack("!H", self.qid)
		data += pack("!H", length)
		data += pack("!H", key_len)
		data += pack("!H", val_len)
		data += pack(str(key_len) + "s", bytes(word, encoding="ASCII"))
		data += pack("!I", 1)
		
		return Ether() / IP(src=self.conf["src_addr"], dst=self.conf["dst_addr"]) / UDP(sport=self.conf["src_port"], dport=self.conf["dst_port"]) / data
		
	def spark_build(self, kvs):
		def kv_split(x):
			kv = x[4:].split(';')
			return kv[0], int(kv[1])

		kvs1 = kvs.map(kv_split)
		return kvs1

	def output(self, kvs):
		print(kvs)

if __name__ == '__main__':

	from config.config import conf

	conf["p4_conf"].update({
		"app":"word_count_sketch"
	})
	query = WordCount(q_conf)
	Runtime(conf, [query])