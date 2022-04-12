from ..StaticCode import P4String, p4_code_path, py_code_path

'''
control name(
        inout header_t hdr,
        inout metadata_t ig_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {
    
    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    apply {

    }
}
'''
class FilterOperator():

    def __init__(self, P4Generator, key, threshold, operation):
        self.generator = P4Generator
        self.key = key
        self.threshold = threshold
        self.operation = operation
        self.transfer = {'>':'greater', '<':'less', '==':'equal', '>=':'ge', '<=':'le'}

        return

    def generate(self):
        name = 'filter_' + self.key +'_'+ self.threshold +'_'+ self.transfer[self.operation] +'_'+ str(self.generator.counter)
        with open(p4_code_path + '/operator/filter.p4' ,'r') as f:
            part_filter = f.read()
        part_filter = part_filter.replace('<name>', name)
        part_filter = part_filter.replace('<condition>', self.generator.findVarStr(self.key, 'value') +' '+ self.generator.inverse[self.operation] +' '+ self.threshold)
        self.generator.lst.append(part_filter)
        
        return name
        # self.code["apply"].append('// filter ' + key +' '+ threshold +' '+ operation) # the notation.
        # self.code["apply"].append('if(' + self.findVarStr(key, 'value') +' '+ self.inverse[operation] +' '+ threshold +')');
        # self.code["apply"].append('    drop();'); # For only one (key, value). If multiple we shouldn't drop the packet.
        # self.code["apply"].append('\n')