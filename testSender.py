import ctypes
import time


appName = 'wordCount'
QID = 1

libPath = 'speed_test/build/libSender.so'
lib = ctypes.CDLL(libPath)

lib.sender.restype = ctypes.c_void_p
lib.sender.argtypes = [ctypes.c_wchar_p, ctypes.c_uint32, ctypes.c_uint32, ctypes.c_uint32]

st = time.time()
lib.sender(ctypes.c_wchar_p(appName), ctypes.c_uint32(1000000000), ctypes.c_uint32(5), ctypes.c_uint32(QID))



print("------Finish sending-------")
#/home/bfsde/bf-sde-9.6.0/build/p4-build/SketchStream_reduce/tofino/SketchStream_reduce/manifest.json