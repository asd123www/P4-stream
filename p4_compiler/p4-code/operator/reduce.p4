
control <name> (
        inout header_t hdr,
        inout metadata_t ig_md) {


<define_sketch>

<define_action>

<match_action_table>

    apply {
<copy_the_value_to_header>
<apply_content>
<judge_variable>
<restore_result>
<SetHeaderValueInvalid>
    }
}

