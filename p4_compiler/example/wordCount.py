# coding:utf8
# Author: Kira Sun
# Email: sunhaifeng@ict.ac.cn
# Time: 2020-03-04 15:25
import json

from autosketch_query_lang.sonata_frontend.packet_stream import PacketStream
from autosketch_runtime.runtime import Runtime

if __name__ == '__main__':
    config_path = '../../configs/autosketch_conf.json'

    with open(config_path) as json_data_file:
        data = json.load(json_data_file)
    #
    # config = data["on_server"][data["is_on_server"]]["telemetry"]

    ddos_attack = (P4Generator(qid=1)
                   .map()
                   .map(keys=('ipv4.dstIP',), map_values=('count',), func=('eq', 1,))
                   .reduce(keys=('ipv4.dstIP',), func=('sum',))
                   .filter(filter_vals=('count',), func=('geq', 40))
                   .map(keys=('ipv4.dstIP',))
                   )
    print(str(ddos_attack))

    queries = {'ddos_attack': ddos_attack}
    runtime = Runtime(queries, data)
    # config["final_plan"] = [(1, 5)]
    #
    # # print("*********************************************************************")
    # # print("*                   Receiving User Queries                          *")
    # # print("*********************************************************************\n\n")
    # runtime = Compiler('ddos_attack', config, queries)