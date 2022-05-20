import os
from ternary_expr import Atomic_expr, Ternery_expr

def _readStr(pathname):
    program = ""
    dirname = os.path.dirname(__file__)

    with open(dirname + pathname, mode = 'r') as file:
        for line in file: program = program + line
    return program

class FilterOperator():

    def __init__(self, scope, cond_expr, identity):
        self.id = identity
        self.scope = scope
        self.cond_expr = cond_expr
        return

    def gen(self):

        name = "filter_{}".format(self.id)
        body_code = _readStr("/../p4-code/func.p4")
        
        cond_code = _readStr("/../p4-code/action.p4")
        cond_code = cond_code.replace("<replace_with_single_instruction>", Atomic_expr(self.scope, *self.cond_expr[0], "ig_md.tmp0").eval())
        cond_code = cond_code.replace("<replace_with_action_name>", "pkt_filter")

        body_code = body_code.replace("<replace_with_app_name>", name)
        body_code = body_code.replace("<replace_with_body_action>", "pkt_filter();\n")
        body_code = body_code.replace("<replace_with_condition>", "ig_md.tmp0 {} 0".format(self.cond_expr[1]))
        body_code = body_code.replace("<replace_with_actions>", cond_code)

        return name, body_code

if __name__ == '__main__':
    map_t = FilterOperator((("a", "+", "b"), ">"), "asd123www")

    name, prog = map_t.gen()
    with open(os.path.dirname(__file__) + "/b.p4", "w") as file:
        file.write(prog)
    pass