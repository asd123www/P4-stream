from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

WORDCOUNT_QID = 1

qconf = {
	"split": 2,
	"is_hash": True
}

queries = [PacketStream(1, 'WordCount', qconf)
			.Reduce('origin', 'sum', 3, 4096)
        	.Filter('origin', '32w3', '>=')
			]

Monitor(conf, queries)
