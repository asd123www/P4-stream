import ctypes


signal = ctypes.c_int(0)



libPath = './speed_test/build/libReceiver.so'
mylib = ctypes.CDLL(libPath)

mylib.receiver.restype = None
mylib.receiver.argtypes = [ctypes.POINTER(ctypes.c_int32)] # 之后可能添加一下别的参数.

mylib.receiver(ctypes.pointer(signal))