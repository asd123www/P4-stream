#ifndef __HASH_H__
#define __HASH_H__

#include <stdint.h>
#include <stdlib.h>

uint64_t AwareHash(unsigned char* data, uint64_t n,
        uint64_t hash, uint64_t scale, uint64_t hardener);
uint64_t AwareHash_debug(unsigned char* data, uint64_t n,
        uint64_t hash, uint64_t scale, uint64_t hardener);

uint64_t GenHashSeed(int index);

int is_prime(int num);
int calc_next_prime(int num);

void mangle(const unsigned char* key, unsigned char* ret_key,
		int nbytes);

void unmangle(const unsigned char* key, unsigned char* ret_key,
		int nbytes);

uint16_t hash1(const uint8_t *buf, int len);
uint16_t hash2(const uint8_t *buf, int len);


// CRC
uint32_t crc32(uint8_t* data, uint16_t len);
uint32_t crc_32c(uint8_t* data, uint16_t len);
uint32_t crc_32d(uint8_t* data, uint16_t len);
uint32_t crc_32q(uint8_t* data, uint16_t len);
uint32_t crc_32_bzip2(uint8_t* data, uint16_t len);
uint32_t crc_32_mpeg(uint8_t* data, uint16_t len);
uint32_t posix(uint8_t* data, uint16_t len);
uint32_t jamcrc(uint8_t* data, uint16_t len);
uint32_t xfer(uint8_t* data, uint16_t len);
uint32_t select_crc(int hashid, uint8_t* data, uint16_t len);
#endif