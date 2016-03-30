#!/bin/bash

set -m

FILENAME=$(cat .run/filename)
HOSTNAME="$2"
PORT="$1"

ucesb/empty/empty stream://localhost:$PORT --output=size=1024M,newnum,wp,$FILENAME &
PID=$!

echo "$PID" > .run/fo.${HOSTNAME}.pid

fg

