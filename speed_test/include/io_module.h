#ifndef __OMNISTACK_IO_MODULES_H
#define __OMNISTACK_IO_MODULES_H

#include <stdint.h>
#include <stdlib.h>
#include "packet_data.h"

#define NAMED_IO(name,suffix) io_module_##name##_##suffix
#define IO_MODULE(name) IO_MOD_##name

// src dst
typedef struct io_module_func {
	int (*load_module)(void);
	void* (*init_handle_up)(uint16_t nif, uint32_t stack_id);
	void* (*init_handle_down)(uint16_t nif);
	int (*start_iface)(uint16_t nif);

	void* (*get_wptr)(void *ctx, packet_data_t* pkt, uint16_t len);
	int (*send_pkts)(void *ctx);

	void (*get_rptr)(void *ctx, packet_data_t* pkt, uint16_t index);
	int (*recv_pkts)(void *ctx);

	void (*destroy_handle_up)(void *ctx);
	void (*destroy_handle_down)(void *ctx);

	int (*dev_ioctl)(void *ctx, int nif, int cmd, void *argp);

	char name[128];
} io_module_func_t;

#endif