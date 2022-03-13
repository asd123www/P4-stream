control SwitchIngress(
	inout header_t hdr,
	inout metadata_t ig_md,
	in ingress_intrinsic_metadata_t ig_intr_md,
	in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
	inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
	inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

<part_get_threshold>

<part_drop>

<part_flag>

<part_set_flag_action_table>

<part_ipv4_forward>

<part_ipv4_lpm>

<part_operators>

	apply{

<part_apply>

	}
}
