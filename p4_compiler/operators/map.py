import os
from .ternary_expr import Ternery_expr

def _readStr(pathname):
    program = ""
    dirname = os.path.dirname(__file__)

    with open(dirname + pathname, mode = 'r') as file:
        for line in file: program = program + line
    return program

class MapOperator():

    def __init__(self, scope, new_key, expr):
        # self.generator = P4Generator
        self.scope = scope
        self.new_key = new_key
        self.expr = Ternery_expr(scope, *expr)
        return

    def gen(self):
        # should be in `Map`.
        size, cond_code, action_code, body_code = self.expr.eval()
        prog = _readStr("/../p4-code/map_func.p4")
        prog = prog.replace("<replace_with_app_name>", "map_{}".format(self.new_key))
        prog = prog.replace("<replace_with_actions>", cond_code + action_code) # add a random decl.
        prog = prog.replace("<replace_with_body>", body_code[:-1])

        return "map_{}".format(self.new_key), prog


# if __name__ == '__main__':
#     aaa = ((("c", "+", "d"), "assign"), None, None)
#     aab = ((("c", "+", "d"), "assign"), None, None)
#     aa = ((("a", "+", "b"), ">"), aaa, aab)
#     ab = ((("a", "+", "b"), ">"), aaa, aab)
#     a = ((("a", "+", "b"), ">"), aa, ab, 2)
#     map_t = MapOperator("asd123www", a)

#     name, prog = map_t.gen()
#     with open(os.path.dirname(__file__) + "/b.p4", "w") as file:
#         file.write(prog)
#     pass