
class PacketStream(object):
	def __init__(self, qid, qname, operators=[], t=0):
		self.qid = qid
		self.qname = qname
		self.operators = operators
		self.t = t
		
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
		if self.t > len(self.operators):
			print("don not have enough operators")
			return None, None, False
		
		return PacketStream(self.qid, self.qname, self.operators[0:self.t]), PacketStream(self.qid, self.qname, self.operators[self.t:]), True