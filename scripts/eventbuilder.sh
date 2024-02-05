#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################
EXE=$(readlink -f $0)
cd $(dirname $EXE)/..
TARGET=lxir133.gsi.de
if test "$(hostname)" != "$TARGET"
then
	echo "sshing to $TARGET"
	exec ssh -tt $TARGET $EXE $@
	exit $!
fi

if [[ "$#" -ne "0" ]]; then
	echo "Usage: $0 " >&2
	exit -1
fi

source config/local_settings.sh

ln -fvs  empty ucesb/empty/haecksler.${SIDE}

HOSTNO=$(echo $MBSPC | sed -E 's/x86l?-//g' )

if test -n "$EBSOURCE"
then
    IFS=":" read HOST SRCPORT <<<$EBSOURCE
else
    HOST="$MBSPC"
    SRCPORT=6002
fi
echo "Will read data from $HOST:$SRCPORT"
# UCESB will serve on the following ports.
PORT_TRANS=$((  8000 + ${HOSTNO} ))
PORT_STREAM=$(( 9000 + ${HOSTNO} ))

# as suggested by Hakan, keep OOM killer at bay

ulimit -d 10000000   # 10 GB
ulimit -v 10000000
ulimit -m 10000000

#ulimit -a            # just to print 

mkdir -p .run

sleep 5

set -m

SLEEP=10
TYPE=trans # alternative: stream

while true; do

        clear
        # we scan for stream server to get less ugly errors in mbs output
	# then we use the stream server
	echo "Waiting for mbs stream server..."
	while ! nc -vv -z $HOST $SRCPORT -q1 </dev/null  >/dev/null ; do
	    sleep $SLEEP
            echo .
	done;

	echo "MBS transport server online, trying to start UCESB event-builder, trans:$PORT_TRANS and stream:$PORT_STREAM."
	# --eb-time-stitch=500
	# was --serve=stream --server=trans:6000 
	#
        CMD="ucesb/empty/haecksler.${SIDE} --colour=yes --eventbuilder=${WRTS_SUB_ID}  trans://$HOST:$SRCPORT --server=size=100Mi,trans:$PORT_TRANS,flush=1 --server=size=100Mi,stream:$PORT_STREAM,flush=1"
	echo "running $CMD"
       	$CMD 2>&1 #|  scripts/rate-limit.py &
        # TODO: write output to file
        
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
