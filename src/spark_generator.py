from src.packetstream import PacketStream

def getint(s):
	return int(s.split('w')[-1])

class SparkGenerator(object):
	def __init__(self, em_formats, queries):
		self.em_formats = em_formats
		self.queries = queries
	
	def solve(self):
		em_formats = []
		for format in self.em_formats:
			# find the query with the same qid
			q = None
			for query in self.queries:
				if query.qid == format["qid"]:
					q = query
					break
			
			code = "kvs"
			for opt, args in q.operators:
				if opt == "Map":
					old_key, new_key, constant, operation = args
					if new_key == "origin":
						code += ".map(lambda p: (p[0], p[1] %s %d))" % (operation, getint(constant))
					else:
						code += ".map(lambda p: ('%s', p[1] %s %d))" % (new_key, operation, getint(constant))
					
				elif opt == "Filter":
					key, threshold, operation = args
					code += ".filter(lambda p: (p[1] %s %s))" % (operation, getint(threshold))

				elif opt == "Reduce":
					key, operation = args[:2]
					if operation == "sum":
						code += ".reduceByKey(lambda a, b: a + b)"
					elif operation == "max":
						code += ".reduceByKey(lambda a, b: a > b ? a : b)"
					elif operation == "min":
						code += ".reduceByKey(lambda a, b: a < b ? a : b)"


			format.update({
				"spark_code": code
			})
			em_formats.append(format)
			
		return em_formats

if __name__ == "__main__":
	ps = [PacketStream(0, "test")
			.Map("a", "b", "1", "+")
			.Filter("b", "1", ">=")
			.Reduce("b", "sum")]
	
	ef = [{
		"qid": 0,
		"qname": "text",
		"em_format": "a"
	}]
	sg = SparkGenerator(ef, ps)
	print(sg.solve()[0]["spark_code"])
