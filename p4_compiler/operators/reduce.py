from ..StaticCode import P4String, p4_code_path, py_code_path

'''
control name(
        inout header_t hdr,
        inout metadata_t ig_md) {

    apply {

    }
}
'''
class ReduceOperator():

    def __init__(self, P4Generator, key, operation, num, length):
        self.generator = P4Generator
        self.key = key
        self.operation = operation
        self.num = num
        self.length = length # the length can be fixed... later change.
        self.sketchName = {'min': 'CMin_UPDATE_KEY',
                           'max': 'CMax_UPDATE_KEY',
                           'sum': 'CSum_UPDATE_KEY'}

        return 
    
    def generate(self):
        tab = chr(9)

        name = 'reduce_' + self.key +'_'+ self.operation +'_'+ str(self.num) +'_'+ str(self.length) +'_'+ str(self.generator.counter)
        with open(p4_code_path + '/operator/reduce.p4' ,'r') as f:
            part_reduce = f.read()
        part_reduce = part_reduce.replace('<name>', name)
        # define the sketch.
        part_define_sketch = ''
        seed = ['32w0x30243f0b', '32w0x0f79f523', '32w0x6b8cb0c5', '32w0x00390fc3', '32w0x298ac673']
        for i in range(self.num):
            part_define_sketch = part_define_sketch + tab + self.sketchName[self.operation] +'('+ seed[i] +') update_'+str(self.generator.counter)+'_'+str(i)+';\n'
    
        part_reduce = part_reduce.replace('<define_sketch>', part_define_sketch)
        # define the action: judge the want and overlap the useless.
        part_define_action = ''
        for i in range(1, self.num):
            part_define_action = part_define_action + tab + 'action a'+str(i+1)+'() {\n'
            part_define_action = part_define_action + tab*2 + 'ig_md.est_'+str(i+1)+' = ig_md.est_'+str(i)+';\n'
            part_define_action = part_define_action + tab + '}\n'
        part_reduce = part_reduce.replace('<define_action>', part_define_action)

        # define the match/action table: 
        part_match_action_table = ''
        for i in range(1, self.num):
            # bfrt.simple_l3.pipe.SwitchIngress.t2.clear()
            # bfrt.simple_l3.pipe.SwitchIngress.t2.add_with_a2(c_2 = 0)
            # bfrt.simple_l3.pipe.SwitchIngress.t2.dump()
            prefix = 'bfrt.simple_l3.pipe.{}.t'.format(name)+str(i+1)
            # self.generator.sh_code += '{}.clear()\n'.format(prefix)
            # self.generator.sh_code += '{}.add_with_a{}(c_{} = 0)\n'.format(prefix, i+1, i+1)
            # self.generator.sh_code += '{}.dump()\n\n\n'.format(prefix)
            with open(p4_code_path + '/operator/match_action_table.p4' ,'r') as f:
                match_action_table = f.read()
            match_action_table = match_action_table.replace('<num>', str(i+1))
            part_match_action_table += match_action_table
        part_reduce = part_reduce.replace('<match_action_table>', part_match_action_table)
        
        # 将没用的header中的value位置为Invalid.
        setInValidCode = ''
        for i in range(2, len(self.generator.keyname) + 1):
            setInValidCode += tab*2 + 'hdr.kvs.val_word.val_word_' + str(i) + '.setInvalid();\n'
        part_reduce = part_reduce.replace('<SetHeaderValueInvalid>', setInValidCode)

        # drop other keys.
        # 1. copy the value to header.
        part_reduce = part_reduce.replace('<copy_the_value_to_header>', tab*2+self.generator.findVarStr('origin', 'value')+' = '+self.generator.findVarStr(self.key, 'value')+';')
        # 2. drop other keys.
        self.generator.keyname = ['origin']

        # fill the apply content.
        part_apply_content = ''
        for i in range(self.num):
            func = 'update_'+str(self.generator.counter)+'_'+str(i)
            self.generator.arraylist.append('bfrt.simple_l3.pipe.SwitchIngress.func_{}.{}'.format(self.generator.counter-1, func))
            part_apply_content += tab*2+func+'.apply(hdr, ig_md.flag, ig_md.est_'+str(i+1)+');\n'
        
        part_reduce = part_reduce.replace('<apply_content>', part_apply_content)
        
        # fill the judge variable.
        part_judge_variable = ''
        for i in range(1, self.num):
            part_judge_variable += tab*2 + 'ig_md.est_1'+str(i+1)+' = ig_md.est_'+str(i+1)+' - ig_md.est_'+str(i)+';\n'
            part_judge_variable += tab*2 + 'ig_md.c_'+str(i+1)+' = (bit<1>) (ig_md.est_1'+str(i+1)+' >> 31);\n'
            part_judge_variable += tab*2 + 't'+str(i+1)+'.apply();\n'
        # ig_md.est_12 = ig_md.est_2 - ig_md.est_1;
        # ig_md.c_2 = (bit<1>) (ig_md.est_12 >> 31);
        # t2.apply();
        part_reduce = part_reduce.replace('<judge_variable>', part_judge_variable)
        
        # you should restore the result in header.value
        part_reduce = part_reduce.replace('<restore_result>', tab*2+self.generator.findVarStr('origin', 'value')+' = ig_md.est_'+str(self.num)+';')


        self.generator.lst.append(part_reduce)

        return name