#include "udp.c"

// 
packet_data_t* generate_packet(int payload) {
    packet_data_t* pkt = rte_malloc(NULL, sizeof(packet_data_t), 64);
    pkt->data = pkt->mbuf; // 直接把payload放在mbuf偏移 ether+ipv4+udp 的位置即可.
    pkt->length = payload_length + sizeof(ethernet_header_t) + sizeof(ipv4_header_t) + sizeof(udp_header_t);
    pkt->header_tail = pkt->headers;
    packet_header_t* ethh = pkt->header_tail ++;
    packet_header_t* ipv4h = pkt->header_tail ++;
    packet_header_t* udph = pkt->header_tail ++;
    ethh->data = pkt->data;
    ethh->length = sizeof(ethernet_header_t);
    ipv4h->data = pkt->data + sizeof(ethernet_header_t);
    ipv4h->length = sizeof(ipv4_header_t);
    udph->data = pkt->data + sizeof(ethernet_header_t) + sizeof(ipv4_header_t);
    udph->length = sizeof(udp_header_t);

    ethernet_header_t* eth = ethh->data;
    ipv4_header_t* ipv4 = ipv4h->data;
    udp_header_t* udp = udph->data;
    rte_memcpy(eth->dst, dst_mac, sizeof(dst_mac));
    rte_memcpy(eth->src, devices_hwaddr[0], sizeof(dst_mac));
    eth->type = ETH_PROTO_TYPE_IPV4;
    ipv4->src = src_ip;
    ipv4->dst = dst_ip;
    ipv4->proto = IP_PROTO_TYPE_UDP;
    ipv4->version = 4;
    ipv4->ihl = ipv4h->length >> 2;
    ipv4->tos = 0;
    ipv4->len = htons(ipv4h->length + udph->length + payload_length);
    ipv4->id = 0;
    ipv4->frag_off = 0;
    ipv4->ttl = 24;
    udp->sport = htons(src_port);
    udp->dport = htons(dst_port);
    udp->len = htons(udph->length + payload_length);
    return pkt;
}

void sender(char *appName, uint64_t bandwidth, uint32_t burst_size) {
    // the c code define thread_num.
    uint8_t thread_num;
    uint32_t src_ip, dst_ip;
    uint16_t src_port, dst_port;
    uint8_t dst_mac[6];

    uint32_t payload_length = 0;  // length of payload, you should change it to key-value pair.
    // uint64_t bandwidth;   // Mbps while inputting, Bps while processing
    // uint32_t burst_size;

    uint64_t next_send_tick = 0;


    dpdk_init("11111", 0);

    cqs_core_affinitize_dpdk(0);

    dpdk_module_func.load_module();
    
    void* up_handle = dpdk_module_func.init_handle_up(devices_attached[0], 0);
    void* down_handle = dpdk_module_func.init_handle_down(devices_attached[0]);

    for(int i = 0; i < num_devices_attached; i ++) dpdk_module_func.start_iface(devices_attached[i]);

    printf("initialized\n");

    // in the parameter.
    src_ip = s2ipv4("10.0.12.9");
    dst_ip = s2ipv4("10.0.12.10");
    src_port = 45678;
    dst_port = 23233;
    s2macaddr((char*)dst_mac, "3c:fd:fe:bb:ca:81");

    // sscanf(argv[1], "%d", &payload_length);
    // sscanf(argv[2], "%ld", &bandwidth);
    // sscanf(argv[3], "%d", &burst_size);
    bandwidth *= 1000000; bandwidth /= 8;



    const int wordNumber = 7;
    const int wordLength = 100;

    int length[wordNumber];
    char words[wordNumber][wordLength] = {"alice", "bob", "carol", "dave", "eve", "abcdefghijklmn", "o"};
    // (word, 1)

    for (int i = 0; i < wordNumber; ++i) {
        length[i] = strlen(words[i]);
        payload_length += length[i];
    }
    uint32_t SEND_ITER = 100;

    packet_data_t* pkt[wordNumber];
    for(int i = 0; i < wordNumber; ++i) {
        // you should define the payload here.
        unsigned char a[wordLength];
        memcpy(a, words[i], length[i]);
        generate_packet(length[i]);
    }

    uint16_t ip_id = 0;
    uint64_t sending_length = burst_size * payload_length;
    ipv4_header_t* ipv4 = pkt[0]->data + sizeof(ethernet_header_t);
    while(1) {
        struct timespec time = {0, 0};
        clock_gettime(CLOCK_MONOTONIC, &time);
        uint64_t tick = time.tv_sec*1000000000LL + time.tv_nsec;
        if(tick >= next_send_tick) {
            for(int i = 0; i < burst_size; i ++) for (int j = 0; j < wordNumber; ++j) {
                void* ptr = dpdk_module_func.get_wptr(up_handle, pkt, pkt[j]->length);
                ipv4->id = ntohs(ip_id ++);
                rte_memcpy(ptr, pkt[j]->data, 64);
            }
            dpdk_module_func.send_pkts(up_handle);
            next_send_tick = tick + 1000000000LL * sending_length / bandwidth;
        }
    }

    for(int i = 0; i < wordNumber; ++i) rte_free(pkt[i]);
}