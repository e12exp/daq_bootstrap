#!/usr/bin/python

import sys
from time import time

limit=100
lastt=time()
count=0


while 1:
    x=sys.stdin.readline()
    if not len(x):
        exit(0)
    count+=1
    if time()>=1+lastt:
        count=0
        lastt=time()
    if count<limit:
        sys.stdout.write(x)
    elif count==limit:
        print "[RATE LIMIT]"

