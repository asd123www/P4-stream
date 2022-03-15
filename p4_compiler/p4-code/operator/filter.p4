control <name>(
        inout header_t hdr,
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
    apply {
        if(<condition>)
            drop();

    }
}
