#!/usr/bin/env python2

import os
import json
import pty

def checker(host, port, flag, team):
    master, slave = pty.openpty()
    ooo = json.dumps([host, port, flag, team]).encode('base64').replace('\n', '')
    xx = os.popen("echo " + ooo + " | base64 -d | /home/xctf/xctf-final-2015/scripts/service/missle/missle_checker.py") 
    read_data = xx.read()
    ret = json.loads(read_data)
    xx.close()
    return ret
