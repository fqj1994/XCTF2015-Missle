import websocket
import random
import os
import json
import string
import requests
import subprocess
import hashlib

passwords = {
        "self": "123456"
        }

sshs = [] # 'IPs'
reverse_ports = [9000:9100]


def checker(*kwargs):
    try:
        return real_checker(*kwargs)
    except Exception as e:
        return {'status': 'error', 'msg': 'Exception: ' + str(e)}


def real_checker(host, port, flag, team):
    if hashlib.sha1(requests.get("http://" + host + ":" + str(port) + "/").text).hexdigest() != 'c303b8b8ab604d882dc90127e9a8b1a0cc310f9c':
        return {'status': 'down', 'msg': 'wrong launch UI'}
    user = 'admin'
    pwd = passwords[team]
    reverse_host = random.choise(sshs)
    reverse_port = random.choice(reverse_ports)
    target = ''.join(random.choice(string.ascii_uppercase + string.digits) for _ in range(20))
    ws = websocket.create_connection("ws://" + host + ":" + str(port) + "/missle")
    reverse_proxy =subprocess.Popen("ssh -R 9999:localhost:" + str(reverse_port) + " root@" + reverse_host)
    sshd = os.popen("./missle_sshd.erl " + flag, "r", 1)
    assert sshd.readline().strip() == 'ready'
    ws.send(json.dumps(
        [user, pwd, reverse_host, reverse_port, target]))
    first_status = ws.recv_data_frame()[1].data
    if first_status != "Request Received":
        sshd.close()
        reverse_proxy.kill()
        return {'status': 'down', 'msg': 'Checker cannot authenticate with the service.'}
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
    print checker("127.0.0.1", 20001, "9999", "self")
