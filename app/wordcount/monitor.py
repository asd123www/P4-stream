from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

queries = [PacketStream(1, 'WordCount')
			.Reduce('add3', 'sum', 3, 4096)
        	.Filter('origin', '32w3', '>=')
			]

conf.update["split"] = 3

Monitor(conf, queries)
