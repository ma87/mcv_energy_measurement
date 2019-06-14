
# first of all import the socket library 
import socket
import struct
from subprocess import Popen, PIPE

import communication as cm

import argparse
import time
import sys
import os

parser = argparse.ArgumentParser(description="Software Energy measurements with TP-Link Wi-Fi Smart Plug Client")
parser.add_argument("-t", "--time", metavar="<resolution_time>", required=True, help="read power period")
parser.add_argument("-p", "--hwplug", metavar="<hw_plug>", nargs='+', required=False, help="activate hwplug measurement process")
parser.add_argument("-c", "--cpuplug", metavar="<cpu_plug>", nargs='+', required=True, help="cpuplug measurement process")
parser.add_argument("-f", "--folder", metavar="<folder>", required=True, help="folder to read command")

args = parser.parse_args()

#if args.hwplug:
#    print("hw plug args = {}".format("|".join(args.hwplug)))
#
#print("time = " + args.time)
#print("cpu args = " + "|".join(args.cpuplug))
#print("folder = " + args.folder) 

#path_executable = sys.argv[3:]
#test_name = sys.argv[1]
#power_plug_ip = sys.argv[2]

cpu_process_args = args.cpuplug
hw_process_args = args.hwplug

directory = args.folder
if not os.path.exists(directory):
  os.makedirs(directory)
  with open(os.path.join(directory, "results.csv"), "w") as result_f:
     result_f.write("USER,LANGUAGE,DAY,ENERGY_CONSUMED_CPU,ENERGY_CONSUMED_HW,TIME_ELAPSED\n")

if args.hwplug:
   measure_hw = False
else:
   measure_hw = True

cpu_process_args.append("-t")
cpu_process_args.append(args.time)
cpu_process_args.append("-f")
cpu_process_args.append(args.folder)
cpu_process_args.append("-e")

if hw_process_args:
    hw_process_args.append("-t")
    hw_process_args.append(args.time)
    hw_process_args.append("-f")
    hw_process_args.append(args.folder)
    hw_process_args.append("-e")

# next create a socket object 
s = socket.socket()
print("Socket successfully created")

# Next bind to the port 
# we have not typed any ip in the ip field 
# instead we have inputted an empty string 
# this makes the server listen to requests  
# coming from other computers on the network 
s.bind(('', cm.PORT))         
  
# put the socket into listening mode 
s.listen(1)
  
# a forever loop until we interrupt it or  
# an error occurs 

# Establish connection with client. 
c, addr = s.accept()
print ('Got connection from', addr)


def start_measure_process(path_executable, exe_name):
    path_executable.append(exe_name)
    print("execute cmd = " + "|".join(path_executable))
    
    p = Popen(path_executable, shell=False, stdout=PIPE, stdin=PIPE)
    result = p.stdout.readline().strip()
    print("executable returns " + str(result))
    path_executable.pop()

    return p


def stop_measure_process(p, time_elapsed):
    p.stdin.write(b'%.5f\n' % time_elapsed)
    p.stdin.flush()

    return p.stdout.readline().strip().decode()

def get_measure_process(p):

    energy_consumed = p.stdout.readline().strip().decode().split("=")[1]
    time_elapsed = p.stdout.readline().strip().decode().split("=")[1]
    splitted_exe_name = exe_name.split("_")

    return energy_consumed

with open(os.path.join(directory, "results.csv"), "a") as result_f:
   while True:
      print("wait for client request")
      request = c.recv(1024)
      print("receive request of len {}".format(len(request)))
      cmd = struct.unpack('<B', request)[0]

      if cmd == cm.Command.START:
         c.send(struct.pack('<B', cm.Command.ACK))
         exe_name = c.recv(1024).decode().rstrip()
         print("client send exe name = " + str(exe_name))
         
         if hw_process_args: 
             p_hw = start_measure_process(hw_process_args, exe_name)
         
         p_cpu = start_measure_process(cpu_process_args, exe_name)
         if hw_process_args:
             p_hw.stdin.write(b'0\n')
             p_hw.stdin.flush()

         c.send(struct.pack('<B', cm.Command.ACK))

      elif cmd == cm.Command.STOP:
         print("client send stop, ACK")
         c.send(struct.pack('<B', cm.Command.ACK))

         request = c.recv(1024)
         time_elapsed = struct.unpack('<d', request)[0]

         if "RESULTS" not in stop_measure_process(p_cpu, time_elapsed):
             print("error: cpu measurement process fail")
             exit(1)

         if hw_process_args and  "RESULTS" not in stop_measure_process(p_hw, time_elapsed):
             print("error: hw measurement process fail")
             exit(1)


         energy_consumed_cpu = get_measure_process(p_cpu)
         energy_consumed_hw  = 0
         if hw_process_args:
            energy_consumed_hw = get_measure_process(p_hw)

         splitted_exe_name = exe_name.split("_")

         if len(splitted_exe_name) == 3:
            print("User {} in {} for day {} consumed {} J in CPU and {} J in HW in {} ms".format(splitted_exe_name[0], splitted_exe_name[1], splitted_exe_name[2], energy_consumed_cpu, energy_consumed_hw, time_elapsed))
            result_f.write("{},{},{},{},{},{:.5f}\n".format(splitted_exe_name[0], splitted_exe_name[1], splitted_exe_name[2], energy_consumed_cpu, energy_consumed_hw, time_elapsed))
         else:
            print("error: cannot parse user, language names and day from executable name sent by client")

         #p_cpu.stdin.write(b'%.5f\n' % time_elapsed)
         #p_cpu.stdin.flush()

         #result = p_cpu.stdout.readline().strip().decode()
         #print("executable returns " + str(result))
         #if "RESULTS" in result:
         #   energy_consumed_cpu = p_cpu.stdout.readline().strip().decode().split("=")[1]
         #   energy_consumed_hw = 0.0
         #   if measure_hw:
         #       energy_consumed_hw = p_hw.stdout.readline().strip().decode().split("=")[1]
         #   time_elapsed = p_cpu.stdout.readline().strip().decode().split("=")[1]
         #   splitted_exe_name = exe_name.split("_")
         #   if len(splitted_exe_name) == 3:
         #      print("User {} in {} for day {} consumed {} J in {} ms".format(splitted_exe_name[0], splitted_exe_name[1], splitted_exe_name[2], energy_consumed, time_elapsed))
         #      result_f.write("{},{},{},{},{}\n".format(splitted_exe_name[0], splitted_exe_name[1], splitted_exe_name[2], energy_consumed, time_elapsed))
         #   else:
         #      print("error: cannot parse user, language names and day from executable name sent by client")

         c.close()
         c, addr = s.accept()

      elif cmd == cm.Command.STOP_SERVER:
         print("client send stop EXE, ACK")
         c.send(struct.pack('<B', cm.Command.ACK))
         break

print("server close")



