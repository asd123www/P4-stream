import sys
from StaticCode import P4String


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
        self.transfer = {'+':'add', '-':'sub', '*':'mul', '&':'and', '|':'or', '^':'xor', '=':'eq'}

        return

    def generate(self):
        name = 'map_' + self.old_key +'_'+ self.new_key +'_'+ self.constant +'_'+ self.transfer[self.operation] +'_'+ str(self.generator.counter)
        self.generator.lst.append('control ' + name + '(')
        self.generator.lst.append('        ' + 'inout header_t hdr,')
        self.generator.lst.append('        ' + 'inout metadata_t ig_md) {')
        self.generator.lst.append('')
        self.generator.lst.append('    apply {')
        self.generator.lst.append('        ' + self.generator.findVarStr(self.new_key, 'value') +' = '+ self.constant +' '+ self.operation +' '+ self.generator.findVarStr(self.old_key, 'value') + ';')
        self.generator.lst.append('    }')
        self.generator.lst.append('}')
        self.generator.lst.append('\n')
        
        return name
        # self.code["apply"].append('// map ' + old_key +' '+ new_key +' '+ constant +' '+ operation) # the notation.
        # self.code["apply"].append(self.findVarStr(new_key, 'value') +' = '+ constant +' '+ operation +' '+ self.findVarStr(old_key, 'value') + ';');
        # self.code["apply"].append('\n')


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

        self.generator.lst.append('control ' + name + '(')
        self.generator.lst.append('        ' + 'inout header_t hdr,')
        self.generator.lst.append('        ' + 'inout metadata_t ig_md,')
        self.generator.lst.append('        ' + 'inout ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {')
        self.generator.lst.append('')
        self.generator.lst.append('    action drop() {')
        self.generator.lst.append('        ig_dprsr_md.drop_ctl = 1;')
        self.generator.lst.append('    }')
        self.generator.lst.append('')

        self.generator.lst.append('    apply {')
        
        self.generator.lst.append('        if(' + self.generator.findVarStr(self.key, 'value') +' '+ self.generator.inverse[self.operation] +' '+ self.threshold +')');
        self.generator.lst.append('            drop();'); # For only one (key, value). If multiple we shouldn't drop the packet.

        self.generator.lst.append('    }')
        self.generator.lst.append('}')
        self.generator.lst.append('\n')

        return name
        # self.code["apply"].append('// filter ' + key +' '+ threshold +' '+ operation) # the notation.
        # self.code["apply"].append('if(' + self.findVarStr(key, 'value') +' '+ self.inverse[operation] +' '+ threshold +')');
        # self.code["apply"].append('    drop();'); # For only one (key, value). If multiple we shouldn't drop the packet.
        # self.code["apply"].append('\n')


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
        name = 'reduce_' + self.key +'_'+ self.operation +'_'+ str(self.num) +'_'+ str(self.length) +'_'+ str(self.generator.counter)

        self.generator.lst.append('control ' + name + '(')
        self.generator.lst.append('        ' + 'inout header_t hdr,')
        self.generator.lst.append('        ' + 'inout metadata_t ig_md) {')
        self.generator.lst.append('')

        # define the sketch.
        seed = ['32w0x30243f0b', '32w0x0f79f523', '32w0x6b8cb0c5', '32w0x00390fc3', '32w0x298ac673']
        for i in range(self.num):
            self.generator.lst.append('    ' + self.sketchName[self.operation] +'('+ seed[i] +') update_'+str(self.generator.counter)+'_'+str(i)+';')
        self.generator.lst.append('')

        # define the action: judge the want and overlap the useless.
        for i in range(1, self.num):
            self.generator.lst.append('    action a'+str(i+1)+'() {')
            self.generator.lst.append('        ig_md.est_'+str(i+1)+' = ig_md.est_'+str(i)+';')
            self.generator.lst.append('    }')
        self.generator.lst.append('')

        # define the match/action table: 
        for i in range(1, self.num):
            self.generator.lst.append('    table t'+str(i+1)+' {')
            self.generator.lst.append('        key = {')
            self.generator.lst.append('            ig_md.c_'+str(i+1)+' : exact;')
            self.generator.lst.append('        }')
            self.generator.lst.append('        actions = {')
            self.generator.lst.append('            a'+str(i+1)+';')
            self.generator.lst.append('            NoAction;')
            self.generator.lst.append('        }')
            self.generator.lst.append('        default_action = NoAction();')
            self.generator.lst.append('    }')
        self.generator.lst.append('')


        self.generator.lst.append('    apply {')
        # drop other keys.
        # 1. copy the value to header.
        self.generator.lst.append('        '+self.generator.findVarStr('origin', 'value')+' = '+self.generator.findVarStr(self.key, 'value')+';')
        # 2. drop other keys.
        self.generator.keyname = ['origin']


        # fill the apply content.
        for i in range(self.num):
            func = 'update_'+str(self.generator.counter)+'_'+str(i)
            self.generator.lst.append('        '+func+'.apply(hdr, ig_md.flag, ig_md.est_'+str(i+1)+');')
        
        # fill the judge variable.
        for i in range(1, self.num):
            self.generator.lst.append('        '+'ig_md.est_1'+str(i+1)+' = ig_md.est_'+str(i+1)+' - ig_md.est_'+str(i)+';')
            self.generator.lst.append('        '+'ig_md.c_'+str(i+1)+' = (bit<1>) (ig_md.est_1'+str(i+1)+' >> 31);')
            self.generator.lst.append('        '+'t'+str(i+1)+'.apply();')
        # ig_md.est_12 = ig_md.est_2 - ig_md.est_1;
        # ig_md.c_2 = (bit<1>) (ig_md.est_12 >> 31);
        # t2.apply();

        self.generator.lst.append('    }')
        self.generator.lst.append('}')
        self.generator.lst.append('\n')

        return name



