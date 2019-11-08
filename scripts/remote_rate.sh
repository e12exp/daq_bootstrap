#!/bin/bash

if test "$#" -ne 1
then
   echo "usage: $0 HOSTNAME"
   exit 1
fi

while true ; 
do
    ssh -o ServerAliveInterval=1 -o PasswordAuthentication=No -tt $1 <<<"rate ; exit"
    echo "restarting rate monitor in 10s"
    sleep 10
done
