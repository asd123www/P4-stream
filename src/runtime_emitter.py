import sys, os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re
from src.sender import Sender
from src.emitter import Emitter
from src.spark_driver import SparkDriver
from src.p4_driver import P4Driver
from src.utils import *


class Runtime(object):
	def __init__(self, conf, queries):
		self.conf = conf
		self.queries = queries

		self.emitter = Emitter(self.conf["em_conf"], self.queries)
		self.emitter_thread = Thread(name="emitter", target=self.emitter.start)

		self.emitter_thread.start()
		
		a = input()

		self.emitter.stop()
		self.emitter_thread.join()
		print("Finished. Press `Ctrl+C` to exit.")
		sys.exit(0)

