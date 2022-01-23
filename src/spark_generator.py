class SparkGenerator(object):
	def __init__(self, em_formats, queries):
		self.em_formats = em_formats
		self.queries = queries
	
	def solve(self):
		em_formats = []
		for format in em_formats:
			# find the query with the same qid
			for query in self.queries:
				if query.qid == format["qid"]:
					break
			
			code = "kvs"
			# TODO
			format.update({
				"spark_code": code
			})
			em_formats.append(format)
			
		return em_formats