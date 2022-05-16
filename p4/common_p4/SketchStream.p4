// -----------------------------------Get_Hash------------------------------------
control Query_Hash(
        inout header_t hdr,
		inout metadata_t ig_md) {

    CRCPolynomial<bit<32>>(32w0x6b8cb0c5, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly0;
    CRCPolynomial<bit<32>>(32w0x30243f0b, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly1;
    CRCPolynomial<bit<32>>(32w0x0f79f523, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly2;
    CRCPolynomial<bit<32>>(32w0x00390fc3, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly3;
    CRCPolynomial<bit<32>>(32w0x298ac673, true, false, false, 32w0xFFFFFFFF, 32w0xFFFFFFFF) poly4;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly0) hash0;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly1) hash1;
    Hash<bit<HASH_WIDTH>>(HashAlgorithm_t.CRC32, poly2) hash2;
    Hash<bit<32>>(HashAlgorithm_t.CRC32, poly3) hash3;

    action apply_hash0() {
        ig_md.hash_idx1 = hash0.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    action apply_hash1() {
        ig_md.hash_idx2 = hash1.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    action apply_hash2() {
        ig_md.hash_idx3 = hash2.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }
    action apply_hash3() {
        ig_md.hash_32 = hash3.get({hdr.kvs.key_word.key_word_1.data, hdr.kvs.key_word.key_word_2.data, hdr.kvs.key_word.key_word_3.data, hdr.kvs.key_word.key_word_4.data, hdr.kvs.key_word.key_word_5.data, hdr.kvs.key_word.key_word_6.data, hdr.kvs.key_word.key_word_7.data, hdr.kvs.key_word.key_word_8.data});
    }

    table tbl_hash0 {
        actions = {
            apply_hash0;
        }
        const default_action = apply_hash0();
        size = 512;
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

    table tbl_hash3 {
        actions = {
            apply_hash3;
        }
        const default_action = apply_hash3();
        size = 512;
    }

    apply {
        tbl_hash0.apply();
        tbl_hash1.apply();
        tbl_hash2.apply();
        tbl_hash3.apply();
    }
}


// -----------------------------------Distinct------------------------------------
// In `distinct`, we must be operating on keys, so we don't have to specify source.
control BloomFilter_Distinct(
		inout header_t hdr,
		inout metadata_t ig_md,
        in bit<HASH_WIDTH> idx,
        out bit sgn)(bit<32> ARRAY_LENGTH) {

    Register<bit, bit<HASH_WIDTH>>(ARRAY_LENGTH, 0) cs_table; // initial value is 0.

    RegisterAction<bit, bit<HASH_WIDTH>, bit>(cs_table) cs_action = {
        void apply(inout bit register_data, out bit result) {
            result = register_data;
            register_data = 1;
        }
    };

    apply {
        sgn = cs_action.execute(idx);
    }
}


// 
control SketchStream_distinct(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md)(bit<32> ARRAY_LENGTH) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    BloomFilter_Distinct(ARRAY_LENGTH) A1;
    BloomFilter_Distinct(ARRAY_LENGTH) A2;
    BloomFilter_Distinct(ARRAY_LENGTH) A3;

    apply {
        A1.apply(hdr, ig_md, ig_md.hash_idx1, ig_md.sgn1);
        A2.apply(hdr, ig_md, ig_md.hash_idx2, ig_md.sgn2);
        A3.apply(hdr, ig_md, ig_md.hash_idx3, ig_md.sgn3);

        // all hit before insert.
        if ((ig_md.sgn1 == 1) || (ig_md.sgn2 == 1) || (ig_md.sgn3 == 1)) {
            drop();
        }
    }
}







// -----------------------------------GroupBy_min-------------------------------------
// 得到最小值的Sketch.
control CountMin_Array(
    inout header_t hdr,
	inout metadata_t ig_md,
    in bit<HASH_WIDTH> idx,
    in bit<32> src_field,
    out bit<32> dest_field)(bit<32> ARRAY_LENGTH) {
    
    Register<bit<32>, bit<HASH_WIDTH>> (ARRAY_LENGTH, 0x7FFFFFFF) cs_table; // initial value is INT_MAX.

    RegisterAction<bit<32>, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            if (src_field < register_data) {
                register_data = src_field;
            }
            result = register_data;
        }
    };

    apply {
        dest_field = cs_action.execute(idx);
    }
}

// 整一个长度为8的.
control SketchStream_groupby_min(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout bit<32> field) (bit<32> ARRAY_LENGTH) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    CountMin_Array(ARRAY_LENGTH) A1;
    CountMin_Array(ARRAY_LENGTH) A2;
    CountMin_Array(ARRAY_LENGTH) A3;

    apply {
        Query_Hash.apply(hdr, ig_md);

        A1.apply(hdr, ig_md, ig_md.hash_idx1, field, ig_md.result1);
        A2.apply(hdr, ig_md, ig_md.hash_idx2, field, ig_md.result2);
        A3.apply(hdr, ig_md, ig_md.hash_idx3, field, ig_md.result3);
        ig_md.diff1 = max(ig_md.result1, ig_md.result2);
        field = max(ig_md.diff1, ig_md.result3);
    }
}



// -----------------------------------GroupBy_max-------------------------------------
// 得到最大值的Sketch.
control CountMax_Array(
    inout header_t hdr,
	inout metadata_t ig_md,
    in bit<HASH_WIDTH> idx,
    in bit<32> src_field,
    out bit<32> dest_field) (bit<32> ARRAY_LENGTH) {
    
    Register<bit<32>, bit<HASH_WIDTH>> (ARRAY_LENGTH, 0) cs_table; // initial value is INT_MAX.

    RegisterAction<bit<32>, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            if (src_field > register_data) {
                register_data = src_field;
            }
            result = register_data;
        }
    };

    apply {
        dest_field = cs_action.execute(idx);
    }
}

