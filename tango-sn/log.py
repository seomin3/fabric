import time

class logassist(object):
    def get_currenttime(self):
        return time.asctime(time.localtime(time.time()))
