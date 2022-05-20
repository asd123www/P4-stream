control <replace_with_app_name>(
        inout header_t hdr,
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        out bit<32> field) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }
    Random<bit<32>>() rnd;

<replace_with_actions>

    apply {
<replace_with_body>
    }
}


