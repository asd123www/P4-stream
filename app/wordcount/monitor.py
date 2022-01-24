from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

WORDCOUNT_QID = 1

qconf = {
	"split": 4,
	"is_hash": True
}

queries = [PacketStream(1, 'WordCount', qconf)
			.Reduce('origin', 'sum', 3, 4096)
        	.Map('origin', 'low_bit', '32w7', '&')
			.Filter('low_bit', '32w0', '==')
			.Map('origin', 'reserve', '32w0', '+')
			]

Monitor(conf, queries)