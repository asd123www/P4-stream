
from src.packetstream import PacketStream
from p4_compiler.P4Generator import P4Generator
import os

''' test code. '''
if __name__ == '__main__':

    WORDCOUNT_QID = 1
    qconf = {
        "split": 3,
        "is_hash": True
    }
    queries = [PacketStream(1, 'WordCount', qconf)
                .Map('random', (((None, "random", None), "assign"), None, None))
                .Filter((('random', '-', '2345958'), '>'))
                .Reduce("random")]
    
    # split task
    p4_queries = []
    spark_queries = []
    for query in queries:
        p4_query, spark_query, success = query.split()
        assert(success)
        p4_queries.append(p4_query)
        spark_queries.append(spark_query)

    # Generate .p4 file, format, command.py
    # p4_code, sh_code, em_formats = "", "", [{"qid":0, "qname":"test", "em_format":"origin"}]
    p4_code, sh_code, em_formats = P4Generator(p4_queries).solve()


    print(os.path.dirname(__file__) + "/test.p4")
    # # print(self.sh_code)
    # with open(os.path.dirname(__file__) + "/test.py", "w") as file:
    #     file.write(sh_code)
    with open(os.path.dirname(__file__) + "/test.p4", "w") as file:
        file.write(sh_code)