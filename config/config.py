import os
sd_conf = {
		"send_iface": "enp129s0f1",
	}

em_conf = {
		"sniff_iface" : "enp129s0f1",
		"spark_addr" : "localhost",
		"spark_port" : 3002,
	}

p4_conf = {
		"hw": False,
		"p4_path": os.path.join(os.getcwd(), "p4"),
	}

conf = {
	"sd_conf":sd_conf,
	"em_conf":em_conf,
	"p4_conf":p4_conf,
	"log_path": "log/",
}
