

#define _GNU_SOURCE 1
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <numa.h>
#include <sched.h>
#include <pthread.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <assert.h>
#include <stdint.h>
#include <arpa/inet.h>
#include <sys/time.h>

#include "protocol_headers.h"
#include "packet_data.h"
#include "io_module.h"

#include <rte_ethdev.h>
#include <rte_mempool.h>
#include <rte_mbuf.h>
#include <rte_malloc.h>
#include <rte_memcpy.h>

/* Constants */
#define MAX_PKT_BURST 256
#define MAX_DEVICES 32

#define CORE_MAX_BUF_SIZE 1536
#define MCORE_MAX_BUF_SIZE (CORE_MAX_BUF_SIZE + sizeof(struct rte_mbuf) + RTE_PKTMBUF_HEADROOM)
#define MEMPOOL_CACHE_SIZE 256
#define NB_MBUF 16384

#define RTE_TEST_RX_DESC_DEFAULT 1024
#define RTE_TEST_TX_DESC_DEFAULT 1024
/* default port_conf */


// wzz: packet length.
#define MaxPacket 1000
#define wordLength 100
#define largePrime 23333


const int num_devices_attached = 1;
const int devices_attached[32] = {0};  // ethtool -i enp129s0f1 查询pcie的bus端口号.
uint8_t devices_hwaddr[32][6];

static uint8_t rss_key[] = {
    0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, /* 10 */
    0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, /* 20 */
    0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, /* 30 */
    0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A, 0x6D, 0x5A /* 40 */
};

const struct rte_eth_conf port_conf_default = {
    .rxmode = {
        .mq_mode = ETH_MQ_RX_RSS,
        .split_hdr_size = 0,
        .max_rx_pkt_len = 1514,
        .offloads = 0
    },
    .rx_adv_conf = {
		.rss_conf = {
            .rss_key = rss_key,
            .rss_key_len = sizeof(rss_key),
            .rss_hf = 
                ETH_RSS_FRAG_IPV4           |
                ETH_RSS_NONFRAG_IPV4_UDP    |
                ETH_RSS_NONFRAG_IPV4_TCP    |
                ETH_RSS_TCP
		}
	},
    .txmode = {
        .mq_mode = ETH_MQ_TX_NONE,
        .offloads =
            DEV_TX_OFFLOAD_VLAN_INSERT |
            DEV_TX_OFFLOAD_IPV4_CKSUM  |
            DEV_TX_OFFLOAD_UDP_CKSUM   |
            DEV_TX_OFFLOAD_TCP_CKSUM   |
            DEV_TX_OFFLOAD_SCTP_CKSUM  |
            DEV_TX_OFFLOAD_TCP_TSO,
    }};

/* Structures */
struct mbuf_table
{
    uint16_t len; /* length of queued packets */
    struct rte_mbuf *m_table[MAX_PKT_BURST];
};

typedef struct
{
    struct mbuf_table wmbufs;
    struct rte_mempool *pktmbuf_pool;
    uint16_t txq_id;
    uint16_t portid;
} __rte_cache_aligned dpdk_context_up;

typedef struct
{
    struct mbuf_table rmbuf;
    struct rte_mempool *pktmbuf_pool;
    struct rte_mbuf *pkts_burst[MAX_PKT_BURST];
    uint16_t portid;
    uint16_t rxq_id;
} __rte_cache_aligned dpdk_context_down;

static struct {
    pthread_mutex_t mutex;
    uint32_t idx_txq[MAX_DEVICES];
    uint32_t idx_rxq[MAX_DEVICES];
    uint32_t num_rxq[MAX_DEVICES];
    uint32_t global_initialized[MAX_DEVICES];
    uint16_t nb_rxd[MAX_DEVICES];
    uint16_t nb_txd[MAX_DEVICES];
    struct rte_eth_conf port_conf[MAX_DEVICES];
    struct rte_eth_dev_info dev_info[MAX_DEVICES];

    uint32_t init_thread[MAX_DEVICES];
} dpdk_info;

