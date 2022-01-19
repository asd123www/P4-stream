import sys, os
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re
from src.sender import Sender
from src.spark_driver import SparkDriver
from src.p4_driver import P4Driver
from src.utils import *


class Runtime(object):
	def __init__(self, conf, queries):
		self.conf = conf
		self.queries = queries
		self.sender = Sender(self.conf["sd_conf"], self.queries)
		self.sender_thread = Thread(name="sender", target=self.sender.start)
		self.sender_thread.start()

		self.sender_thread.join()
	
		print("Finished. Press `Ctrl+C` to exit.")
		sys.exit(0)

