#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
typedef unsigned int uint32_t;

typedef unsigned short uint16_t;
typedef unsigned char uint8_t;
#define min(a,b) ((a)<(b)?(a):(b))
#define M 2048


#define TOPBIT   (((uint32_t)1) << 31)

static uint32_t reflect(uint32_t VF_dato, uint8_t VF_nBits) {
    uint32_t VP_reflection = 0;

    for (uint8_t VP_Pos_bit = 0; VP_Pos_bit < VF_nBits; VP_Pos_bit++) {
        if ((VF_dato & 1) == 1) {
            VP_reflection |= (((uint32_t)1) << ((VF_nBits - 1) - VP_Pos_bit));
        }
        VF_dato = (VF_dato >> 1);
    }
    return (VP_reflection);
}

#define reflect_DATA(_DATO)                      ((uint8_t)(reflect((_DATO), 8)&0xFF))
#define reflect_CRCTableValue(_CRCTableValue)	((uint32_t) reflect((_CRCTableValue), 32))

static uint32_t crc_ObtenValorDeTabla_Reversed(uint8_t VP_Pos_Tabla, uint32_t polynomial) {
    uint32_t VP_CRCTableValue = 0;

    VP_CRCTableValue = ((uint32_t) reflect_DATA(VP_Pos_Tabla)) << 24;

    for (uint8_t VP_Pos_bit = 0; VP_Pos_bit < 8; VP_Pos_bit++) {
        if (VP_CRCTableValue & TOPBIT) {
            VP_CRCTableValue = (VP_CRCTableValue << 1) ^ polynomial;
        } else {
            VP_CRCTableValue = (VP_CRCTableValue << 1);
        }
    }
    return (reflect_CRCTableValue(VP_CRCTableValue));
}

uint32_t crc_body_reversed_true(uint8_t* data, uint16_t len, uint32_t code, uint32_t init, uint32_t final_xor) {
    for (int16_t VP_bytes = 0; VP_bytes < len; VP_bytes++) {
        init = (init >> 8) ^ crc_ObtenValorDeTabla_Reversed(((uint8_t)(init & 0xFF)) ^ data[VP_bytes], code);
    }

    return (init ^ final_xor);
}

uint32_t crc32(uint8_t* data, uint16_t len) {
    return crc_body_reversed_true(data, len, 0x04C11DB7, 0xFFFFFFFF, 0xFFFFFFFF);
}

uint32_t crc_32c(uint8_t* data, uint16_t len) {
    return crc_body_reversed_true(data, len, 0x1EDC6F41, 0xFFFFFFFF, 0xFFFFFFFF);
}

uint32_t crc_32d(uint8_t* data, uint16_t len) {
    return crc_body_reversed_true(data, len, 0xA833982B, 0xFFFFFFFF, 0xFFFFFFFF);
}




int arr[3][M];

int main() {
    freopen("a.txt", "r", stdin);
    freopen("result.txt","w",stdout);


    char s[100]; // max length: 10
    while (scanf("%s", s+1) == 1) {
        int len = strlen(s+1);
        if (len==3) break;
        if (len > 8) continue;

        ++arr[0][crc32((uint8_t *)(s + 1), len) & (M-1)];
        ++arr[1][crc_32c((uint8_t *)(s + 1), len) & (M-1)];
        ++arr[2][crc_32d((uint8_t *)(s + 1), len) & (M-1)];
    }


    int num;
    int round = 0;
    while (scanf("%s%d", s+1, &num) == 2) {
        int len = strlen(s+1);

        int a = arr[0][crc32((uint8_t*)(s + 1), len) & (M-1)];
        int b = arr[1][crc_32c((uint8_t*)(s + 1), len) & (M-1)];
        int c = arr[2][crc_32d((uint8_t*)(s + 1), len) & (M-1)];
        int t = min(c, min(a, b));
        if(num != t)
        printf("%d %d %d %d %d %d\n", round, t, num, crc32((uint8_t*)(s + 1), len) & (M-1), crc_32c((uint8_t*)(s + 1), len) & (M-1), crc_32d((uint8_t*)(s + 1), len) & (M-1));
        round ++;
    }

}