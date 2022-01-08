import sys
import os
sys.path.append(".")
from random import randint
from scapy.all import *
from struct import pack, unpack
import numpy as np
from src.runtime import Runtime
from src.emitter import Emitter

from app.wordcount.wordcount import q_conf, WordCount

if __name__ == "__main__":

	from config.config_hw import conf

	conf["p4_conf"].update({
		"app":"word_count_sketch"
	})
	query = WordCount(q_conf)
	emitter = Emitter(query["em_conf"], [query])

	emitter.start()