// 整一个长度为8的.
control SketchStream_groupby_max(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout bit<32> field) (bit<32> ARRAY_LENGTH) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    CountMax_Array(ARRAY_LENGTH) A1;
    CountMax_Array(ARRAY_LENGTH) A2;
    CountMax_Array(ARRAY_LENGTH) A3;

    apply {
        Query_Hash.apply(hdr, ig_md);


        A1.apply(hdr, ig_md, ig_md.hash_idx1, field, ig_md.result1);
        A2.apply(hdr, ig_md, ig_md.hash_idx2, field, ig_md.result2);
        A3.apply(hdr, ig_md, ig_md.hash_idx3, field, ig_md.result3);

        ig_md.diff1 = min(ig_md.result1, ig_md.result2);
        field = min(ig_md.diff1, ig_md.result3);
    }
}






// -----------------------------------Join-------------------------------------
// The length is fixed to 8. Don't think it necessary to change.
struct pair {
    bit<32>     first;  // highest 3 bits store stage number.
    bit<32>     second; // store finger-print.
}

control OccupyPlace(
        inout header_t hdr,
		inout metadata_t ig_md) (bit<32> ARRAY_LENGTH) {

    Register<pair, bit<HASH_WIDTH>>(size = ARRAY_LENGTH, initial_value = {0, 0}) cs_table; // initial value is 0.

    RegisterAction<pair, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout pair val, out bit<32> result) {

            if (val.first == 0) {
                val.first = 32w536870912;
                val.second = ig_md.hash_32;
            }
            else if (val.second == ig_md.hash_32) {
                val.first = val.first + 32w536870912; // num = num + 1.
            }

            result = val.second;
        }
    };

    apply {
        ig_md.InPlace = cs_action.execute(ig_md.hash_idx1);
    }
}

// only 32-bits to metadata: another counting array.
control CountStage(
        inout header_t hdr,
		inout metadata_t ig_md) (bit<32> ARRAY_LENGTH) {
    
    Register<bit<8>, bit<HASH_WIDTH>>(ARRAY_LENGTH, 0) cs_table; // initial value is 0.

    RegisterAction<bit<8>, bit<HASH_WIDTH>, bit<8>>(cs_table) cs_action = {
        void apply(inout bit<8> register_data, out bit<8> result) {
            
            if (register_data == 8w7)
                register_data = 8w0;
            else 
                register_data = register_data + 8w1;

            result = register_data;
        }
    };

    apply {
        ig_md.num = cs_action.execute(ig_md.hash_idx1); // mod 8.
    }
}

