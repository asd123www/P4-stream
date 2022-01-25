from src.sender_server import SenderServer
from app.wordcount.wordcount import WORDCOUNT_QID
from config.config_hw import sd_conf
server = SenderServer(sd_conf)

SEND_ITER = 300

server.start()
for i in range(0, SEND_ITER):
	server.send((str(i), i), WORDCOUNT_QID)

server.finish()
