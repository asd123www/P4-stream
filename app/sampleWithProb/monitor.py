from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

SampleWithProbID = 2

qconf = {
	"split": 2,
	"is_hash": False
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
			.Map('cond', condition)
			.Filter((('cond', '-', '0'), '=='))]

Monitor(conf, queries)