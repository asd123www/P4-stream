from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

qconf = {
	"split": 2,
	"is_hash": True
}

queries = [PacketStream(0, 'WordCount', qconf)
			.Reduce('add3', 'sum', 3, 4096)
        	.Filter('origin', '32w3', '>=')
			]

Monitor(conf, queries)