class P4Generator():

    def __init__(self, PSInstance):
        self.maxKeyLen = 3
        self.maxSketchNum = 5
        self.counter = 0
        self.keyname = ['origin'] # maintain the mapping: key -> value.
        self.inverse = {'>':'<=', '<':'>=', '==':'!=', '>=':'<', '<=':'>', "!=":'=='} 

        
        # The code we generate, incremental construct.
        self.lst = []  # the code
        self.operators = []

        self.P4String = P4String(self)
        self.PacketStream = PSInstance

    # find the variable in P4.
    def findVarStr(self, key, type):
        idx = self.keyname.index(key)

        ans = ''
        if (idx == 0):
            ans += 'hdr.kvs.val_word.val_word_1.data'
            # ans += 'hdr.kvs.val_word.' + type # we fix the bits to 32, so only one value.
            # hdr.kvs.val_word.val_word_1.data = ig_md.est_3;
        else:
            # if in metadata_t, then the idx is the corresponding value index.
            # there is no key in metadata_t.
            ans += 'ig_md.' + type + str(idx)
        
        return ans
    

    def Map(self, old_key, new_key, constant, operation):
        if (new_key in self.keyname):
            print('The new key "{}" has existed!'.format(new_key))
            sys.exit(0)
        if (len(self.keyname) >= self.maxKeyLen):
            print('Exceed the maximum metadata length: {}'.format(self.maxKeyLen))
            sys.exit(0)
        
        self.counter += 1
        self.keyname.append(new_key)
        map_t = MapOperator(self, old_key, new_key, constant, operation)
        name = map_t.generate()
        self.operators.append(name)

        return
    

    def Filter(self, key, threshold, operation):
        if key not in self.keyname: 
            print('The key "{}" doesn\'t exist!'.format(key))
            sys.exit(0)
        
        # if 'drop' not in self.code["action"]:
        #     self.code["action"]['drop'] = {}
        #     self.code["action"]['drop']['param'] = {}
        #     self.code["action"]['drop']['body'] = ['ig_dprsr_md.drop_ctl = 1;']

        self.counter += 1
        filter_t = FilterOperator(self, key, threshold, operation)
        name = filter_t.generate()
        self.operators.append(name)

        return

    # @param num: how many sketches you want.
    # @param length: how long the sketches you want.
    def Reduce(self, key, operation, num, length): 
        if num > self.maxSketchNum:
            print('The # of sketch exceeds {}!'.format(self.maxSketchNum))
            sys.exit(0)
        if key not in self.keyname: 
            print('The key "{}" doesn\'t exist!'.format(key))
            sys.exit(0)
        
        # After reduce only the value correspondent key remains, others drop.
        self.counter += 1
        reduce_t = ReduceOperator(self, key, operation, num, length)
        name = reduce_t.generate()
        self.operators.append(name)
        
        return

    def printStr(self, pathname):
        with open(pathname, mode = 'w') as file:
            for line in self.lst:
                file.write(line + '\n')

            # lst = self.code["apply"]
            # for line in lst:
            #     str = '    '
            #     if (line != lst[0] and line != lst[-1]): str += '   '
            #     file.write(str + line + '\n')
    
    def solve(self):
        # the wordCount instance.
        '''
        self.Map('origin', 'identity', '32w0', '+')
        self.Filter('identity', '32w0', '>=')
        self.Map('identity', 'add3', '32w3', '+')
        self.P4String.generate()

        # you need to change the path!
        self.printStr("/home/bfsde/wzz-p4-stream/p4-stream/p4_compiler/test.p4")
        '''


        # only support one query now.
        for p4_query in self.PacketStream:
            for operator in p4_query:
                print(operator)
            
            for operator in p4_query:
                if operator[0] == 'Map':
                    self.Map(operator[1])
                elif operator[0] == 'Filter':
                    self.Filter(operator[1])
                elif operator[0] == 'Reduce':
                    self.Reduce(operator[1])
            
            s = ''
            for line in self.lst: s += line + '\n'
        
        