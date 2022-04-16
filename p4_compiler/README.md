# Operator 参数定义



## filter

```python
Filter('low_bit', '32w0', '==')
```

`参数1`指定作用的`value`域.

 `参数2`指定比较的常数.

`参数3`指定`op`, 目前支持 `>, <, >=, <=, ==`.



## map

```python
Map('origin', 'low_bit', '32w7', '=')
```

`参数1`指定运算的`value`域.

`参数2`指定新增加的`value`域.

`参数3`指定运算常数, 或指定`random`.

`参数4`指定`op`, 目前支持 `+, -, &, | , ^, =`.

**特殊地**: 若`参数4`为`=`, 则将`参数3`的值赋给`参数2`, 若`参数3`为`random`代表增加一个随机数.



## reduce 

```python
Reduce('origin', 'sum', 3, 4096)
```

`参数1`指定运算的`value`域.

`参数2`指定操作, 目前支持`sum, max, min`.

`参数3`指定使用的`sketch`的深度.

`参数4`指定使用的`sketch`的宽度.

<span style="color:red;"> 问题1: 目前reduce会只保留一个value结果, 这样做不了count, 需要修改.</span>

<span style="color:red;"> 问题2: 用户指定与autoConfig矛盾, 之后需要去掉.</span>



## join

待定义... prototype 已有.