int dpdk_load_module(void) {
    int i, portid, ret;
    for (i = 0; i < num_devices_attached; i++) {
        portid = devices_attached[i];
        dpdk_info.num_rxq[portid] ++;
        struct rte_ether_addr mac_addr;
        rte_eth_macaddr_get(portid, &mac_addr);
        rte_memcpy(devices_hwaddr[i], mac_addr.addr_bytes, sizeof(devices_hwaddr[i]));
        printf("hwaddr = %x:%x:%x:%x:%x:%x\n", devices_hwaddr[i][0], devices_hwaddr[i][1], devices_hwaddr[i][2], devices_hwaddr[i][3], devices_hwaddr[i][4], devices_hwaddr[i][5]);
    }
    for (i = 0; i < num_devices_attached; i++) {
        portid = devices_attached[i];
        if (dpdk_info.global_initialized[portid])
            continue;
        // LOG_INFO("[IO_DPDK] Initializing device %d with %u rx queues %u tx queues\n", portid, dpdk_info.num_rxq[portid], CONFIG.num_stack);
        dpdk_info.global_initialized[portid] = 1;
        ret = rte_eth_dev_info_get(portid, &dpdk_info.dev_info[portid]);
        if (ret != 0)
            rte_exit(EXIT_FAILURE,
                "Error during getting device (port %u) info: %s\n",
                portid, strerror(-ret));
        
        // LOG_INFO("[IO_DPDK] NB LIMIT: RX:%hu TX:%hu\n", dpdk_info.dev_info[portid].rx_desc_lim.nb_max, dpdk_info.dev_info[portid].tx_desc_lim.nb_max);
        //LOG_FAST_DEBUG(IO_DPDK, "NBSIZE LIMIT: RX:%hu TX:%hu\n", dpdk_info.dev_info[portid].rx_desc_lim.nb_mtu_seg_max, dpdk_info.dev_info[portid].tx_desc_lim.nb_seg_max);
        // LOG_INFO("[IO_DPDK] NB Q LIMIT: RX queue:%hu TX queue:%hu\n", dpdk_info.dev_info[portid].max_rx_queues, dpdk_info.dev_info[portid].max_tx_queues);
        
        // LOG_INFO("[IO_DPDK] port tx offloading capability = %lx\n", dpdk_info.dev_info[portid].tx_offload_capa);
        dpdk_info.port_conf[portid] = port_conf_default;
        // dpdk_info.port_conf[portid].rxmode.offloads = 0;
        dpdk_info.port_conf[portid].txmode.offloads &= dpdk_info.dev_info[portid].tx_offload_capa;
        // rte_eth_dev_set_ptypes(portid, RTE_PTYPE_UNKNOWN, NULL, 0);

        dpdk_info.nb_rxd[portid] = RTE_TEST_RX_DESC_DEFAULT;
        dpdk_info.nb_txd[portid] = RTE_TEST_TX_DESC_DEFAULT;
        // dpdk_info.nb_txd[portid] = RTE_TEST_TX_DESC_DEFAULT;
        rte_eth_dev_adjust_nb_rx_tx_desc(portid, &dpdk_info.nb_rxd[portid], &dpdk_info.nb_txd[portid]);
        dpdk_info.port_conf[portid].rx_adv_conf.rss_conf.rss_hf &= dpdk_info.dev_info[portid].flow_type_rss_offloads;
        ret = rte_eth_dev_configure(portid, dpdk_info.num_rxq[portid], 1, &dpdk_info.port_conf[portid]);
        if (ret < 0) {
            // LOG_ERR("[IO_DPDK]\tFailed to configure dev\n");
        }
    }
    pthread_mutex_init(&(dpdk_info.mutex), NULL);
    return 0;
}

