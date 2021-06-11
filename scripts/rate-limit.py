#!/usr/bin/python

import sys
from time import time, sleep
from  fcntl import *
from termios import FIONREAD
import array
limit=100
lastt=time()
count=0


    
while 1:
    if time()>=1+lastt:
        count=0
        lastt=time()
    c=array.array('I', [0])
    if ioctl(sys.stdin.fileno(), FIONREAD, c)==-1:
        raise RuntimeError("ioctl failed")
    if c[0]==0:
        sleep(0.1)
        continue
    x=sys.stdin.read(c[0])
    if not len(x): # EOF
        exit(0)
    lines=x.split("\n")
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
        else:
            break
    sys.stdout.flush()
    
