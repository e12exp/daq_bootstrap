#!/bin/bash

if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
SESSION="daq_${USER}_${HOSTNAME}"

# Check if TMUX is already running and has session
if $(tmux has -t $SESSION); then
	tmux -2 attach -t $SESSION
	exit
fi

# Start and setup new session

WD=$(echo $PWD | sed -e "s#$HOME##g" | sed -e "s#^/##g")

scripts/install.sh $HOSTNAME

tmux -2 new-session -d -s $SESSION
#tmux new-window -t $SESSION:1 -n "DAQ $HOSTNAME"
tmux split-window -v
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 2
tmux split-window -h

tmux select-pane -t 0
tmux send-keys "ssh $HOSTNAME" C-m
tmux send-keys "cd $WD/mbs" C-m
# tmux send-keys "resl" C-m
# tmux send-keys "./ini_chane 0 1" C-m
# tmux send-keys "./ini_chane 0 1" C-m
# tmux send-keys "mbs" C-m
tmux send-keys "../scripts/runmbs.csh" C-m
tmux send-keys "@startup" C-m

tmux select-pane -t 2
tmux send-keys "ssh $HOSTNAME" C-m
tmux send-keys "sleep 5 && rate" C-m

tmux select-pane -t 3
tmux send-keys "# Reserved for ucesb event builder" C-m

tmux select-pane -t 0

tmux select-pane -t 1
# tmux send-keys "ssh $HOSTNAME" C-m
# tmux send-keys "cd $WD/mbs" C-m
# tmux send-keys "./setpar febex.db" C-m

tmux send-keys "cd mbs && ../scripts/easy.sh $HOSTNAME" C-m

tmux -2 attach -t $SESSION
