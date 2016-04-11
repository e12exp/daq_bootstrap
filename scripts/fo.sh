#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

set -m

FILENAME=$(cat .run/filename)
HOSTNAME="$2"
PORT="$1"

ucesb/empty/empty stream://localhost:$PORT --output=size=1024M,newnum,wp,$FILENAME &
PID=$!

echo "$PID" > .run/fo.${HOSTNAME}.pid

fg

