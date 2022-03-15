	table t<num> {
		key = {
			ig_md.c_<num> : exact;
		}
		actions = {
			a<num>;
			NoAction;
		}
		default_action = NoAction();
	}
	