# define the static modular.

class P4String():


    def __init__(self, generator):
        self.name = 'asd'
        self.generator = generator
    


        # name = 'asd123www'
        # line = 'My name is {}'.format(name)
        # print(line)

    def generate(self, qid):
        tab = chr(9)

        # header
        with open('p4-code/SwitchIngress.p4' ,'r') as f:
            p4_code = f.read()

        # the GET_THRESHOLD() function.
        with open('p4-code/get_threshold.p4' ,'r') as f:
            part_get_threshold = f.read()
        p4_code = p4_code.replace('<part_get_threshold>', part_get_threshold)

        prefix = 'bfrt.simple_l3.pipe.SwitchIngress.get_threshold.tbl_get_threshold'
        with open('py-code/get_threshold.py' ,'r') as f:
            py_get_threshold = f.read()
        py_get_threshold = py_get_threshold.replace('<prefix>', prefix).replace('<qid>', str(qid)).replace('<threshold>', str(10))
        self.generator.sh_code += py_get_threshold
        
        # the drop function
        with open('p4-code/drop.p4' ,'r') as f:
            part_drop = f.read()
        p4_code = p4_code.replace('<part_drop>', part_drop)

        # the flag0/1 action
        with open('p4-code/flag.p4' ,'r') as f:
            part_flag = f.read()
        p4_code = p4_code.replace('<part_flag>', part_flag)

        # the stflag match action table
        with open('p4-code/set_flag_action_table.p4' ,'r') as f:
            part_set_flag_action_table = f.read()
        p4_code = p4_code.replace('<part_set_flag_action_table>', part_set_flag_action_table)

        # the ipv4_forward action
        with open('p4-code/ipv4_forward.p4' ,'r') as f:
            part_ipv4_forward = f.read()
        p4_code = p4_code.replace('<part_ipv4_forward>', part_ipv4_forward)

        # the ipv4_lpm table
        with open('p4-code/ipv4_lpm.p4' ,'r') as f:
            part_ipv4_lpm = f.read()
        p4_code = p4_code.replace('<part_ipv4_lpm>', part_ipv4_lpm)


        prefix = 'bfrt.simple_l3.pipe.SwitchIngress.ipv4_lpm'
        with open('py-code/ipv4_lpm.py' ,'r') as f:
            py_ipv4_lpm = f.read()
        ip_mac_addr  = self.generator.lpmEntries[0]
        py_ipv4_lpm = py_ipv4_lpm.replace('<prefix>', prefix).replace('<params>', 'hdr_ipv4_dst_addr=ip("{}"), hdr_ipv4_dst_addr_p_length={}, dst_addr=mac("{}"), port={}'.format(*ip_mac_addr))
        self.generator.sh_code += py_ipv4_lpm

        part_operators = ''
        for i, op in enumerate(self.generator.operators):
            part_operators += tab + op + '()  ' + 'func_' + str(i) +';\n'
        p4_code = p4_code.replace('<part_operators>', part_operators)


        with open('p4-code/apply.p4' ,'r') as f:
            part_apply = f.read()
        # call each function sequentially.
        apply_operators = ''
        for i,op in enumerate(self.generator.operators):
            procedure = 'func_'+str(i)+'.apply'
            line = tab*2 + procedure + '(hdr, ig_md'
            if (op[:6] == 'filter'): line += ', ig_dprsr_md'
            line +=');'
            apply_operators += line + '\n'

        # func_0.apply(hdr, ig_md);
		# func_1.apply(hdr, ig_md, ig_dprsr_md);
		# func_2.apply(hdr, ig_md);
		# func_3.apply(hdr, ig_md);
        '''
        if multiple values, then choose the last one.
        '''
        if len(self.generator.keyname) > 1:
            old_key = self.generator.keyname[0]
            new_key = self.generator.keyname[-1]
            apply_operators += tab*2 + self.generator.findVarStr(old_key, 'value') +' = '+ self.generator.findVarStr(new_key, 'value') +';\n'
        part_apply = part_apply.replace('<apply_operators>', apply_operators)
        p4_code = p4_code.replace('<part_apply>', part_apply)
        self.generator.lst.append(p4_code)



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