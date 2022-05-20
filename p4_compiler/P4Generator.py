from asyncio import new_event_loop
from csv import field_size_limit
from curses import keyname
from dis import show_code
from re import L
import sys
import os
from src.packetstream import PacketStream
from .StaticCode import P4String, p4_code_path, py_code_path
from .operators.filter import FilterOperator
from .operators.map import MapOperator
from .operators.reduce import ReduceOperator


# return the content of file by `String`
def _readStr(pathname):
    program = ""
    dirname = os.path.dirname(__file__)

    with open(dirname + pathname, mode = 'r') as file:
        for line in file: program = program + line
    return program


class Application():
    MAX_SKETCHNUM = 4

    # every operator return: (name, program)
    # program is only for appending, name is for decl in app control block.
    # different operator has different API, therefore need special treatment.
    def __init__(self, p4_query):
        self.name = p4_query.qname
        self.p4_query = p4_query

        self.maxKeyLen = 3
        self.maxSketchNum = 4
        self.counter = 0
        self.inverse = {'>':'<=', '<':'>=', '==':'!=', '>=':'<', '<=':'>', "!=":'=='} 
        self.keyname = ['origin'] # maintain the mapping: key -> value.
        return
    
    # 2022.5.18: now we only store value in header, metadata as intermedia represent.
    # find the variable in P4.
    def findVarStr(self, key):
        idx = self.keyname.index(key)
        return 'hdr.kvs.val_word.val_word_' + str(idx+1) +'.data'
    
    def Map(self, new_key, expr):
        if (new_key in self.keyname):
            print('The new key "{}" has existed!\n'.format(new_key))
            sys.exit(0)
        if (len(self.keyname) >= self.maxKeyLen):
            print('Exceed the maximal number of value: {}\n'.format(self.maxKeyLen))
            sys.exit(0)

        self.counter += 1
        self.keyname.append(new_key)
        field = self.findVarStr(new_key)
        map_t = MapOperator(self, new_key, expr)
        name, func = map_t.gen()
        self.decl += func


        self.program_action += "    {}() func_{};\n".format(name, self.counter)
        self.program_body += "        func_{}.apply(hdr, ig_md, ig_dprsr_md, {});\n".format(self.counter, field)
    

    def Filter(self, condition):
        self.counter += 1
        filter_t = FilterOperator(self, condition, str(self.counter))
        name, func = filter_t.gen()
        self.decl += func

        self.program_action += "    {}() func_{};\n".format(name, self.counter)
        self.program_body += "        func_{}.apply(hdr, ig_md, ig_dprsr_md);\n".format(self.counter)

    def Reduce(self, key):
        if key not in self.keyname: 
            print('The key "{}" doesn\'t exist!'.format(key))
            sys.exit(0)
        
        # wrong!!! we should inherit sketch config from autosketch
        field = self.findVarStr(key)
        name = "SketchStream_reduce({}, {}, {})".format("8w3", "32w4096", "32w4095") #(level, length, mask)
        self.counter += 1
        self.program_action += "    {} func_{};\n".format(name, self.counter)
        self.program_body += "        func_{}.apply(hdr, ig_md, ig_dprsr_md, {});\n".format(self.counter, field)
    
    def eval(self):

        # wrong!!!, 调用auto sketch的生成config接口得到stateful状态配置.

        self.decl = ""
        self.program_action = ""
        self.program_body = ""
        self.program = _readStr("/p4-code/func.p4")
        self.program = self.program.replace("<replace_with_app_name>", self.p4_query.qname)

        for operator in self.p4_query.operators:
            if operator[0] == 'Map':
                self.Map(*operator[1])
            elif operator[0] == 'Filter':
                self.Filter(*operator[1])
            elif operator[0] == 'Reduce':
                self.Reduce(*operator[1])
            elif operator[0] == 'Join':
                assert 0 == 1, "Join not implemented"
            elif operator[0] == 'Distinct':
                assert 0 == 1, "Distinct not implemented"
            elif operator[0] == 'Groupby_max':
                assert 0 == 1, "Groupby_max not implemented"
            elif operator[0] == 'Groupby_min':
                assert 0 == 1, "Groupby_min not implemented"
            else:
                assert(0 == 1)
        
        self.program = self.program.replace("<replace_with_actions>", self.program_action)
        self.program = self.program.replace("<replace_with_body_action>", self.program_body[:-1])

        return self.decl + self.program



# ugly things mustn't be the right choices, no more reuse!
class P4Generator():

    def __init__(self, PSInstance):

        self.sh_code = ''
        # ip_address, length, mac_address, port.
        
        self.lpmEntries = [['10.1.100.2', '32', 'ff:ff:ff:ff:ff:ff', '60']]
        self.arraylist = []

        self.P4String = P4String(self)
        self.PacketStream = PSInstance

    # def shiftFlagCode(self):
    #     tab = chr(9)
    #     self.sh_code += 'import time\n\nflag = 0\nwhile True:\n'

    #     getTime = 'int(time.time())'

    #     self.sh_code += tab + 'curtime = {}\n'.format(getTime)

    #     # flag = 1
    #     self.sh_code += tab + 'if flag:\n'
    #     for func in self.arraylist:
    #         self.sh_code += tab*2 + '{}.cs_table2.clear()\n'.format(func);
    #     self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.clear()\n'
    #     self.sh_code += tab*2 + 'flag = 0\n'

    #     # flag = 0
    #     self.sh_code += tab + 'else:\n'
    #     for func in self.arraylist:
    #         self.sh_code += tab*2 + '{}.cs_table1.clear()\n'.format(func);
    #     self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 0)\n'
    #     self.sh_code += tab*2 + 'bfrt.simple_l3.pipe.SwitchIngress.stflag.add_with_flag1(flag = 1)\n'
    #     self.sh_code += tab*2 + 'flag = 1\n'

    #     self.sh_code += tab + 'while True:\n' + tab*2 + 'if curtime != int(time.time()):\n' + tab*3 + 'break\n'

    #     return
    
    def solve(self):
        # only support one query now.
        em_formats = []

        program = _readStr("/p4-code/template.p4")

        # assert(len(self.PacketStream) == 1)
        apps_code = ""
        decl_code = ""
        branch_code = ""
        for p4_query in self.PacketStream:
            app = Application(p4_query)
            app_code = app.eval()
            apps_code = apps_code + app_code # append code of this app
            decl_code = decl_code + "    {0}() func_{0};\n".format(p4_query.qname)

            # divert different flows to corres function.
            if_state = _readStr("/p4-code/branch.p4")
            if_state = if_state.replace("<replace_with_app_qid>", "16w{0}".format(p4_query.qid))
            if_state = if_state.replace("<replace_with_function_call>", "func_{0}.apply(hdr, ig_md, ig_dprsr_md);".format(p4_query.qname))
            branch_code = branch_code + if_state

            # wrong!!! format没整理好.
            em_formats.append({"qid": p4_query.qid, "qname": p4_query.qname, "em_format": ""})
        
        # define the apps
        program = program.replace("<replace_with_multi_application_definition>", apps_code)
        program = program.replace("<replace_with_multi_application_declaration>", decl_code)
        program = program.replace("<replace_with_multi_application_call>", branch_code[:-1])
        
        # self.shiftFlagCode()

        return program, self.sh_code, em_formats