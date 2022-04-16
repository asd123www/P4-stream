from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

SampleWithProbID = 2

qconf = {
	"split": 2,
	"is_hash": False
}


# 需要修改filter.
queries = [PacketStream(1, 'SampleWithProb', qconf)
        	.Map('origin', 'count', '32w1', '=')
			.Reduce('count', 'sum', 3, 4096) # count number.
			.Map('origin', 'rand', 'random', '=')
            ]


Monitor(conf, queries)