control StorageArray(
        in val_word_h hdrValue,
        inout val_word_h modifyValue,
		inout metadata_t ig_md) (bit<8> num, bit<32> ARRAY_LENGTH) {
    
    Register<bit<32>, bit<HASH_WIDTH>>(ARRAY_LENGTH, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {

            if (ig_md.num == num) // 若要修改, 则将该pkt的value存储; 否则直接读出value.
                register_data = hdrValue.data;
            
            result = register_data;
        }
    };

    apply {
        modifyValue.data = cs_action.execute(ig_md.hash_idx1);
        if (ig_md.num == 8w0) // we really need the value.
            modifyValue.setValid();
    }
}

// 整一个长度为8的.
control SketchStream_join(
		inout header_t hdr,
		inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout bit<32> field) (bit<32> ARRAY_LENGTH) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
    action copy_filed() { // we can only join 32-bit number, therefore copy to first val_word.
        hdr.kvs.val_word.val_word_1.data = field; 
    }

    OccupyPlace(ARRAY_LENGTH) arrayID;
    CountStage(ARRAY_LENGTH) arrayStage;
    StorageArray(8w1, ARRAY_LENGTH) array1;
    StorageArray(8w2, ARRAY_LENGTH) array2;
    StorageArray(8w3, ARRAY_LENGTH) array3;
    StorageArray(8w4, ARRAY_LENGTH) array4;
    StorageArray(8w5, ARRAY_LENGTH) array5;
    StorageArray(8w6, ARRAY_LENGTH) array6;
    StorageArray(8w7, ARRAY_LENGTH) array7; // 每个array有一个id!

    apply {
        Query_Hash.apply(hdr, ig_md);

        arrayID.apply(hdr, ig_md);

        if (ig_md.InPlace == ig_md.hash_32) { // hit, operate.
            arrayStage.apply(hdr, ig_md);// get the stage number.

            // bring out the info.
            array1.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_2, ig_md); // query the array.
            array2.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_3, ig_md);
            array3.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_4, ig_md);
            array4.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_5, ig_md);
            array5.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_6, ig_md);
            array6.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_7, ig_md);
            array7.apply(hdr.kvs.val_word.val_word_1, hdr.kvs.val_word.val_word_8, ig_md);

            if (ig_md.num != 8w0) {// we stored the value, just drop the pkt.
                drop();
            }
        }
    }
}






// -----------------------------------Reduce, aka count-------------------------------------
// 目前只有counting, 流量没有减少.
control Counting_Array(
    inout header_t hdr,
	inout metadata_t ig_md,
    in bit<HASH_WIDTH> idx,
    in bit<32> src_field,
    out bit<32> dest_field) (bit<32> ARRAY_LENGTH) {
    
    Register<bit<32>, bit<HASH_WIDTH>> (ARRAY_LENGTH, 0) cs_table; // initial value is 0.

    RegisterAction<bit<32>, bit<HASH_WIDTH>, bit<32>>(cs_table) cs_action = {
        void apply(inout bit<32> register_data, out bit<32> result) {
            register_data = register_data + src_field;
            result = register_data;
        }
    };

    apply {
        dest_field = cs_action.execute(idx);
    }
}


// 整一个长度为8的.
control SketchStream_reduce(
        inout header_t hdr,
		inout metadata_t ig_md,
        inout bit<32> field) (bit<32> ARRAY_LENGTH) {
    
    Counting_Array(ARRAY_LENGTH) A1;
    Counting_Array(ARRAY_LENGTH) A2;
    Counting_Array(ARRAY_LENGTH) A3;

    apply {
        Query_Hash.apply(hdr, ig_md);

        A1.apply(hdr, ig_md, ig_md.hash_idx1, field, ig_md.result1);
        A2.apply(hdr, ig_md, ig_md.hash_idx2, field, ig_md.result2);
        A3.apply(hdr, ig_md, ig_md.hash_idx3, field, ig_md.result3);
        ig_md.diff1 = min(ig_md.result1, ig_md.result2);

        field = min(ig_md.diff1, ig_md.result3);
    }
}