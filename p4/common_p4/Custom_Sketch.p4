#ifndef _CUSTOM_SKETCH_
#define _CUSTOM_SKETCH_


control CSum_UPDATE_KEY1(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_1.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_1.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}



control CSum_UPDATE_KEY2(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_2.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_2.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY3(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_3.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_3.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY4(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_4.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_4.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY5(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_5.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_5.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY6(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_6.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_6.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY7(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_7.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_7.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


control CSum_UPDATE_KEY8(
  inout header_t hdr,
  inout bit<1> flag, 
  out bit<32> est)(bit<32> polynomial)
{

    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly1;
    CRCPolynomial<bit<32>>(polynomial, true,  false, false, 32w0xFFFFFFFF,  32w0xFFFFFFFF ) poly2;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<10>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Register<bit<32>, bit<10>>(32w1024) cs_table1;
    Register<bit<32>, bit<10>>(32w1024) cs_table2;
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table1) cs_action1 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_8.data;
            result = register_data;
        }
    };
    RegisterAction<bit<32>, bit<10>, bit<32>>(cs_table2) cs_action2 = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + hdr.kvs.val_word.val_word_8.data;
            result = register_data;
        }
    };
    apply {
        @atomic{
            if(flag == 1){
                est = cs_action1.execute(hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }else{
                est = cs_action2.execute(hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data}));
            }
        }
    }
}


#endif

