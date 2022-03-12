import ctypes

appName = 'wordCount'
QID = 1

libPath = 'speed_test/build/libSender.so'
lib = ctypes.CDLL(libPath)

lib.sender.restype = ctypes.c_void_p
lib.sender.argtypes = [ctypes.c_wchar_p, ctypes.c_uint64, ctypes.c_uint32]

lib.sender(ctypes.c_wchar_p(appName), ctypes.c_uint64(10), ctypes.c_uint32(QID))

print("Finish sending")