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
class Atomic_expr():
    ops = ["+", "-", "&", "|" , "^", "=", "random", "immediate"]

    def __init__(self, scope, a, op, b, dst):
        assert op in self.ops
        assert (op == "random") == ((a is None) and (b is None))
        assert (op == "immediate") == ((a is not None) and (b is None))

        self.scope = scope
        self.a = a
        self.b = b
        self.op = op
        self.dst = dst
        return
    
    def find_represent(self, name):
        if name.isnumeric():
            return "32w{}".format(name)
        return self.scope.findVarStr(name)

    # action_code for conditional eval.
    # body_code for assignment eval.
    def eval(self):
        if self.op == "random":
            return "{} = rnd.get();\n".format(self.dst)
        elif self.op == "immediate":
            return "{0} = 32w{1}\n".format(self.dst, self.a)
        name_a = self.find_represent(self.a)
        name_b = self.find_represent(self.b)
        return "{} = {} {} {};\n".format(self.dst, name_a, self.op, name_b)


class Ternery_expr():
    INITIAL_LEVEL = 2
    ops = [">", "<", ">=", "<=", "==", "assign"]

    def __init__(self, scope, cond, sub_ter1, sub_ter2, level = 0, size = 0):
        # cond: (Primary_expr, op)
        # sub_ter1/2: child ternary.
        # if sub_ter1/2 == None, then Ternery_expr is atomic.

        assert cond[1] in self.ops
        assert (sub_ter1 is None) == (sub_ter2 is None)
        assert (cond[1] == "assign") == ((sub_ter1 is None) and (sub_ter2 is None))

        self.scope = scope
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
            action_code = _readStr("", "/../p4-code/action.p4")
            action_code = action_code.replace("<replace_with_action_name>", "assign_{0}".format(self.size))
            action_code = action_code.replace("<replace_with_single_instruction>", Atomic_expr(self.scope, *self.cond[0], "field").eval()[:-1])
            body_code = "{0}assign_{1}();\n".format(indent, self.size)
        else:
            sub_ter1 = Ternery_expr(*self.sub_ter1, level = self.level + 1, size = self.size)
            self.size, cond_code1, action_true, body_true = sub_ter1.eval()
            sub_ter2 = Ternery_expr(*self.sub_ter2, level = self.level + 1, size = self.size)
            self.size, cond_code2, action_false, body_false = sub_ter2.eval()

            action_code = action_code + action_true + action_false
            body_code = _readStr(indent, "/../p4-code/if_else.p4")
            body_code = body_code.replace("<replace_with_true_body>", body_true)
            body_code = body_code.replace("<replace_with_false_body>", body_false)

            # write condition variable to ig_md.tmp{self.size & 31}, lowbit to condition.
            cond_code = cond_code1 + cond_code2 + Atomic_expr(self.scope, *self.cond[0], "ig_md.tmp{0}".format(self.size & (31))).eval()
            body_code = body_code.replace("<replace_with_condition>", "ig_md.tmp{0} {1} 0".format(self.size & 31, self.cond[1]))
            self.size += 1
        
        if self.level == self.INITIAL_LEVEL:
            cond_code = _readStr("", "/../p4-code/action.p4").replace("<replace_with_single_instruction>", cond_code)
            cond_code = cond_code.replace("<replace_with_action_name>", "condition_assign")
            body_code = indent + "condition_assign();\n" + body_code

        return self.size + 32, cond_code, action_code, body_code
