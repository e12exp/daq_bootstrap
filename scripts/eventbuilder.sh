#!/bin/bash

if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
PORT="6002"

sleep 5

while true; do

	echo "Trying to start ucesb eventbuilder on port $PORT"
	ucesb/empty/empty --eventbuilder stream://$HOSTNAME --server=stream:$PORT
	RET=$?

	# Return code 134 means: Socket in use => Try again with different port

	if [[ "$RET" -ne "134" ]]; then
		break
	fi

	PORT=$(($PORT+1))

	if [[ "$PORT" -ge "6012" ]]; then
		echo "I tried 10 different ports now. I honestly don't think, that's the problem. Bailing out!"
		exit $RET
	fi

done

