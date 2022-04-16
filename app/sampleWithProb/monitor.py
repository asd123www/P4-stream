from src.monitor import Monitor
from src.packetstream import PacketStream
from config.config_hw import conf

SampleWithProbID = 2

qconf = {
	"split": 2,
	"is_hash": False
}

queries = [PacketStream(1, 'SampleWithProb', qconf)
        	.Map('origin', 'rand32', 'random', '=')
			.Filter('rand32', '32w2147483648', '<') # 采样一半
			]


Monitor(conf, queries)