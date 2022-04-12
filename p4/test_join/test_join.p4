#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#include "headers.p4"
#include "util.p4"


typedef bit<16> hash_type;


struct metadata_t {
    hash_type hash1;
    bit<32> hash2;

    bit<32> InPlace;
    bit<3> num;

    bit<32> tmpData;
}

#include "parser.p4"




/*
16位地址, 返回32位register.
后续可以拼一下hash value, 达到29位, 加上数组可得到45位的hash value -> reduce collision.
*------------------*----------------------*------------------*
*   invalid bits   *   aggregate number   *   hash_2 value   *
*------------------*----------------------*------------------*
*      13 bits     *         3 bits       *      16 bits     *
*------------------*----------------------*------------------*
*/
control OccupyPlace(
        inout header_t hdr,
		inout metadata_t ig_md) {

    Register<bit<32>, hash_type>(32w65536, 0) cs_table; // initial value is 0.

    // in register action you can't do complex operation such as crc32.get().
    RegisterAction<bit<32>, hash_type, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {

            if ((bit<19>)register_data < 19w65536) // 在16,17,18位为: 000, 则覆盖. 目前只能做16位hash.
                register_data = ig_md.hash2 + 32w65536; // num = 1, 改成 | 就不行?
            else if ((hash_type)register_data == (hash_type)ig_md.hash2) // 用类型转换而不是&运算.
                register_data = register_data + 32w65536; // num = num + 1.
            
            result = register_data;
        }
    };

    apply {
        ig_md.InPlace = cs_action.execute(ig_md.hash1);
    }
}

control StorageArray(
        in val_word_h hdrValue,
        inout val_word_h modifyValue,
		inout metadata_t ig_md)(bit<3> num) {
    
    Register<bit<32>, hash_type>(32w65536, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, hash_type, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {

            if (ig_md.num == num) // 若要修改, 则将该pkt的value存储; 否则直接读出value.
                register_data = hdrValue.data;
            
            result = register_data;
        }
    };

    apply {
        modifyValue.data = cs_action.execute(ig_md.hash1);
        if (ig_md.num == 3w0) // we really need the value.
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
    Hash<hash_type>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<hash_type>(HashAlgorithm_t.CRC32, poly2) hash2;

    OccupyPlace() arrayID;
    StorageArray(3w1) array1;
    StorageArray(3w2) array2;
    StorageArray(3w3) array3;
    StorageArray(3w4) array4;
    StorageArray(3w5) array5;
    StorageArray(3w6) array6;
    StorageArray(3w7) array7; // 每个array有一个id!

    apply {
        // 首先得到两个hash value.
        ig_md.hash1 = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
        ig_md.hash2 = (bit<32>)hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
        // improvement: cancat 2-16bit hash value -> 29bit hash value.

        arrayID.apply(hdr, ig_md);

        if ((hash_type)ig_md.InPlace == (hash_type)ig_md.hash2) { // hit, 进行操作.
            ig_md.num = (bit<3>)(ig_md.InPlace >> 16); // get the stage number.

            // 把信息都带出来.
            // 为什么assign value写在外面编译错误? 提示PHV invalid.
            array1.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_2, ig_md); // query the array.
            array2.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_3, ig_md);
            array3.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_4, ig_md);
            array4.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_5, ig_md);
            array5.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_6, ig_md);
            array6.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_7, ig_md);
            array7.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_8, ig_md);

            if (ig_md.num != 3w0) // we stored the value, just drop the pkt.
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

        func_1.apply(hdr, ig_md, ig_dprsr_md);

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