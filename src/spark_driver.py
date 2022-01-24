from scapy.all import *
from multiprocessing.connection import Client, Listener
import time
import logging
from threading import Thread
from struct import unpack
import pickle
import re
from pyspark import SparkContext
from pyspark.streaming import StreamingContext

class SparkDriver(object):
	def __init__(self, sp_conf, query):
		self.conf = sp_conf
		self.query = query

	def start(self):
		# note: in local[n], n should be greater than 1!
		self.sc = SparkContext("local[%i]" % (self.query.qid + 1), self.query.qname)
		self.ssc = StreamingContext(self.sc, 1)
		self.sc.setLogLevel('OFF')
		self.input = self.ssc.socketTextStream(self.conf["spark_addr"], self.conf["spark_port"])
		self.output = self.query.spark_build(self.input)

		if self.conf["echo"]:
			echo_conn = Client((self.conf["echo_addr"], self.conf["echo_port"]))
			# TODO
			self.output.pprint()
			# self.output.foreachRDD(lambda rdd: rdd.foreach(lambda x: echo_conn.send(x)))
		else:
			self.output.pprint()

		# self.output.foreachRDD(lambda rdd: rdd.foreach(self.query.output))

		self.ssc.start()
		self.ssc.awaitTermination()

	def stop(self):
		self.ssc.stop(stopSparkContext=True, stopGraceFully=True)
