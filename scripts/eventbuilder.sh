#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
PORT="6002"

mkdir -p .run

sleep 5

set -m

while true; do

    # note: 6002 is the mbs server port, while $PORT is the ucesb port
    clear
    echo "Waiting for mbs stream server ..."
    while ! nc $HOSTNAME 6002 -q0 </dev/null  &>/dev/null ; do
	sleep 10
    done;
    
	echo "mbs stream server is online. Trying to start ucesb eventbuilder on port $PORT"
	ucesb/empty/empty --eventbuilder stream://$HOSTNAME --server=stream:$PORT &
	PID=$!
	echo "$PORT" > .run/eb.${HOSTNAME}.port
	echo "$PID" > .run/eb.${HOSTNAME}.pid
	fg
	wait $PID
	RET=$?

	# Return code 134 means: Socket in use => Try again with different port

	if [[ "$RET" -ne "134" ]]; then
	    echo "Seems like the eventbuilder died or did not start correctly. I will retry in 10 seconds."
	    sleep 10
	else
	    echo "TCP port $PORT looks like it was in use, trying another one."
	    PORT=$(($PORT+1))
	fi


	if [[ "$PORT" -ge "6012" ]]; then
		echo "I tried 10 different ports now. I honestly don't think, that's the problem. Bailing out!"
		exit $RET
	fi

done