int dpdk_start_iface(uint16_t nif) {
    // LOG_INFO("[DPDK]Iface %hu started.\n", nif);

    int ret, portid = nif;
    ret = rte_eth_promiscuous_enable(portid);
    if (ret != 0) {
        // LOG_WARN("Failed to enable promiscuous mode.\n");
    }

    struct rte_eth_fc_conf fc_conf;
    memset(&fc_conf, 0, sizeof(fc_conf));
    ret = rte_eth_dev_flow_ctrl_get(portid, &fc_conf);
    // if (ret != 0)
    //     LOG_INFO("Failed to get flow control info!\n");
    // else {
    //     LOG_INFO("[IO_DPDK] Dev flow ctrl: mode = %d\n", fc_conf.mode);
    // }

    /* and just disable the rx/tx flow control */
    // fc_conf.mode = RTE_FC_NONE;
    // ret = rte_eth_dev_flow_ctrl_set(portid, &fc_conf);
    // if (ret != 0)
    //     LOG_INFO("Failed to set flow control info!: errno: %d\n", ret);

    ret = rte_eth_dev_start(portid);
    if (ret < 0)
        rte_exit(EXIT_FAILURE, "rte_eth_dev_start:err=%d, port=%u\n",
                    ret, (unsigned)portid);
    
    printf("[IO_DPDK]Interface %hu started.\n", nif);

    // LOG_INFO("[IO_DPDK] Checking status %hu\n", nif);

    struct rte_eth_link link;
    ret = rte_eth_link_get_nowait(portid, &link);
    if (ret < 0) {
        // LOG_WARN(IO_DPDK, "Port %u link get failed: %s\n", portid, rte_strerror(-ret));
        return 0;
    }

    // char link_status_text[128];
    // rte_eth_link_to_str(link_status_text, sizeof(link_status_text), &link);
	// LOG_INFO("[IO_DPDK] Port %d %s\n", portid, link_status_text);
    
    return 0;
}

/* handle_up is for tx only */
void* dpdk_init_handle_up(uint16_t nif, uint32_t stack_id) {
    // LOG_DEBUG("[IO_DPDK]Dpdk initializing handle.\n");
    int j, portid = nif, ret;
    char name[RTE_MEMPOOL_NAMESIZE];
    dpdk_context_up *dpc = calloc(1, sizeof(dpdk_context_up));
    sprintf(name, "mbuf_pool_up-%d", rte_lcore_id());
    dpc->pktmbuf_pool = rte_mempool_create(
        name, NB_MBUF, MCORE_MAX_BUF_SIZE, MEMPOOL_CACHE_SIZE,
        sizeof(struct rte_pktmbuf_pool_private),
        rte_pktmbuf_pool_init, NULL,
        rte_pktmbuf_init, NULL,
        rte_socket_id(), 0);
    printf("INIT HANDLE UP: mempool = %p\n",dpc->pktmbuf_pool);
    pthread_mutex_lock(&dpdk_info.mutex);
    dpc->portid = portid;
    dpc->txq_id = dpdk_info.idx_txq[portid]++;

    struct rte_eth_txconf txq_conf = dpdk_info.dev_info[portid].default_txconf;
    txq_conf.offloads = 0; //dpdk_info.port_conf[portid].txmode.offloads;

    printf("Setting portid = %d\n", portid);
    ret = rte_eth_tx_queue_setup(portid, dpc->txq_id, dpdk_info.nb_txd[portid], rte_eth_dev_socket_id(portid), &txq_conf);
    pthread_mutex_unlock(&dpdk_info.mutex);

    if (ret < 0)
        rte_exit(EXIT_FAILURE, "tx_queue_setup");

    for (j = 0; j < MAX_PKT_BURST; j++)
    {
        dpc->wmbufs.m_table[j] = rte_pktmbuf_alloc(dpc->pktmbuf_pool);
        if (dpc->wmbufs.m_table[j] == NULL) {
            rte_exit(EXIT_FAILURE, "Failed to allocate %d:wmbuf[%d] on device %d!\n", rte_lcore_id(), j, nif);
        }
    }
    dpc->wmbufs.len = 0;
    return dpc;
}

void* dpdk_init_handle_down(uint16_t nif) {
    int portid = nif, ret;
    char name[RTE_MEMPOOL_NAMESIZE];
    dpdk_context_down *dpc = calloc(1, sizeof(dpdk_context_down));
    dpc->portid = portid;

    sprintf(name, "mbuf_pool_down-%d", rte_lcore_id());
    // printf("RTE LCORE ID = %d\n", rte_lcore_id());
    dpc->pktmbuf_pool = rte_mempool_create(
        name, NB_MBUF, MCORE_MAX_BUF_SIZE, MEMPOOL_CACHE_SIZE,
        sizeof(struct rte_pktmbuf_pool_private),
        rte_pktmbuf_pool_init, NULL,
        rte_pktmbuf_init, NULL,
        rte_socket_id(), 0);
    printf("INIT HANDLE DOWN: mempool = %p\n",dpc->pktmbuf_pool);
    uint16_t rxq_id = -1;
    pthread_mutex_lock(&(dpdk_info.mutex));
    rxq_id = dpdk_info.idx_rxq[portid] ++;
    dpc->rxq_id = rxq_id;
    // LOG_INFO("[IO_DPDK] Create down handle rxq_id = %hu\n", rxq_id);
    pthread_mutex_unlock(&(dpdk_info.mutex));

    struct rte_eth_rxconf rxq_conf = dpdk_info.dev_info[portid].default_rxconf;
    rxq_conf.offloads = dpdk_info.port_conf[portid].rxmode.offloads;
    // LOG_INFO("[IO_DPDK] Init handle down port = %d, socket = %d\n", portid, rte_eth_dev_socket_id(portid));
    ret = rte_eth_rx_queue_setup(portid, rxq_id, dpdk_info.nb_rxd[portid], rte_eth_dev_socket_id(portid), &rxq_conf, dpc->pktmbuf_pool);
    if (ret < 0)
        rte_exit(EXIT_FAILURE, "rx queue setup");
    return dpc;
}

