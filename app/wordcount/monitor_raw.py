from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

WORDCOUNT_QID = 1

qconf = {
	"split": 0,
	"is_hash": False
}

queries = [PacketStream(1, 'WordCount', qconf)
			.Reduce('origin', 'sum', 3, 4096)
			]

Monitor(conf, queries)