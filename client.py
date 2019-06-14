
# An example script to connect to Google using socket 
# programming in Python 
import socket # for socket 
import sys

import struct

import communication as cm

try: 
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM) 
    print("Socket successfully created")
except socket.error as err: 
    print("socket creation failed with error %s" %(err))
  
# default port for socket 
port = 8009
  
try: 
    host_ip = socket.gethostbyname(sys.argv[1]) 
except socket.gaierror: 
    # this means could not resolve the host 
    print("there was an error resolving the host")
    sys.exit()

s.connect((host_ip, port)) 
  
# print("Wait for server answer")
# reply = s.recv(1024)
# print("length reply = " + str(len(reply)))
# str_reply = str(struct.unpack('<6s', reply[0:6])[0])
# print("Server said: " + str_reply)

s.send(struct.pack('<B', cm.Command.START))

reply = s.recv(1024)
cmd = struct.unpack('<B', reply)

if cmd == cm.Command.ACK:
	print("server ack start")
	
s.send('Voici mon test\0'.encode())

reply = s.recv(1024)
cmd = struct.unpack('<B', reply)

if cmd == cm.Command.ACK:
	print("server ack start")
