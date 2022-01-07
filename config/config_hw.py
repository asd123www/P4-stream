import os
sd_conf = {
		"send_iface": "veth1",
	}

em_conf = {
		"sniff_iface" : "veth3",
		"spark_addr" : "localhost",
		"spark_port" : 3002,
	}

p4_conf = {
		"hw": True,
		"p4_path": os.path.join(os.getcwd(), "p4"),
	}

conf = {
	"sd_conf":sd_conf,
	"em_conf":em_conf,
	"p4_conf":p4_conf,
	"log_path": "log/",
}
