import os
from tempfile import TemporaryFile
from subprocess import check_output, CalledProcessError
import time
import inspect
import ctypes
import logging
from config.config import conf


def get_out(args):
    with TemporaryFile() as t:
        try:
            out = check_output(args, stderr=t, shell=True)
            return True, out
        except CalledProcessError as e:
            t.seek(0)
            print (str(args), str(e.returncode), t.read())
            return False, t.read()


def write_to_file(path, content):
    with open(path, 'w') as fp:
        fp.write(content)


def get_in(args, input_data):
    with TemporaryFile() as t:
        try:
            t.write(input_data)
            out = check_output(args, stdin=t, shell=False)
            return True, out
        except CalledProcessError as e:
            t.seek(0)

            return False, t.read()


def get_logger(name, loglevel):

    logger = logging.getLogger(name)
    logger.setLevel(loglevel)
    date = time.strftime("%y%m%d%H%M%S", time.localtime())
    if not os.path.exists(conf["log_path"]):
        os.mkdir(conf["log_path"])

    logdir = os.path.join(conf["log_path"], name)
    if not os.path.exists(logdir):
        os.mkdir(logdir)

    fh = logging.FileHandler(os.path.join(logdir, date + ".log"))
    fh.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
    fh.setFormatter(formatter)
    logger.addHandler(fh)

    return logger

def async_raise(tid, exctype):
    """Raises an exception in the threads with id tid"""
    if not inspect.isclass(exctype):
        raise TypeError("Only types can be raised (not instances)")
    res = ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(tid), ctypes.py_object(exctype))
    if res == 0:
        raise ValueError("invalid thread id")
    elif res != 1:
        # """if it returns a number greater than one, you're in trouble,
        # and you should call it again with exc=NULL to revert the effect"""
        ctypes.pythonapi.PyThreadState_SetAsyncExc(tid, None)
        raise SystemError("PyThreadState_SetAsyncExc failed")
