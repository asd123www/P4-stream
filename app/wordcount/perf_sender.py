from src.sender_server import SenderServer
from app.wordcount.wordcount import WORDCOUNT_QID
from config.config_hw import sd_conf
server = SenderServer(sd_conf)

words = ["alice", "bob", "carol", "dave", "eve", "abcdefghijklmn", "o"]
SEND_ITER = 100

server.start()
for i in range(0, SEND_ITER):
	for word in words:
		server.send((word, 1), WORDCOUNT_QID)

server.finish()
