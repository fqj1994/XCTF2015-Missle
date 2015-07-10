#!/usr/bin/env python2

import os
import json

def checker(host, port, flag, team):
    ooo = json.dumps([host, port, flag, team]).encode('base64').replace('\n', '')
    xx = os.popen("echo " + ooo + " | base64 -d | /home/xctf/xctf-final-2015/scripts/service/missle/missle_checker.py " + team) 
    read_data = xx.read()
    ret = json.loads(read_data)
    xx.close()
    return ret
