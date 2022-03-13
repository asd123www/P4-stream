	table stflag{
		key = {
			ig_md.flag : exact;
		}
		actions = {
			flag1;
			flag0;
		}
		size = 2;
		default_action = flag0();
	}
