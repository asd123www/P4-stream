from src.packetstream import PacketStream

'''
Spark code generator.
But with the sematic problem, now only one key in default.
Futher changes needed to cope with Switch generating multiple (k, v) pairs -> change Spark generator.
'''


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

			keys = [None, format["em_format"]]
			def find_last(key):
				return len(keys) - keys[::-1].index(key) - 1

			for opt, args in q.operators:
				if opt == "Map":
					old_key, new_key, constant, operation = args
					np = []
					for i in range(0, len(keys)):
						np.append("p[%d]" % i)

					if operation == "=":
						if old_key == None and constant != None:
							rhs = "%d" % getint(constant)
						elif old_key != None and constant == None:
							rhs = "p[%d]" % find_last(old_key)
						else:
							raise Exception("exactly one of old_key and constant must be None")
					else:
						rhs = "p[%d] %s %d" % (find_last(old_key), operation, getint(constant))

					if new_key in keys:
						np[find_last(new_key)] = rhs
					else:
						keys.append(new_key)
						np.append(rhs)

					code += ".map(lambda p: (%s))" % (', '.join(np))
					
				elif opt == "Filter":
					key, threshold, operation = args
					code += ".filter(lambda p: (p[%d] %s %s))" % (find_last(key), operation, getint(threshold))

				elif opt == "Reduce":
					key, operation = args[:2]
					if key == keys[1]:
						nkey = "p[0]"
					else:
						nkey = "'%s'" % key

					code += ".map(lambda p: (%s, p[%d]))" % (nkey, find_last(key))
					keys = [None, key]

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
	
	qconf = {
		"split": 0,
		"is_hash": False
	}

	ps = [PacketStream(0, "test", qconf)
			.Map("origin", "a", "1", "+")
			.Map("a", "origin", "1", "+")
			.Filter("a", "1", ">=")
			.Reduce("origin", "sum")]
	
	ef = [{
		"qid": 0,
		"qname": "text",
		"em_format": "origin"
	}]
	sg = SparkGenerator(ef, ps)
	print(sg.solve()[0]["spark_code"])