void* dpdk_get_wptr(void* ctx, packet_data_t* pkt, uint16_t len) {
    dpdk_context_up *dpc = (dpdk_context_up *)ctx;
    struct rte_mbuf *m;
    char* ptr;
    int len_of_mbuf;    

    if (dpc->wmbufs.len == MAX_PKT_BURST)
        return NULL;

    len_of_mbuf = dpc->wmbufs.len;
    m = dpc->wmbufs.m_table[len_of_mbuf];

    ptr = (void *)rte_pktmbuf_mtod(m, struct ether_hdr *);
    m->pkt_len = m->data_len = len;
    m->nb_segs = 1;
    m->next = NULL;

    m->ol_flags = 0;
    m->l2_len = sizeof(ethernet_header_t);
    ethernet_header_t* ethh = (ethernet_header_t*)(pkt->header_tail - 1)->data;

    switch (ethh->type) {
        case ETH_PROTO_TYPE_IPV4: {
            ipv4_header_t* ipv4h = (ipv4_header_t*)(pkt->header_tail - 2)->data;
            m->ol_flags = PKT_TX_IP_CKSUM | PKT_TX_IPV4;
            m->l3_len = sizeof(ipv4_header_t);
            ipv4h->chksum = 0;
            switch (ipv4h->proto) {
                case IP_PROTO_TYPE_TCP: {
                    m->ol_flags |= PKT_TX_TCP_CKSUM;
                    tcp_header_t* tcph = (tcp_header_t*)(pkt->header_tail - 3)->data;
                    tcph->chksum = rte_ipv4_phdr_cksum((const struct rte_ipv4_hdr*)ipv4h, m->ol_flags);
                }
                    break;
                case IP_PROTO_TYPE_UDP: {
                    m->ol_flags |= PKT_TX_UDP_CKSUM;
                    udp_header_t* udph = (udp_header_t*)(pkt->header_tail - 3)->data;
                    udph->chksum = rte_ipv4_phdr_cksum((const struct rte_ipv4_hdr*)ipv4h, m->ol_flags);
                }
                    break;
            }
        }
            break;
        case ETH_PROTO_TYPE_IPV6: {
            m->ol_flags = PKT_TX_IP_CKSUM | PKT_TX_IPV6;
        }
            break;
    }

    dpc->wmbufs.len = len_of_mbuf + 1;
    return (uint8_t *)ptr;
}

int dpdk_send_pkts(void *ctx) {
    dpdk_context_up *dpc = (dpdk_context_up *)ctx;
    int ret = 0, i, portid = dpc->portid;

    if (dpc->wmbufs.len > 0) {
        // printf("[DPDK]Sending packets.\n");

        ret = dpc->wmbufs.len;
        struct rte_mbuf **pkts;
        int cnt = dpc->wmbufs.len;
        pkts = dpc->wmbufs.m_table;
        do {
            ret = rte_eth_tx_burst(portid, dpc->txq_id, pkts, cnt);
            pkts += ret;
            cnt -= ret;
        } while (cnt > 0);

        for (i = 0; i < dpc->wmbufs.len; i++) {
            dpc->wmbufs.m_table[i] = rte_pktmbuf_alloc(dpc->pktmbuf_pool);
            if (dpc->wmbufs.m_table[i] == NULL) {
                rte_exit(EXIT_FAILURE, "Failed to allocate %d:wmbuf[%d] on device %d!\n",
                         rte_lcore_id(), i, portid);
            }
        }
        dpc->wmbufs.len = 0;
    }
    return ret;
}

