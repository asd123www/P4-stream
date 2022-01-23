
class PacketStream(object):
	def __init__(self, qid, qname, qconf, operators=[]):
		self.qid = qid
		self.qname = qname
		self.operators = operators
		self.qconf = qconf
		
	def Map(self, *args):
		self.operators.append(('Map', args))
		return self
	
	def Filter(self, *args):
		self.operators.append(('Filter', args))
		return self
	
	def Reduce(self, *args):
		self.operators.append(('Reduce', args))
		return self
	
	def split(self):
		t = self.qconf["split"]
		if t > len(self.operators):
			print("don not have enough operators")
			return None, None, False
		
		return PacketStream(self.qid, self.qname, self.qconf self.operators[0:t]), PacketStream(self.qid, self.qname, self.qconf, self.operators[t:]), True