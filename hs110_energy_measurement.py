#!/usr/bin/env python3

import socket
import argparse
import subprocess
import os, re, threading
import time
from timeit import default_timer as timer

from tools.measures import Measures
import struct

import math

def encrypt(request):
    key = 171
    plainbytes = request.encode()
    buffer = bytearray(struct.pack(">I", len(plainbytes)))

    for plainbyte in plainbytes:
        cipherbyte = key ^ plainbyte
        key = cipherbyte
        buffer.append(cipherbyte)

    return bytes(buffer)
    
def decrypt(ciphertext):
    key = 171
    buffer = []
    for cipherbyte in ciphertext:
        plainbyte = key ^ cipherbyte
        key = cipherbyte
        buffer.append(plainbyte)

    plaintext = bytes(buffer)

    return plaintext.decode()

class energy_tool():
    def __init__(self, ip, port, number_measures):
        self.sock_tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.sock_tcp.connect((ip, port))
        self.energy_command = '{"emeter":{"get_realtime":{}}}'
        self.regexp_power = re.compile('.*"power_mw":(\d*)')
        self.current_energy = 0.0
        self.ref_power = 0.0
        self.measures = Measures(number_measures)

    def get_power(self):
        self.sock_tcp.send(encrypt(self.energy_command))
        data = self.sock_tcp.recv(2048)
        emeter_read = decrypt(data[4:])
        power = float(self.regexp_power.match(emeter_read).groups()[0]) * 0.001
        self.measures.add_measure(power - self.ref_power)
        return power

    def trigger(self):
        time.sleep(0.5)
        self.get_power()


class timer_tool(threading.Thread):
    def __init__(self, energy_tool):
        threading.Thread.__init__(self)

        self.energy_tool = energy_tool
        self.stop_event = threading.Event()

    def stop(self):
        self.stop_event.set()

    def stopped(self):
        return self.stop_event.is_set()

    def run(self):
        self.energy_tool.tick = timer()
        while not self.stopped():
            self.energy_tool.trigger()

parser = argparse.ArgumentParser(description="Software Energy measurements with TP-Link Wi-Fi Smart Plug Client")
parser.add_argument("-t", "--target", metavar="<hostname>", required=True, help="Target hostname or IP address")
parser.add_argument("-m", "--number_measures", metavar="<number_measures>", help="Number of measures")
args = parser.parse_args()

FNULL = open(os.devnull, 'w')

et = energy_tool(args.target, 9999, 10)
measure_timer = timer_tool(et)
measure_timer.start()
_ = input("press key to exit")
measure_timer.stop()
measure_timer.join()
print(Measures.Get_header())
print(et.measures)

FNULL.close()
et.sock_tcp.close()