static inline void
free_pkts(struct rte_mbuf **mtable, unsigned len)
{
    int i;
    /* free the freaking packets */
    for (i = 0; i < len; i++)
    {
        rte_pktmbuf_free(mtable[i]);
        RTE_MBUF_PREFETCH_TO_FREE(mtable[i + 1]);
    }
}

void dpdk_get_rptr(void *ctx, packet_data_t* pkt, uint16_t index) {
    dpdk_context_down *dpc = (dpdk_context_down *)ctx;
    struct rte_mbuf *m;

    m = dpc->pkts_burst[index];

    pkt->data = rte_pktmbuf_mtod(m, uint8_t *);
}

int dpdk_recv_pkts(void *ctx) {
    dpdk_context_down *dpc = (dpdk_context_down *)ctx;
    int ret, portid = dpc->portid;
    // printf("%d %d %d\n", portid, dpc->rxq_id, dpc->pkts_burst);
    ret = rte_eth_rx_burst((uint16_t)portid, dpc->rxq_id, dpc->pkts_burst, MAX_PKT_BURST);
    return ret;
}

void dpdk_destroy_handle_up(void *ctx) {
    dpdk_context_up *dpc = (dpdk_context_up *)ctx;
    free_pkts(dpc->wmbufs.m_table, dpc->wmbufs.len);
    free(dpc);
}
void dpdk_destroy_handle_down(void *ctx) {
    dpdk_context_down *dpc = (dpdk_context_down *)ctx;
    free(dpc);
}

int dpdk_dev_ioctl(void *ctx, int nif, int cmd, void *argp) {
    /* TODO: wirte io ctl to use hardware resources */
    return 0;
}

io_module_func_t dpdk_module_func = {
    .name = "IO_MODULE(DPDK)",
    .load_module = dpdk_load_module,
    .init_handle_up = dpdk_init_handle_up,
    .init_handle_down = dpdk_init_handle_down,
    .start_iface = dpdk_start_iface,

    .get_wptr = dpdk_get_wptr,
    .send_pkts = dpdk_send_pkts,

    .get_rptr = dpdk_get_rptr,
    .recv_pkts = dpdk_recv_pkts,

    .destroy_handle_up = dpdk_destroy_handle_up,
    .destroy_handle_down = dpdk_destroy_handle_down,

    .dev_ioctl = dpdk_dev_ioctl
};

uint32_t s2ipv4(const char* val) {
    uint32_t a, b, c, d;
    sscanf(val, "%u.%u.%u.%u", &a, &b, &c, &d);
    return a | (b << 8) | (c << 16) | (d << 24);
}
void s2macaddr(char* dst, const char* val) {
    uint32_t a[6];
    sscanf(val, "%x:%x:%x:%x:%x:%x", &a[0], &a[1], &a[2], &a[3], &a[4], &a[5]);
    for(int i=0;i<6;i++)
        dst[i] = a[i];
}

int cqs_core_affinitize_dpdk(int cpu){
    cpu_set_t cpus;

    CPU_ZERO(&cpus);
    CPU_SET((unsigned)cpu,&cpus);
    return rte_thread_set_affinity(&cpus);
}

void dpdk_init(char *cpumask, uint32_t main_core) {
    #define argc 7
    char argv[argc][1024] = {"./main", "-c", "", "--main-lcore", "", "--log-level", "1000"};//, "--legacy-mem", "--socket-mem", "8192,8192"};
    sprintf(argv[2], cpumask);
    sprintf(argv[4], "%d", main_core);

    char **argv_p = calloc(argc, sizeof(char*));
    for (int i=0;i<argc;i++) {
        argv_p[i] = calloc(strlen(argv[i]) + 1, sizeof(char));
        strcpy(argv_p[i], argv[i]);
    }
    rte_eal_init(argc, argv_p);
    #undef argc
    printf("DPDK Initialized.\n");

}




uint32_t src_ip, dst_ip;
uint16_t src_port, dst_port;
uint8_t dst_mac[6];

