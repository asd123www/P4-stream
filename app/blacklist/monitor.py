from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

qconf = {
	"split": 0,
	"is_hash": False
}

queries = [PacketStream(1, 'Blacklist', qconf)
			.Reduce('origin', 'max', 3, 4096)
        	.Filter('origin', '32w0', '==')
			]

Monitor(conf, queries)
