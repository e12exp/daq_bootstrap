#!/bin/bash

BALANCER_PORT=8010
NUM_SORTERS=4
SORTER_PORT_START=9200


if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
# UCESB will serve on the following ports.
PORT_TRANS="8000"
PORT_STREAM="8002"

FOREVER=$(dirname $0)/forever.sh

tmux new-window -n "parallel califa eventbuilder"
tmux split-window -v
tmux split-window -v
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2 # lower middle
tmux split-window -h
tmux select-pane -t 1 # upper middle
tmux split-window -h

#   0: load balancer
#   1     |      2
#   3     |      4
#   5: merger

SORTERS=""
tmux select-pane -t 0 # load balancer
tmux send-keys "$FOREVER ucesb/empty/empty stream://$1 --server=trans:${BALANCER_PORT},sendonce" C-m
sleep 10
for i in $(seq 1 4)
do
    tmux select-pane -t $i
    PORT=$(( ${SORTER_PORT_START} + $i -1 ))
    tmux send-keys "$FOREVER ucesb/empty/empty --eventbuilder --eb-time-stitch=0 trans://localhost:${BALANCER_PORT} --server=trans:$PORT" C-m
    SORTERS="$SORTERS trans://localhost:${PORT}"
done
tmux select-pane -t 5
tmux send-keys "$FOREVER ucesb/empty/empty --io-error-fatal --merge=wr,4 $SORTERS --server=stream:${PORT_STREAM} --server=trans:${PORT_TRANS}" C-m

