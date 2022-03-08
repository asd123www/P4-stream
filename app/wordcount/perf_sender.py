from email.utils import format_datetime
from src.sender_server import SenderServer
from app.wordcount.wordcount import WORDCOUNT_QID
from config.config_hw import sd_conf

server = SenderServer(sd_conf)

dataPath = "./data/wordCount.txt"
words = ["alice", "bob", "carol", "dave", "eve", "abcdefghijklmn", "o"]
# SEND_ITER = 100 meaningless.

# prepare the data to send.
with open(dataPath, "w") as f:
	f.write(f'{WORDCOUNT_QID}\n')
	for word in words:
		f.write(f'{word} 1\n')

server.start()

server.send('wordCount')

server.finish()