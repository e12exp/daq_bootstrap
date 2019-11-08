#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

# HTT haxx: Don't look for open ports, this thing must run where intended.
# -- okay, hated the port loop search anyhow. --pk

if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
# UCESB will serve on the following ports.
PORT_TRANS="8000"
PORT_STREAM="8002"

mkdir -p .run

sleep 5

set -m

while true; do

        clear
        # we scan for stream server to get less ugly errors in mbs output
	# then we use the stream server
	echo "Waiting for mbs stream server..."
	while ! nc $HOSTNAME 6002 -q0 </dev/null  &>/dev/null ; do
		sleep 10
	done;

	echo "MBS transport server online, trying to start UCESB event-builder, trans:$PORT_TRANS and stream:$PORT_STREAM."
	# --eb-time-stitch=500
	# was --serve=stream --server=trans:6000 
	#
	ucesb/empty/empty --eventbuilder --eb-time-stitch=0 trans://$HOSTNAME --server=trans:$PORT_TRANS --server=stream:$PORT_STREAM &
	PID=$!
	echo "$PORT_TRANS" > .run/eb.${HOSTNAME}.port
	echo "$PID" > .run/eb.${HOSTNAME}.pid
	fg
	wait $PID
	RET=$?

	# Return code 134 means: Socket in use => Try again with different port
	if [[ "$RET" -ne "134" ]]; then
	    echo "Seems like the eventbuilder died or did not start correctly. I will retry in 10 seconds."
	    sleep 10
	else
#	    echo "TCP port $PORT looks like it was in use, trying another one."
#	    PORT=$(($PORT+1))
	    echo "TCP port $PORT_TRANS or $PORT_STREAM occupied, tidy up and I'll try again in 10 seconds."
	    sleep 10
	fi
#	if [[ "$PORT" -ge "6012" ]]; then
#		echo "I tried 10 different ports now. I honestly don't think, that's the problem. Bailing out!"
#		exit $RET
#	fi
done
