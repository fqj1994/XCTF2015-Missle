#!/usr/bin/env python2
# coding: utf-8
import websocket
import random
import os
import json
import string
import requests
import subprocess
import hashlib
import traceback
import pty
import sys


teams = [u'217', u'******', u'0ops', u'L1ght', u'Dawn', u'Sigma', u'FlappyPig', u'Freed0m', u'4', u'ROIS', u'BambooFox', u'天枢', u'NPC']

dirs = os.path.dirname(os.path.realpath(__file__))

passwords = {
        }

def get_password_of_team(team):
    try:
        i = teams.index(team)
        password_of_team = os.popen("ssh root@172.16." + str(i + 1) + ".1 cat /root/xctf_missle_passwords | awk {'print $2'}").read().strip()
        assert len(password_of_team) > 0
        return password_of_team
    except Exception as e:
        return False 

sshs = ['172.16.' + str(i) +'.1' for i in range(1, 14)]
reverse_ports = range(500, 1000)


def checker(*kwargs):
    try:
        return real_checker(*kwargs)
    except Exception as e:
        return {'status': 'error', 'msg': 'Exception: ' + traceback.format_exc(e)}


def real_checker(host, port, flag, team):
    pwd = get_password_of_team(team)
    if not pwd:
        return {'status': 'error', 'msg': 'cannot get admin password.'}
    if hashlib.sha1(requests.get("http://" + host + ":" + str(port) + "/").text).hexdigest() != 'c303b8b8ab604d882dc90127e9a8b1a0cc310f9c':
        return {'status': 'down', 'msg': 'wrong launch UI'}
    tid = teams.index(team)
    user = 'admin'
    reverse_host = random.choice(sshs)
    reverse_port = random.choice(reverse_ports)
    target = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(20))
    ws = websocket.create_connection("ws://" + host + ":" + str(port) + "/missle")
    master, slave = pty.openpty()
    reverse_proxy = subprocess.Popen(["ssh",  "-q", "-R", str(reverse_port) + ":localhost:" + str(9100 + tid), "root@" + reverse_host],  stdout=open(subprocess.os.devnull, 'w'), stderr=open(subprocess.os.devnull, 'w'), stdin=slave, close_fds=True)
    sshd = os.popen(dirs + "/missle_sshd.erl " + flag + " " + str(9100 + tid), "r", 1)
    assert sshd.readline().strip() == 'ready'
    ws.send(json.dumps(
        [user, pwd, reverse_host, reverse_port, target]))
    first_status = ws.recv_data_frame()[1].data
    if first_status != "Request Received":
        sshd.close()
        reverse_proxy.kill()
        return {'status': 'down', 'msg': 'Checker cannot authenticate with the service.' + first_status + ' pwd:' + pwd}
    sshd_st = sshd.readline().strip()
    if sshd_st != 'ok':
        reverse_proxy.kill()
        return {'status': 'down', 'msg': sshd_st}
    else:
        rnd_suffix = sshd.readline().strip()
        missle_id = sshd.readline().strip()
        welcome_msg = 'Welcome to Missle ' + missle_id
        launch_msg = 'launch-missle '  + target
        success_msg = 'Successfully destroyed target ' + target + '-' + rnd_suffix
        if ws.recv_data_frame()[1].data.strip() != welcome_msg:
            reverse_proxy.kill()
            return {'status': 'down', 'msg': 'Wrong missle'}
        if ws.recv_data_frame()[1].data.strip() != launch_msg: 
            reverse_proxy.kill()
            return {'status': 'down', 'msg': 'What\'re you doing to the missle?'}
        if ws.recv_data_frame()[1].data.strip() != success_msg:
            reverse_proxy.kill()
            return {'status': 'down', 'msg': 'You destroyed a wrong target'}
        logs = requests.get("http://" + host + ":" + str(port) + "/log").text
        if success_msg in logs:
            reverse_proxy.kill()
            return {'status': 'up', 'msg': 'ok'}
        else:
            reverse_proxy.kill()
            return {'status': 'down', 'msg': 'log feature is not functioning.'}
    reverse_proxy.kill()
    return {'status': 'error', 'msg': 'unexpetected checking path.'}


if __name__ == "__main__":
    print json.dumps(checker(*json.loads(raw_input())))
