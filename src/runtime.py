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
		
		self.p4_driver = P4Driver(self.conf["p4_conf"])
		# start p4
		self.p4_driver.compile()
		self.p4_model_thread = Thread(name="p4_model", target=self.p4_driver.start_model)
		self.p4_model_thread.start()
		time.sleep(10)
		self.p4_driver_thread = Thread(name="p4_driver", target=self.p4_driver.start_driver)
		self.p4_driver_thread.start()
		time.sleep(10)
		self.p4_driver_command_thread = Thread(name="p4_command", target=self.p4_driver.send_command)
		self.p4_driver_command_thread.start()
		time.sleep(10)
		# print(self.interfaces["veth1"][0].address)
		
		# self.create_interfaces()
		self.sender = Sender(self.conf["sd_conf"], self.queries)
		self.sender_thread = Thread(name="sender", target=self.sender.start)

		self.emitter = Emitter(self.conf["em_conf"], self.queries)
		self.emitter_thread = Thread(name="emitter", target=self.emitter.start)

		self.emitter_thread.start()
		
		self.sender_thread.start()

		self.sender_thread.join()
		self.emitter.stop()
		self.emitter_thread.join()
		# print("emitter joined")
		self.p4_driver_thread.join(1)
		# print("p4_driver joined")
		self.p4_model_thread.join(1)
		# print("p4_model joined")
		print("Finished. Press `Ctrl+C` to exit.")

	def create_interfaces(self):
		Interfaces(self.conf["interfaces"]["sender"][0], self.conf["interfaces"]["sender"][1]).setup()
		Interfaces(self.conf["interfaces"]["emitter"][0], self.conf["interfaces"]["emitter"][1]).setup()
		



