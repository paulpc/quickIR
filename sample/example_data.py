#!/usr/bin/python
import socket


TCP_IP = '127.0.0.1'
TCP_PORT = 1514
BUFFER_SIZE = 1024
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((TCP_IP, TCP_PORT))
with open('out.json','r') as outjson:
    for line in outjson:
        s.send(line)
        #data = s.recv(BUFFER_SIZE)
s.close()
