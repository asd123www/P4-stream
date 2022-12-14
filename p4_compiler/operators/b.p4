control filter_asd123www(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        out bit<32> field) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action pkt_filter() {
        ig_md.tmp0 = a + b;

    }


    apply {
        pkt_filter();

        if (ig_md.tmp0 > 0) {
            drop();
        }
    }
}