packet_data_t* generate_packet(uint32_t payload_length, char *buf) {
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
    // memcpy(pkt->data + sizeof(ethernet_header_t) + sizeof(ipv4_header_t) + sizeof(udp_header_t), buf, payload_length)

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



typedef struct kvPair{
    int QID;
    u_int32_t key;
    int value;
}kvPair;

typedef struct hashTable {
    u_int32_t keys[largePrime];
    int values[largePrime];

    int* (*query) (u_int32_t* keys, int *values, u_int32_t key);
}hashTable;

int *hashQueryPosition(u_int32_t* keys, int *values, u_int32_t key) {
    int i = key%largePrime;
    for(; keys[i] && keys[i] != key; ++i) if (i + 1 == largePrime) i = -1;
    keys[i] = key;
    return values + i;
}

u_int32_t hash(char *buf, u_int32_t len) {
    u_int32_t ans = 0;
    for(u_int32_t i = 0; i < len; ++i) ans = ans * 1000000007 + buf[i];
    return ans;
}
// how to use?
// hashTable a;
// a.query = hashQueryPosition;
// uint32_t key = hash(s, strlen(s));
// a.query(a.keys, a.values, key)


// deparse the packet.
void packetFormat(kvPair *p, char *buf) {
    int QID = *((unsigned short *) buf);
    int len = *((unsigned short *) buf + 1);
    int key_len = *((unsigned short *) buf + 2);
    int val_len = *((unsigned short *) buf + 3);
    u_int32_t key = hash(buf + 8, key_len);
    int value = *((unsigned int *) (buf + 8 + key_len));

    // printf("QID: %d, key_len: %d, val_len: %d\n", QID, key_len, val_len);
    // printf("key: ");
    // for(int i = 0; i < key_len; ++i) putchar(*(buf + 8 + i));
    // printf(", value: %d\n\n\n", value);

    p -> QID = QID;
    p -> key = key;
    p -> value = value;

    return;
}


void WordCount(kvPair *p) {
    // printf("QID: %d, key:%d, value:%d\n\n", p->QID, p->key, p->value);
}


// test the max speed, the switch is able to handle, so best effort.
void receiver(int *signal) {

    dpdk_init("11111", 0);

    cqs_core_affinitize_dpdk(0);

    dpdk_module_func.load_module();

    void* up_handle = dpdk_module_func.init_handle_up(devices_attached[0], 0);
    void* down_handle = dpdk_module_func.init_handle_down(devices_attached[0]);

    for(int i = 0; i < num_devices_attached; i ++) dpdk_module_func.start_iface(devices_attached[i]);

    printf("initialized\n");

    // in the parameter.
    // 先整个固定的, 跑通了改一下参数传递.
    src_ip = s2ipv4("10.1.100.1");
    dst_ip = s2ipv4("10.1.100.2");
    src_port = 1111;
    dst_port = 2222;
    s2macaddr((char*)dst_mac, "3c:fd:fe:bb:ca:81");

    int payload_length = 0;
    char *buf[1000+5];

    kvPair p;
    packet_data_t* data = generate_packet(payload_length, buf);

    int total = 0;
    *signal = 1;
    printf("In receiver UDP: I'm ready!\n");
    while(1) { // sniffer the port.
        int recv_num = dpdk_module_func.recv_pkts(down_handle);
        total += recv_num;
        if (recv_num) printf("In round: %d\n", total);
        for(int i = 0; i < recv_num; i ++) {
            dpdk_module_func.get_rptr(down_handle, data, i);
            ipv4_header_t* data_ipv4 = data->data + sizeof(ethernet_header_t);
            udp_header_t* data_udp = data->data + sizeof(ethernet_header_t) + sizeof(ipv4_header_t);
            // drop the packet that is not in UDP. 
            if (data_ipv4 -> proto != 17) continue;

            // 在payload里面需要解析出(key, value), 然后写自定义的stream processing处理程序.
            packetFormat(&p, data->data + sizeof(ethernet_header_t) + sizeof(ipv4_header_t) + sizeof(udp_header_t));
            WordCount(&p);

            unsigned char* ptr = data->data - RTE_PKTMBUF_HEADROOM - sizeof(struct rte_mbuf);
            rte_pktmbuf_free((struct rte_mbuf*)ptr);
        }
    }

    // 对于wordCount来说, 用hash_table来做.
    // 先不考虑清空的情况.
    // 可预见的结果是快了至少k倍, 因为包的数量减少了k倍.

    return;
}