
from src.packetstream import PacketStream
from p4_compiler.P4Generator import P4Generator
import os

# PacketStream.map(rd, "random")
#                         .map(cnt, "1")
#             .reduce(cnt)
#             .map(condition, [cnt <= N_1]?
#                                             1:
#                                             [cnt <= N_2]?
#                                                 [rd <= Threshold_1]:
#                                                 [rd <= Threshold_2])
#             .filter([condition == 0])

# stateful_sampling
''' test code. '''
if __name__ == '__main__':

    WORDCOUNT_QID = 1
    qconf = {
        "split": 5,
        "is_hash": True
    }

    true_cond = ((("1", "immediate", None), "assign"), None, None)
    false_cond = ((("0", "immediate", None), "assign"), None, None)

    # aaaa = ((("c", "+", "d"), "assign"), None, None)
    # aaab = ((("c", "+", "d"), "assign"), None, None)

    aab = ((("random", "-", "1111111"), "<="), true_cond, false_cond) # threshold_2
    aaa = ((("random", "-", "2222222"), "<="), true_cond, false_cond) # threshold_1

    ab = ((("cnt", "-", "10000000"), "<="), aaa, aab) # N_2x
    condition = ((("cnt", "-", "100000"), "<="), true_cond, ab, 2) # N_1
    # 注意第一层一定要写个`2`, 要不然没法识别是不是第一层.

    queries = [PacketStream(1, 'WordCount', qconf)
                .Map('cnt', ((("1", "immediate", None), "assign"), None, None, 2))
                .Reduce('cnt')
                .Map('random', (((None, "random", None), "assign"), None, None, 2))
                .Map('cond', condition)
                .Filter((('cond', '-', '0'), '=='))]
    
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
        file.write(p4_code)