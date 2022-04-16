#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"


// bit<32>访问65536是否存在不确定性?
struct metadata_t {
    bit<16> hash1; // index hash.
    bit<32> hash2; // Finger-Print hash.

    bit<32> InPlace; // compare if-in hash.
    bit<8> num; // if-in: stage number.

    bit<32> tmpData; // store temporary data.
}

#include "parser.p4"






struct pair {
    bit<32>     first;  // highest 3 bits store stage number.
    bit<32>     second; // store finger-print.
}

control OccupyPlace(
        inout header_t hdr,
		inout metadata_t ig_md) {

    Register<pair, bit<16>>(size = 32w65536, initial_value = {0, 0}) cs_table; // initial value is 0.

    RegisterAction<pair, bit<16>, bit<32>>(cs_table) cs_action = {
        void apply(inout pair val, out bit<32> result) {

            if (val.first == 0) {
                val.first = 32w536870912;
                val.second = ig_md.hash2;
            }
            else if (val.second == ig_md.hash2) {
                val.first = val.first + 32w536870912; // num = num + 1.
            }

            result = val.second;
        }
    };

    apply {
        ig_md.InPlace = cs_action.execute(ig_md.hash1);
    }
}

// only 32-bits to metadata: another counting array.
control CountStage(
        inout header_t hdr,
		inout metadata_t ig_md) {
    
    Register<bit<8>, bit<16>>(32w65536, 0) cs_table; // initial value is 0.

    RegisterAction<bit<8>, bit<16>, bit<8>>(cs_table) cs_action = {
        void apply(inout bit<8> register_data, out bit<8> result) {
            
            if (register_data == 8w7)
                register_data = 8w0;
            else 
                register_data = register_data + 8w1;

            result = register_data;
        }
    };

    apply {
        ig_md.num = cs_action.execute(ig_md.hash1); // mod 8.
    }
}

control StorageArray(
        in val_word_h hdrValue,
        inout val_word_h modifyValue,
		inout metadata_t ig_md)(bit<8> num) {
    
    Register<bit<32>, bit<16>>(32w65536, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<16>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {

            if (ig_md.num == num) // 若要修改, 则将该pkt的value存储; 否则直接读出value.
                register_data = hdrValue.data;
            
            result = register_data;
        }
    };

    apply {
        modifyValue.data = cs_action.execute(ig_md.hash1);
        if (ig_md.num == 8w0) // we really need the value.
            modifyValue.setValid();
    }
}

// 整一个长度为8的.
control JoinOperator(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    
    CRCPolynomial<bit<32>>(32w0x30243f0b, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly1;
    CRCPolynomial<bit<32>>(32w0x0f79f523, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly2;
    Hash<bit<16>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, poly2) hash2;

    OccupyPlace() arrayID;
    CountStage() arrayStage;
    StorageArray(8w1) array1;
    StorageArray(8w2) array2;
    StorageArray(8w3) array3;
    StorageArray(8w4) array4;
    StorageArray(8w5) array5;
    StorageArray(8w6) array6;
    StorageArray(8w7) array7; // 每个array有一个id!


    action apply_hash1() {
        ig_md.hash1 = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    action apply_hash2() {
        ig_md.hash2 = hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    
    table tbl_hash1 {
        actions = {
            apply_hash1;
        }
        const default_action = apply_hash1();
        size = 512;
    }

    table tbl_hash2 {
        actions = {
            apply_hash2;
        }
        const default_action = apply_hash2();
        size = 512;
    }

    apply {
        tbl_hash1.apply();
        tbl_hash2.apply();

        arrayID.apply(hdr, ig_md);

        if (ig_md.InPlace == ig_md.hash2) { // hit, operate.
            arrayStage.apply(hdr, ig_md);// get the stage number.

            // bring out the info.
            array1.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_2, ig_md); // query the array.
            array2.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_3, ig_md);
            array3.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_4, ig_md);
            array4.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_5, ig_md);
            array5.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_6, ig_md);
            array6.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_7, ig_md);
            array7.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_8, ig_md);

            if (ig_md.num != 8w0) // we stored the value, just drop the pkt.
               ig_dprsr_md.drop_ctl = 1;
        }
    }
}




control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
    }
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    table ipv4_lpm {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 512;
        default_action = NoAction;
    }

    JoinOperator() func_1;

    apply {
        // there is some disturbing pkts!!!
        if (hdr.udp.isValid()) func_1.apply(hdr, ig_md, ig_dprsr_md);

        ipv4_lpm.apply();
        
    }
}


/********  G L O B A L   E G R E S S   M E T A D A T A  *********/

parser EgressParser(packet_in        pkt,
    /* User */
    out empty_header_t          hdr,
    out empty_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    /* This is a mandatory state, required by Tofino Architecture */
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

control EgressDeparser(packet_out pkt,
    /* User */
    inout empty_header_t                       hdr,
    in    empty_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

Pipeline(
    SwitchIngressParser(),
    SwitchIngress(),
    SwitchIngressDeparser(),
    EgressParser(),
    EmptyEgress(),
    EgressDeparser()
) pipe;

Switch(pipe) main;