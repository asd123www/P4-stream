

from __future__ import print_function
from ast import operator

from gurobipy import Model, GRB, GurobiError


'''
@param Flow: 前缀operator放到data plane之后的流量大小. 例如[[5, 3, 2, 1] , [3, 2]]代表2个app, 每个流量情况.
@param App2Operator: 每个App包含的Operator. 例如 [[0, 1, 2, 3] , [0, 2]] 其中app(1), app(2)共用了一个Array 2.
@param Operator2Arrays: 每个operator包含的Array. 例如[[0], [1], [2, 3, 4], [5]], operator(2)需要三个array. 
@param Arrays_ALU: 每个array需要的ALU资源. 例如[0, 1, 3, 3, 3, 1].
@param Arrays_Memo: 每个array需要的memory资源. 例如[0, 4096, 2048, 2048, 2048, 4096].

@param ALU_Max: 每个stage的ALU个数.
@param Memo_Max: 每个stage的register个数. 单位为byte.
@param Stage_Max: 最大stage个数.
'''
def solve_lp(Flow, App2Operator, Operator2Arrays, Arrays_ALU, Arrays_Memo, ALU_Max = 4, Memo_Max = (1<<12) - 1, Stage_Max = 8):
    # check the sanity of input.
    assert(len(Arrays_ALU) == len(Arrays_Memo))
    assert(len(Flow) == len(App2Operator))


    name = "SketchStream"
    Num_of_Array = len(Arrays_ALU)
    Num_of_App = len(Flow)

    try:
        m = Model(name)


        # indicate whether j operator of app i is in data plane.
        Split_Point = {}
        for i in range(Num_of_App):
            Split_Point[i] = {}
            for op in range(len(App2Operator[i])):
                Split_Point[i][op] = m.addVar(lb = 0, ub = 1, vtype = GRB.BINARY, name = 'InDataPlane_App_' + str(i) + '_op_' + str(op))
                if op > 0: m.addConstr(Split_Point[i][op] <= Split_Point[i][op - 1])
            m.addConstr(sum(Split_Point[i][op] for op in range(len(App2Operator[i]))) >= 1)
        
        # which state the array in, if out in Stage_Max + 1.
        Array2Stage = {}
        for i in range(Num_of_Array):
            Array2Stage[i] = {}
            for j in range(Stage_Max + 1):
                Array2Stage[i][j] = m.addVar(lb = 0, ub = 1, vtype = GRB.BINARY, name = 'Array2State_' + str(i) + '_' + str(j))
            m.addConstr(1 == sum(Array2Stage[i][j] for j in range(Stage_Max + 1))) # must place in one stage.
        
        # satisfy the ALU & memory constraint for each stage.  Except the last Virtual Stage.
        for j in range(Stage_Max):
            m.addConstr(sum(Arrays_ALU[i] * Array2Stage[i][j] for i in range(Num_of_Array)) <= ALU_Max)
            m.addConstr(sum(Arrays_Memo[i] * Array2Stage[i][j] for i in range(Num_of_Array)) <= Memo_Max)

        # transfer the 0/1 array to integer.
        Array2StageID = {}
        for i in range(Num_of_Array):
            Array2StageID[i] = m.addVar(lb = 0, ub = Stage_Max, vtype = GRB.INTEGER, name = "Array2StateID_" + str(i))
            for j in range(0, Stage_Max + 1):
                m.addGenConstrIndicator(Array2Stage[i][j], True, Array2StageID[i] == j)
        


        # strictly ordered for different operators.
        for i in range(Num_of_App):
            operators = App2Operator[i]
            # print(operators)
            for j in range(1, len(operators)):
                op1 = operators[j-1]
                op2 = operators[j]
                print('asd123www', i, j, op1, op2)
                fir = Operator2Arrays[op1][-1]
                sec = Operator2Arrays[op2][0]
                m.addGenConstrIndicator(Split_Point[i][j], True, Array2StageID[fir] - Array2StageID[sec] <= -1)
        
        # loosely ordered for different Arrays of the same operator.
        for op in range(len(Operator2Arrays)):
            Arrays = Operator2Arrays[op]
            for j in range(1, len(Arrays)):
                fir = Arrays[j-1]
                sec = Arrays[j]
                m.addConstr(Array2StageID[fir] <= Array2StageID[sec])
                # m.addGenConstrIndicator(Array2Stage[sec][Stage_Max], False, Array2StageID[fir] <= Array2StageID[sec])
        
        # relate Split_Point with Array2StageID.
        for i in range(Num_of_App):
            for op in range(len(App2Operator[i])):
                opp = App2Operator[i][op]
                print("asd123www", op, Operator2Arrays[op][-1])
                m.addGenConstrIndicator(Split_Point[i][op], True, Array2StageID[Operator2Arrays[opp][-1]] <= Stage_Max - 1)
        

        # objective: minimize the flow size.
        objective_expr = []
        for i in range(Num_of_App):
            Num_of_Op = len(App2Operator[i])
            for op in range(Num_of_Op - 1):
                objective_expr.append((Split_Point[i][op] - Split_Point[i][op + 1]) * Flow[i][op])
            objective_expr.append(Split_Point[i][Num_of_Op - 1] * Flow[i][Num_of_Op - 1])
        m.setObjective(sum(objective_expr), GRB.MINIMIZE)

        m.optimize()
        print('Obj:', m.objVal)
        for v in m.getVars():
            # if 'InDataPlane' in v.varName:
            print(v.varName, v.x)

    except GurobiError:
        print('Error reported', GurobiError.message)


if __name__ == '__main__':
    Flow = [[5, 3, 2, 1] , [3, 2]]
    App2Operator = [[0, 1, 2, 3] , [0, 2]]
    Operator2Arrays = [[0], [1], [2, 3, 4], [5]]
    Arrays_ALU = [0, 1, 3, 3, 3, 1]
    Arrays_Memo = [0, 4096, 2048, 2048, 2048, 4096]

    # Flow = [[3, 2]]
    # App2Operator = [[0, 2]]
    # Operator2Arrays = [[0], [1], [2, 3, 4], [5]]
    # Arrays_ALU = [0, 1, 3, 3, 3, 1]
    # Arrays_Memo = [0, 4096, 2048, 2048, 2048, 4096]
    solve_lp(Flow, App2Operator, Operator2Arrays, Arrays_ALU, Arrays_Memo)