from scapy.all import *
from src.utils import *
SEND_ITER = 10

class Sender(object):
	def __init__(self, sd_conf, queries):
		self.conf = sd_conf
		self.queries = queries
		self.logger = get_logger(__name__, logging.INFO)

	def start(self):
		print("==============================================")
		print("               start sending")
		print("==============================================")
		
		for query in self.queries:
			query._sd_iter = 0
		
		# send one packet for each query once
		while True:
			has_send = False
			for query in self.queries:
				if query._sd_iter < query.sd_iter:
					# get packet
					p = query.sender()
					# send packet
					self.logger.info(p['UDP'].load)
					sendp(p, iface=self.conf["send_iface"], verbose=0)
					query._sd_iter += 1
					has_send = True

			if not has_send:
				break
			time.sleep(0.1)

		print("==============================================")
		print("                send complete")
		print("==============================================")



if __name__ == "__main__":
	sd_conf = {
		"iter": SEND_ITER,
		"send_iface": "enp129s0f1",

	}