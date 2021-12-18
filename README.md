## 布局

*   应用在`app`里

*   p4程序在`p4`里
    *   每个p4程序需提供`.p4`代码和`command.py`（用于配置p4内的table）

>   目前只有`wordcount_raw`这一个应用和`simple_l3`这一个p4程序



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



