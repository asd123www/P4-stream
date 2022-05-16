# 模拟器版本
## 布局

*   应用在`app`里

*   p4程序在`p4`里
    *   每个p4程序需提供`.p4`代码和`command.py`（用于配置p4内的table）



## 测试

在`p4-stream`文件夹下

```shell
export PYTHONPATH=$PWD
sudo python3 app/wordcount/wordcount_raw.py
```

## 新增应用

```python
class CustomQuery(object):
    def emitter() 		# 用于解析p4发来的包
    def sender() 		# 用于生成发给p4的包
    def spark_build() 	# 用于添加spark的流程
    def output()		# 最后spark的输出会调用此函数（暂时没用）

conf["p4_conf"]["app"]  # 本应用所用到的p4程序
Runtime(conf, [queries])# 以这些应用运行
```


## 算子
| |Cheetah |NetAccel | SketchSteam |
| -- | --- | --- | ----|
|Distinct | Cache | | BloomFilter|
| Reduce (count) | CountMin | groupby(sum) | CountMin|
| join  | 2*pkts + BloomFilter |  | Join Chain|
| groupby(min/max)  | Min/Max Cache | | Min-Max Sketch |

## SketchStream算子API - 2022.5.16
|                         | API | Example |
| ----------------------- | ---- | ---- |
| Map                     | Custom | None |
| Filter                  | Custom | None |
| Reduce (count)          | 需指定一个32bit的value, 结果返回到相同field. | SketchStream_reduce(32w4096) func_1;                                    func_1.apply(hdr.kvs.val_word.val_word_1.data); |
| Join          | 需指定一个32bit的value, pkt有可能标记为drop. | SketchStream_join(32w4096) func_1;                                                     func_1.apply(hdr.kvs.val_word.val_word_1.data); |
| Distinct (Bloom filter) | 完全根据key, 因此不需要输入参数. | SketchStream_distinct(32w4096) func_1;                                          func_1.apply(); |
| Groupby (min/max)       | 需指定一个32bit的value, 结果返回到相同field. | SketchStream_groupby_max(32w4096) func_1;                                func_1.apply(hdr.kvs.key_word.key_word_1.data); |

## 算子的问题

加强原先的**map(fields, [expr])** 为**map(fields, [Ternary_expr])**. (海风学长建议)

**[Ternary_expr] = [field op constant] ? [Ternary_expr1]: [Ternary_expr2]**.

写成三元表达式的形式:

```python
# 设pkt个数为cnt.
# cnt \in [1,N_1] 一定sample.
# cnt \in [N_1, N_2] 以p_1的概率sample.
# cnt \in [N_2, ∞] 以p_2的概率sample.
# Threshold_i是 2^32 * p_i 上取整, 在monitor中算出来.
PacketStream.map(rd, "random")
						.map(cnt, "1")
            .reduce(cnt)
            .map(condition, [cnt <= N_1]?
                							1:
                							[cnt <= N_2]?
                								[rd <= Threshold_1]:
                								[rd <= Threshold_2])
            .filter([condition == 0])
```

翻译成**P4**代码:

实现思路: 

1. 保留之前将**最终结果**存在`hdr.values`中的实现, 目前有$8$个$32$bit数.
2. `ig_md`即`metadata`中保存中间结果, 例如下面的`ig_md.cnt_subN1`.

```c
control Condition_map(
		inout header_t hdr,
		inout metadata_t ig_md) {
  
    // 这里需要根据不同的condition计算出结果便于在 if else 中比较, 否则超过4byte+12bits的限制.
    // action里不能有依赖. !!: 比较容易的实现时每个action里面一条运算, 依赖交给compiler.
    action cal() {
        ig_md.cnt_subN1 = ig_md.cnt - N_1;
        ig_md.cnt_subN2 = ig_md.cnt - N_2;
        ig_md.rand_subTh1 = ig_md.rand - Threshold_1;
        ig_md.rand_subTh2 = ig_md.rand - Threshold_2;
    }

    apply {
        cal();
        // 三元表达式的形式比较容易翻译成如下代码.
        if (ig_md.cnt_subN1 <= 0) {
            ig_md.sgn = 32w1;
        } else {
            if (ig_md.cnt_subN2 <= 0) {
                if (ig_md.rand_subTh1 <= 0) {
                    ig_md.sgn = 32w1;
                } else {
                    ig_md.sgn = 32w0;
                }
            } else {
                if (ig_md.rand_subTh2 <= 0) {
                    ig_md.sgn = 32w1;
                } else {
                    ig_md.sgn = 32w0;
                }
            }
        }
    }
}
```


# 硬件版本

## 测试

*   p4_server负责接收monitor发来的p4代码并运行
*   emitter_server负责接收monitor发来的emitter格式并进行emit
*   sender负责发送数据
*   monitor负责管理整个系统，生成p4代码、spark代码、emitter格式

#### bf2

*   不需要进入venv环境
*   注意不要加sudo
*   `-d` 代表debug模式，这会跳过P4Generator
*   `-s` 是自定义的程序名后缀

```shell
PYTHONPATH=$PWD python3 src/p4_server.py -s zcq 
```

#### dl9

```shell
sudo PYTHONPATH=$PWD python3 src/emitter_server.py
```

#### dl10

```shell
sudo PYTHONPATH=$PWD python3 app/wordcount/perf_sender.py
```

在sender, emitter_server, p4_server都开始运行后，运行monitor
```shell
sudo PYTHONPATH=$PWD python3 app/wordcount/monitor.py
```
