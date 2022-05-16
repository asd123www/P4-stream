from curses import keyname
from dis import show_code
from re import L
import sys
import os
from .StaticCode import P4String, p4_code_path, py_code_path
from .operators.filter import FilterOperator
from .operators.map import MapOperator
from .operators.reduce import ReduceOperator


class P4Generator():

    def __init__(self, PSInstance):
        self.maxKeyLen = 3
        self.maxSketchNum = 5
        self.counter = 0
        self.keyname = ['origin'] # maintain the mapping: key -> value.
        self.inverse = {'>':'<=', '<':'>=', '==':'!=', '>=':'<', '<=':'>', "!=":'=='} 

        self.sh_code = ''
        # ip_address, length, mac_address, port.
        
        self.lpmEntries = [['10.1.100.2', '32', 'ff:ff:ff:ff:ff:ff', '60']]
        self.arraylist = []
        
        # The code we generate, incremental construct.
        self.lst = []  # the code
        self.operators = []

        self.P4String = P4String(self)
        self.PacketStream = PSInstance

    # find the variable in P4.
    def findVarStr(self, key, type):
        idx = self.keyname.index(key)
        return 'hdr.kvs.val_word.val_word_' + str(idx+1) +'.data'
    

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

    def readStr(self, pathname):

        dirname = os.path.dirname(__file__)

        with open(dirname + pathname, mode = 'r') as file:
            for line in file:
                self.lst.append(line[:-1])
            # for line in self.lst:
            #     file.write(line + '\n')

            # lst = self.code["apply"]
            # for line in lst:
            #     str = '    '
            #     if (line != lst[0] and line != lst[-1]): str += '   '
            #     file.write(str + line + '\n')
        
    def shiftFlagCode(self):
        tab = chr(9)
        self.sh_code += 'import time\n\nflag = 0\nwhile True:\n'

        getTime = 'int(time.time())'

        self.sh_code += tab + 'curtime = {}\n'.format(getTime)

        # flag = 1
        self.sh_code += tab + 'if flag:\n'
        for func in self.arraylist:
            self.sh_code += tab*2 + '{}.cs_table2.clear()\n'.format(func);
        self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.clear()\n'
        self.sh_code += tab*2 + 'flag = 0\n'

        # flag = 0
        self.sh_code += tab + 'else:\n'
        for func in self.arraylist:
            self.sh_code += tab*2 + '{}.cs_table1.clear()\n'.format(func);
        self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 0)\n'
        self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 1)\n'
        self.sh_code += tab*2 + 'flag = 1\n'

        self.sh_code += tab + 'while True:\n' + tab*2 + 'if curtime != int(time.time()):\n' + tab*3 + 'break\n'

        return
    
    def solve(self):
        # only support one query now.

        # print (type(self.PacketStream))
        p4_code = ''
        em_formats = []

        self.readStr("/p4-code/half.p4")
        
        for p4_query in self.PacketStream:
            for operator in p4_query.operators:
                # print(operator[0])
                if operator[0] == 'Map':
                    self.Map(*operator[1])
                elif operator[0] == 'Filter':
                    self.Filter(*operator[1])
                elif operator[0] == 'Reduce':
                    self.Reduce(*operator[1])

            self.P4String.generate(p4_query.qid)

            em_formats.append({"qid": p4_query.qid, "qname": p4_query.qname, "em_format": self.keyname[-1]})

        self.readStr("/p4-code/pipe.p4")

        for line in self.lst: p4_code += line + '\n'

        self.shiftFlagCode()

        # print(os.path.dirname(__file__) + "/test.p4")
        # # print(self.sh_code)
        # with open(os.path.dirname(__file__) + "/test.py", "w") as file:
        #     file.write(self.sh_code)
        # with open(os.path.dirname(__file__) + "/test.p4", "w") as file:
        #     file.write(p4_code)

        return p4_code, self.sh_code, em_formats