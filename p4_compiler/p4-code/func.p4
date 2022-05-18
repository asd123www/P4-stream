control <replace_with_app_name>(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }


    apply {
        
    }
}