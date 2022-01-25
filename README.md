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
