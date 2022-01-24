from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

qconf = {
	"split": 0,
	"is_hash": False
}

queries = [PacketStream(1, 'WordCountRaw', qconf)
			.Reduce('origin', 'sum', 3, 4096)
        	.Filter('origin', '32w3', '>=')
			]

Monitor(conf, queries)
