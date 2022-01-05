#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

if [[ "$#" -lt "0" ]]; then
	echo "Usage: $0 " >&2
	exit -1
fi

. config/local_settings.sh

HOSTNAME="$MBSPC"

test -z "$HOSTNAME" && echo "MBSPC not set in config/local_settings.sh"

SESSION="${HOSTNAME}_daq"

while [[ $(tput cols) -lt "120" ]]; do
	clear
	echo
	echo -e "\e[1;7mWarning\e[0;7m Your terminal has \e[1m$(tput cols)\e[0;7m columns.\e[0m"
	echo -e "It is recommented to run this program in a \e[1mmaximized\e[0m terminal\nwith at least 120 columns."
	echo "Please resize your terminal if possible."
	echo

	source scripts/menu.sh
	MENU_RETURN_ON_RESIZE=1
	menu "Retry" "Continue with current size" "Exit"

	case "$?" in
		[0-1])
			continue
			;;
		2)
			break
			;;
		3)
			exit
			;;
	esac
done

# Check if TMUX is already running and has session
if $(tmux has -t $SESSION); then
	tmux -2 attach -t $SESSION
	exit
fi

echo "trying to connect to host"


while ! ssh -o ConnectTimeout=5 -o PasswordAuthentication=no \
        -n ${HOSTNAME} /bin/true
do
    echo "host is not responding, still trying (^C to quit)"
    sleep 5
done

# Start and setup new session
WD=$(echo $PWD | sed -e "s#$HOME##g" | sed -e "s#^/##g")

#scripts/install.sh $HOSTNAME || exit $?

mkdir -p .run
rm -f .run/filename

tmux -2 new-session -d -s $SESSION
#tmux new-window -t $SESSION:1 -n "DAQ $HOSTNAME"
tmux split-window -v
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 2
tmux split-window -h

tmux select-pane -t 0
tmux send-keys "ssh $HOSTNAME" C-m
sleep 5
tmux send-keys "cd_current ; cd $HOSTNAME/daq_bootstrap/mbs" C-m
# tmux send-keys "resl" C-m
# tmux send-keys "./ini_chane 0 1" C-m
# tmux send-keys "./ini_chane 0 1" C-m
# tmux send-keys "mbs" C-m
tmux send-keys "alias mbs ../scripts/runmbs.bash" C-m
tmux send-keys "mbs" C-m
tmux send-keys "@startup" C-m

tmux select-pane -t 2
tmux send-keys "scripts/remote_rate.sh $HOSTNAME" C-m

tmux select-pane -t 3
tmux send-keys "# Reserved for ucesb event builder" C-m
tmux split-window -v
tmux select-pane -t 4
tmux send-keys "# Reserved for ucesb file output" C-m

tmux select-pane -t 1
# tmux send-keys "ssh $HOSTNAME" C-m
# tmux send-keys "cd $WD/mbs" C-m
# tmux send-keys "./setpar febex.db" C-m

tmux send-keys "cd mbs" C-m
tmux send-keys "../scripts/easy.sh $HOSTNAME" C-m

tmux -2 attach -t $SESSION
