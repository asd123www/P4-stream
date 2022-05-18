from datetime import datetime
import os
from xml.etree.ElementPath import ops
from urllib3 import Retry

def _readStr(indent, pathname):
    program = ""
    dirname = os.path.dirname(__file__)

    with open(dirname + pathname, mode = 'r') as file:
        for line in file: program = program + "{0}{1}".format(indent, line)
    return program

# a op b, they can be PHV or Immediate number.
class Condition_expr():
    ops = ["+", "-", "&", "|" , "^", "=", "random", "immediate"]

    def __init__(self, a, op, b, dst):
        assert op in self.ops
        assert (op == "random") == ((a is None) and (b is None))
        assert (op == "immediate") == ((a is not None) and (b is None))

        self.a = a
        self.b = b
        self.op = op
        self.dst = dst
        return
    
    # action_code for conditional eval.
    # body_code for assignment eval.
    def eval(self):
        # if self.op == "random":
        #     action_code = "    Random<bit<32>>() rnd;\n"
        #     body_code   = "    field = rnd.get();\n"
        # elif self.op == "immediate":
        #     # action_code += ""
        #     body_code = "    field = 32w{0}".format(self.a)
        # else:
        #     body_code = "    {0}".format(self.a)

        return "ig_md.tmp{} = {} {} {}\n".format(self.dst, self.a, self.op, self.b)


class Ternery_expr():
    INITIAL_LEVEL = 1
    ops = [">", "<", ">=", "<=", "==", "assign"]

    def __init__(self, cond, sub_ter1, sub_ter2, level = 0, size = 0):
        # cond: (Primary_expr, op)
        # sub_ter1/2: child ternary.
        # if sub_ter1/2 == None, then Ternery_expr is atomic.

        assert cond[1] in self.ops
        assert (sub_ter1 is None) == (sub_ter2 is None)
        assert (cond[1] == "assign") == ((sub_ter1 is None) and (sub_ter2 is None))

        self.size = size
        self.level = level # for code indent.
        self.cond = cond
        self.sub_ter1 = sub_ter1
        self.sub_ter2 = sub_ter2
        return

    def eval(self):
        cond_code = "" # maintain variable in `if()`, by `action`.
        action_code = "" # maintain variable in assignment, by `action`.
        body_code = "" # if-else statement.
        indent = "    " * self.level

        # action_cond, body_cond = self.cond[0].eval()
        if self.cond[1] == "assign":
            a = self.cond[0][0]
            op = self.cond[0][1]
            b = self.cond[0][2]

            action_code = _readStr("", "/../p4-code/action.p4")
            # wrong!!! 没处理random的情况.
            action_code = action_code.replace("<replace_with_action_name>", "assign_{0}".format(self.size))
            action_code = action_code.replace("<replace_with_single_instruction>", "{0}field = {1} {2} {3};".format(indent, a, op, b))
            body_code = "{0}assign_{1}();\n".format(indent, self.size)
        else:
            sub_ter1 = Ternery_expr(*self.sub_ter1, level = self.level + 1, size = self.size)
            self.size, cond_code1, action_true, body_true = sub_ter1.eval()
            sub_ter2 = Ternery_expr(*self.sub_ter2, level = self.level + 1, size = self.size)
            self.size, cond_code2, action_false, body_false = sub_ter2.eval()

            # print(cond_code1)
            # print(action_true)
            # print(body_true)
            
            action_code = action_code + action_true + action_false
            body_code = _readStr(indent, "/../p4-code/if_else.p4")
            body_code = body_code.replace("<replace_with_true_body>", body_true)
            body_code = body_code.replace("<replace_with_false_body>", body_false)

            # write condition variable to ig_md.tmp{self.size}
            cond_code = cond_code1 + cond_code2 + Condition_expr(*self.cond[0], self.size).eval()
            body_code = body_code.replace("<replace_with_condition>", "ig_md.tmp{0} {1} 0".format(self.size, self.cond[1]))
            # wrong!!!, body没写
        
        if self.level == self.INITIAL_LEVEL:
            pass

        return self.size + 1, cond_code, action_code, body_code


if __name__ == '__main__':
    aaa = ((("c", "+", "d"), "assign"), None, None)
    aab = ((("c", "+", "d"), "assign"), None, None)
    aa = ((("a", "+", "b"), ">"), aaa, aab)
    ab = ((("a", "+", "b"), ">"), aaa, aab)
    a = ((("a", "+", "b"), ">"), aa, ab, 2)
    x = Ternery_expr(*a)

    a, b, c, d = x.eval()

    with open(os.path.dirname(__file__) + "/b.p4", "w") as file:
        file.write(b)
    with open(os.path.dirname(__file__) + "/c.p4", "w") as file:
        file.write(c)
    with open(os.path.dirname(__file__) + "/d.p4", "w") as file:
        file.write(d)
    pass