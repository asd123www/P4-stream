from src.sender_server import SenderServer

from config.config_hw import sd_conf
server = SenderServer(sd_conf)
server.start()
server.finish()
