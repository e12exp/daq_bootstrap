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

HOST="$1"
HOSTNO=$(echo $HOST | sed -E 's/x86l?-//g' )
# UCESB will serve on the following ports.
PORT_TRANS=$((  8000 + $((HOSTNO*10)) ))
PORT_STREAM=$(( 9000 + $((HOSTNO*10)) ))

mkdir -p .run

sleep 5

set -m

SLEEP=10

while true; do

        clear
        # we scan for stream server to get less ugly errors in mbs output
	# then we use the stream server
	echo "Waiting for mbs stream server..."
	while ! nc $HOST 6000 -q0 </dev/null  &>/dev/null ; do
		sleep $SLEEP
	done;

	echo "MBS transport server online, trying to start UCESB event-builder, trans:$PORT_TRANS and stream:$PORT_STREAM."
	# --eb-time-stitch=500
	# was --serve=stream --server=trans:6000 
	#
        . mbs/local_settings.sh # read ${WRTS_SUB_ID} from mbs configuration input
        ucesb/empty/empty --colour=yes --eventbuilder=${WRTS_SUB_ID} --eb-time-stitch=0 stream://$HOST --server=size=100Mi,trans:$PORT_TRANS --server=size=100Mi,stream:$PORT_STREAM 2>&1 |  scripts/rate-limit.py &
#	/u/land/landexp/202103_s455/califa_ucesb/empty/empty --califa=0xb00,91,10.99.2.27 trans://$HOST --server=trans:$PORT_TRANS --server=stream:$PORT_STREAM &
	PID=$!
	echo "$PORT_TRANS" > .run/eb.${HOST}.port
	echo "$PID" > .run/eb.${HOST}.pid
	fg
	wait $PID
	RET=$?

	if [[ "$RET" -ne "134" ]]; then
	    echo "Seems like the eventbuilder died or did not start correctly. I will retry in $SLEEP seconds."
	    sleep $SLEEP
	else
	    echo "TCP port $PORT_TRANS or $PORT_STREAM occupied, tidy up and I'll try again in $SLEEP seconds."
	    sleep $SLEEP
	fi
#	if [[ "$PORT" -ge "6012" ]]; then
#		echo "I tried 10 different ports now. I honestly don't think, that's the problem. Bailing out!"
#		exit $RET
#	fi
done
