#!/usr/bin/python

import sys

from time import time, sleep
from  fcntl import *
from termios import FIONREAD
import array
import ctypes
libc=ctypes.CDLL("libc.so.6")
read=libc.read

limit=100
lastt=time()
count=0

blen=200
c=array.array('I', [0])

stdin=sys.stdin.fileno()

while 1:
    if time()>=1+lastt:
        count=0
        lastt=time()

    if ioctl(sys.stdin.fileno(), FIONREAD, c)==-1:
        raise RuntimeError("ioctl failed")
    c[0]=max(c[0], 1)

    x=sys.stdin.read(c[0])
    if x=="":
        print("\nread failed, assuming EOF\n")
        exit(0)
    lines=x.split("\n")
    count-=1
    llen=len(lines)
    for i,l in enumerate(lines):
        count+=1
        if count<limit:
            nl=["\n", ""][i==llen-1]
            #nl="\n"
            #("%d, %d:"%(i, count))
            sys.stdout.write(l+nl)
        elif count==limit:
            sys.stdout.write("\n[RATE LIMIT]\n")
            count+=1 # do not repeat rate limit msg
        else:
            break
    sys.stdout.flush()
    
