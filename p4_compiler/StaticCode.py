# define the static modular.

class P4String():


    def __init__(self, generator):
        self.name = 'asd'
        self.generator = generator
    
    def generate(self):
        tab = chr(9)


        self.generator.lst.append('control SwitchIngress(')
        self.generator.lst.append(tab + 'inout header_t hdr,')
        self.generator.lst.append(tab + 'inout metadata_t ig_md,')
        self.generator.lst.append(tab + 'in ingress_intrinsic_metadata_t ig_intr_md,')
        self.generator.lst.append(tab + 'in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,')
        self.generator.lst.append(tab + 'inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,')
        self.generator.lst.append(tab + 'inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {')
        self.generator.lst.append('')

        self.generator.lst.append(tab + "GET_THRESHOLD() get_threshold;")
        
        self.generator.lst.append('')
        self.generator.lst.append('    action drop() {')
        self.generator.lst.append('        ig_dprsr_md.drop_ctl = 1;')
        self.generator.lst.append('    }')
        self.generator.lst.append('')
        self.generator.lst.append(tab + "action flag1() {")
        self.generator.lst.append(tab*2 + "ig_md.flag = 1;")
        self.generator.lst.append(tab + "}")
        self.generator.lst.append(tab + "action flag0() {")
        self.generator.lst.append(tab*2 + "ig_md.flag = 0;")
        self.generator.lst.append(tab + "}")
        self.generator.lst.append(tab + "table stflag{")
        self.generator.lst.append(tab*2 + "key = {")
        self.generator.lst.append(tab*3 + "ig_md.flag : exact;")
        self.generator.lst.append(tab*2 + "}")
        self.generator.lst.append(tab*2 + "actions = {")
        self.generator.lst.append(tab*3 + "flag1;")
        self.generator.lst.append(tab*3 + "flag0;")
        self.generator.lst.append(tab*2 + "}")
        self.generator.lst.append(tab*2 + "size = 2;")
        self.generator.lst.append(tab*2 + "default_action = flag0();")
        self.generator.lst.append(tab + "}")
        self.generator.lst.append('')


        self.generator.lst.append(tab + "action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {")
        self.generator.lst.append(tab*2 + "ig_tm_md.ucast_egress_port = port;")
        self.generator.lst.append(tab*2 + "hdr.ethernet.src_addr = hdr.ethernet.dst_addr;")
        self.generator.lst.append(tab*2 + "hdr.ethernet.dst_addr = dst_addr;")
        self.generator.lst.append(tab*2 + "hdr.ipv4.ttl = hdr.ipv4.ttl - 1;")
        self.generator.lst.append(tab + "}")
        self.generator.lst.append('')

        self.generator.lst.append(tab + "table ipv4_lpm {")
        self.generator.lst.append(tab*2 + "key = {")
        self.generator.lst.append(tab*3 + "hdr.ipv4.dst_addr: lpm;")
        self.generator.lst.append(tab*2 + "}")
        self.generator.lst.append(tab*2 + "actions = {")
        self.generator.lst.append(tab*3 + "ipv4_forward;")
        self.generator.lst.append(tab*3 + "drop;")
        self.generator.lst.append(tab*3 + "NoAction;")
        self.generator.lst.append(tab*2 + "}")
        self.generator.lst.append(tab*2 + "size = 512;")
        self.generator.lst.append(tab*2 + "default_action = NoAction();")
        self.generator.lst.append(tab + "}")
        self.generator.lst.append('')

        for i, op in enumerate(self.generator.operators):
            self.generator.lst.append(tab + op + '()  ' + 'func_' + str(i) +';')


        self.generator.lst.append('')
        self.generator.lst.append(tab + "apply {")
        self.generator.lst.append(tab*2 + "stflag.apply();")

        # call each function sequentially.
        self.generator.lst.append('')
        for i,op in enumerate(self.generator.operators):
            procedure = 'func_'+str(i)+'.apply'
            line = tab*2 + procedure + '(hdr, ig_md'
            if (op[:6] == 'filter'): line += ', ig_dprsr_md'
            line +=');'
            self.generator.lst.append(line)

        # func_0.apply(hdr, ig_md);
		# func_1.apply(hdr, ig_md, ig_dprsr_md);
		# func_2.apply(hdr, ig_md);
		# func_3.apply(hdr, ig_md);
        self.generator.lst.append('')

        '''
        if multiple values, then choose the last one.
        '''
        if len(self.generator.keyname) > 1:
            old_key = self.generator.keyname[0]
            new_key = self.generator.keyname[-1]
            self.generator.lst.append(tab*2 + self.generator.findVarStr(old_key, 'value') +' = '+ self.generator.findVarStr(new_key, 'value') +';')


        self.generator.lst.append(tab*2 + "ipv4_lpm.apply();")
        self.generator.lst.append(tab + "}")

        self.generator.lst.append("}")



'''
control SwitchIngress(
        inout header_t hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {
        
    GET_THRESHOLD() get_threshold;

    action flag1(){
        ig_md.flag = 1;
    }
    action flag0(){
        ig_md.flag = 0;
    }
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
 
    action ipv4_forward(mac_addr_t dst_addr, PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
        hdr.ethernet.src_addr = hdr.ethernet.dst_addr;
        hdr.ethernet.dst_addr = dst_addr;
        hdr.ipv4.ttl = hdr.ipv4.ttl - 1;
        hdr.kvs.val_word.val_word_1.data = ig_md.est_3;
    }
    
    table ipv4_lpm {
        key = {
            hdr.ipv4.dst_addr: lpm;
        }
        actions = {
            ipv4_forward;
            drop;
            NoAction;
        }
        size = 512;
        default_action = NoAction();
    }
 

    apply {
        stflag.apply();
        
        reduce()

        ipv4_lpm.apply();
    }
}
'''