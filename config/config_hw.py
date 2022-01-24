import os

ISECHO = True

sd_conf = {
		"send_iface": "enp129s0f1",
		"server_addr": "10.16.0.10",
		"server_port": 2010,
		"src_addr":"10.1.100.1",
		"src_port":1111,
		"dst_addr":"10.1.100.2",
		"dst_port":2222,
		"echo": ISECHO,
		"echo_addr": "10.16.0.10",
		"echo_port": 2033,
		"to_file": False,
	}

em_conf = {
		"sniff_iface" : "enp129s0f1",
		"spark_addr" : "localhost",
		"spark_port" : 3002,
		"server_addr" : "10.16.0.9",
		"server_port" : 3010,
		"echo": ISECHO,
		"echo_addr": "10.16.0.10",
		"echo_port": 2033,
	}

p4_conf = {
		"hw": True,
		"p4_path": os.path.join(os.getcwd(), "p4"),
		"server_addr": "10.16.0.18", # bf2
		"server_port": 4010,
		"tmp_name": "tmp",

	}

conf = {
	"sd_conf":sd_conf,
	"em_conf":em_conf,
	"p4_conf":p4_conf,
	"log_path": "log/",
}
