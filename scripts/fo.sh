#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

set -m

cd $(dirname $0)/..

FILENAME=$HOME/califa/$(cat .run/filename)
mkdir -p $(dirname "$FILENAME")
MBSHOST="$2"
PORT="$1"

ucesb/empty/empty trans://lxir123:$PORT --output=size=1024M,newnum,wp,$FILENAME &
PID=$!

echo "$PID" > .run/fo.${MBSHOST}.pid
hostname -f > .run/fo.${MBSHOST}.host
fg

