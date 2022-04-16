control <name> (
		inout header_t hdr,
		inout metadata_t ig_md) {
	
	<RandomGenerator>

	apply {
		<operation>
		<SaveValueToHeader>
		<SetHeaderToValid>
	}
}
