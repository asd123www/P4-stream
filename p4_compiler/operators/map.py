from ..StaticCode import P4String, p4_code_path, py_code_path


'''
control name(
        inout header_t hdr,
        inout metadata_t ig_md) {
    
    apply {

    }
}
'''
class MapOperator():

    def __init__(self, P4Generator, old_key, new_key, constant, operation):
        self.generator = P4Generator
        self.old_key = old_key
        self.new_key = new_key
        self.constant = constant
        self.operation = operation
        self.transfer = {'+':'add', '-':'sub', '&':'and', '|':'or', '^':'xor', '=':'eq'}

        return

    def generate(self):
        name = 'map_' + self.old_key +'_'+ self.new_key +'_'+ self.constant +'_'+ self.transfer[self.operation] +'_'+ str(self.generator.counter)
        with open(p4_code_path + '/operator/map.p4' ,'r') as f:
            part_map = f.read()
        part_map = part_map.replace('<name>', name)

        if self.operation != '=':
            part_map = part_map.replace('<RandomGenerator>', '')
            part_map = part_map.replace('<operation>', self.generator.findVarStr(self.new_key, 'value') +' = '+ self.constant +' '+ self.operation +' '+ self.generator.findVarStr(self.old_key, 'value') + ';')
        else:
            if self.constant == 'random':
                part_map = part_map.replace('<RandomGenerator>', 'Random<bit<32>>() rnd;')
                part_map = part_map.replace('<operation>', self.generator.findVarStr(self.new_key, 'value') +' = rnd.get();')
            else:
                part_map = part_map.replace('<RandomGenerator>', '')
                part_map = part_map.replace('<operation>', self.generator.findVarStr(self.new_key, 'value') +' = '+ self.constant + ';')


        part_map = part_map.replace('<SetHeaderToValid>', 'hdr.kvs.val_word.val_word_'+str(len(self.generator.keyname))+'.setValid();')
        
        self.generator.lst.append(part_map)
        return name
        # self.code["apply"].append('// map ' + old_key +' '+ new_key +' '+ constant +' '+ operation) # the notation.
        # self.code["apply"].append(self.findVarStr(new_key, 'value') +' = '+ constant +' '+ operation +' '+ self.findVarStr(old_key, 'value') + ';');
        # self.code["apply"].append('\n')