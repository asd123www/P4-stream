#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"

struct metadata_t {
	bit<16> sampling_hash_value;
    bit<10> level;
    bit<16> base;
    bit<32> threshold;

    bit<16> key_hash_1;
    bit<16> key_hash_2;
    bit<16> key_hash_3;
    bit<16> key_hash_4;
    bit<16> key_hash_5;
    

    bit<16> index_1;
    bit<16> index_2;
    bit<16> index_3;
    bit<16> index_4;
    bit<16> index_5;

    // bit<5> res_all;
    bit<16> res_all;
    bit<1> res_1;
    bit<1> res_2;
    bit<1> res_3;
    bit<1> res_4;
    bit<1> res_5;

    bit<32> est_1;
    bit<32> est_2;
    bit<32> est_3;
    bit<32> est_4;
    bit<32> est_5;

    bit<32> est_11;
    bit<32> est_12;
    bit<32> est_13;
    bit<32> est_14;
    bit<32> est_15;

    bit<32> value1;
    bit<32> value2;
    bit<32> value3;
    bit<32> value4;
    bit<32> value5;

    bit<1> c_1;
    bit<1> c_2;
    bit<1> c_3;
    bit<1> c_4;
    bit<1> c_5;

    bit<1> above_threshold;

    bit<1> flag;
}

#include "parser.p4"

//#include "API_common.p4"
//#include "API_O1_hash.p4"
//#include "API_O2_hash.p4"
//#include "API_O3_tcam.p4"
//#include "API_O5_salu.p4"
//#include "API_O6_flowkey.p4"
#include "API_threshold.p4"

#include "Custom_Sketch.p4"



