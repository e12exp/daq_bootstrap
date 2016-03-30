#!/bin/bash

if [ "$#" -lt "1" ]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"

LASTMSG=""
LASTLOG=""

function log {
	TS=$(date)
	printf "[%s] %s\n" "$TS" "$*" >> easy.log

	if [ -n "$LASTLOG" ]; then
		LASTLOG="$LASTLOG\n"
	fi
	LASTLOG="${LASTLOG}${*}"
}

function logdo {
	log $@
	$@
}

function check_status {
	RUNNING=0

	PREFIX=$1
	PROC=$2

	if [[ -f ../.run/${PREFIX}.${HOSTNAME}.pid ]]; then
		PID=$(cat ../.run/${PREFIX}.${HOSTNAME}.pid)
		if [[ -e /proc/$PID ]]; then
			if [[ $(readlink /proc/$PID/exe) == *"$PROC"* ]]; then
				RUNNING=1
			fi
		fi
	fi

	return $RUNNING
}

function check_ucesb {
	check_status "eb" "/ucesb/empty/empty"
	RUNNING=$?
	if [[ "$RUNNING" -eq "0" ]]; then
		# ucesb not running => Start
		tmux select-pane -t 3
		tmux send-keys "scripts/eventbuilder.sh $HOSTNAME" C-m
	fi
}

if [[ $(locale charmap) == "UTF-8" ]]; then
	CHARSET="utf-8"
else
	CHARSET="other"
fi

case "$CHARSET" in
	"utf-8")
		BOXLT="\xe2\x95\x94"
		BOXRT="\xe2\x95\x97"
		BOXLB="\xe2\x95\x9a"
		BOXRB="\xe2\x95\x9d"
		BOXH="\xe2\x95\x90"
		BOXV="\xe2\x95\x91"

		BOXVSEPL="\xe2\x95\x9f"
		BOXVSEPR="\xe2\x95\xa2"

		LBOXH="\xe2\x94\x80"
		;;

	*)
		BOXLT="+"
		BOXRT="+"
		BOXLB="+"
		BOXRB="+"
		BOXH="-"
		BOXV="|"

		BOXVSEPL="|"
		BOXVSEPR="|"

		LBOXH="."
		;;
esac

function string_repeat {
	STR=$(echo -en "$1")
	N="$2"
	OUT="$3"

	for I in $(seq 1 $N); do
		eval "$OUT+=\"$STR\""
	done
}

function menu_headline {
	HEADLINE1=" Easy DAQ Control Interface "
	HEADLINE2=" $1 "
	LEN1=${#HEADLINE1}
	LEN2=${#HEADLINE2}
	if [[ "$LEN1" -gt "$LEN2" ]]; then
		LEN=$LEN1
		string_repeat " " $(($LEN1 - $LEN2)) HEADLINE2
	else
		LEN=$LEN2
		string_repeat " " $(($LEN2 - $LEN1)) HEADLINE1
	fi
	TOP="$BOXLT"
	BOTTOM="$BOXLB"
	MIDDLE="$BOXVSEPL"
	string_repeat "$BOXH" $LEN TOP
	string_repeat "$BOXH" $LEN BOTTOM
	string_repeat "$LBOXH" $LEN MIDDLE
	TOP+="$BOXRT"
	BOTTOM+="$BOXRB"
	MIDDLE+="$BOXVSEPR"
	echo -en "\e[31m${TOP}\n${BOXV}\e[1;39m${HEADLINE1}\e[0;31m${BOXV}\n${MIDDLE}\n${BOXV}\e[0;1;33m${HEADLINE2}\e[0;31m${BOXV}\n${BOTTOM}\e[0m\n\n"
}

function menu_daq {
	clear
	
	menu_headline "MBS (Data Acquistion)"

	OPTS=("Start Acquisition", "Stop Acquistion", "Restart", "Shutdown", "Return")
	
	select SEL in "${OPTS[@]}"; do

		tmux select-pane -t 0
		case "$REPLY" in

		1)
			LASTMSG="Sent 'sta ac' to MBS"
			tmux send-keys "sta ac" C-m
			log "mbs> sta ac"
			check_ucesb
			;;

		2)
			LASTMSG="Sent 'sto ac' to MBS"
			tmux send-keys "sto ac" C-m
			log "mbs> sto ac"
			;;

		3)
			LASTMSG="Sent '@r' to MBS"
			tmux send-keys "@r" C-m
			log "mbs> @r"
			check_ucesb
			;;

		4)
			clear
			echo "Shutting down. Please wait..."

			tmux send-keys "@shutdown" C-m
			log "Shut down"
			sleep 5 
			tmux send-keys "quit" C-m
			tmux send-keys "resl" C-m
			sleep 5
			tmux send-keys "exit" C-m
			tmux send-keys "exit" C-m

			tmux select-pane -t 1
			tmux send-keys "exit" C-m
			tmux send-keys "exit" C-m

			tmux select-pane -t 1
			tmux send-keys C-c C-c C-c
			tmux send-keys "exit" C-m

			tmux kill-session
			exit	
			;;

		*)
			;;

		esac

		break

	done
}


function menu_triggers {
	echo
	echo "Which threshold do you want to set?"
	echo "Hint: Usually, you want to set the *GAMMA* threshold"
	echo

	OPTS=("Timing ('Low')", "Gamma ('High')", "Proton", "Never mind, get me back to the main menu!")

	THR=""
	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			THR="cfd_threshold_low"
			;;
		2)
			THR="cfd_threshold_high"
			;;
		3)
			THR="trigger_proton_threshold"
			;;		

		*)
			break
			;;
		esac

		echo
		echo "Aye! Please give me the desired value for the $THR threshold [0 - 4095, empty = cancel]:"
		read THRVAL

		if [ -z "$THRVAL" ]; then
			LASTMSG="Abort, abort, abort!"
			break
		fi

		if [ "$THRVAL" -gt "4095" ]; then
			LASTMSG="Invalid value! Try again if sober..."
			break
		fi

		logdo ./setpar febex.db set *.*.*.$THR $THRVAL
		LASTMSG="Aye aye cap'n! $THR threshold set to $THRVAL. Please restart DAQ to apply the new thresholds."

		break
	done
}

function menu_opmode {
	clear

	menu_headline "Select operation mode"

	OPTS=("Single Event - External trigger only", "Single Event - Self trigger enabled", "Single Event - External + internal coincidence", "Multi Event - Free running", "Ouh, actually, I don't think it was a good idea comming here... Could you bring me back to the main menu?")

	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			log "# Switching to single event mode without internal triggers"	
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 0
			logdo ./setpar febex.db set *.*.*.trigger_enable_walk_correction 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.cfd_delay 20
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 255
		
			LASTMSG="Switched to single event mode without internal triggers"
			;;

		2)
			log "# Switching to single event mode with internal trigger requests (gamma trigger)"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0x40
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 0
			logdo ./setpar febex.db set *.*.*.trigger_enable_walk_correction 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.cfd_delay 20
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 255

			LASTMSG="Switched to single event mode with internal trigger requests (gamma trigger)"
			;;

		3)
			log "# Switching to single event mode with external + internal trigger coincidence (gamma (trigger request) + timing thresholds)"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0x40
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x80
			logdo ./setpar febex.db set *.*.*.trigger_validation_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 1
			logdo ./setpar febex.db set *.*.*.trigger_enable_walk_correction 1
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.trigger_validation_delay 80
			logdo ./setpar febex.db set *.*.*.trigger_validation_gate_length 120
			logdo ./setpar febex.db set *.*.*.cfd_delay 60
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 199

			LASTMSG="Switched to single event mode with external + internal trigger coincidence (gamma (trigger request) + timing thresholds)"
			;;

		4)
			log "# Switching to free running multi event mode"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x80
			logdo ./setpar febex.db set *.*.*.trigger_validation_src 0x100
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 1
			logdo ./setpar febex.db set *.*.*.trigger_enable_walk_correction 1
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.trigger_validation_delay 80
			logdo ./setpar febex.db set *.*.*.trigger_validation_gate_length 120
			logdo ./setpar febex.db set *.*.*.cfd_delay 60
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 199

			LASTMSG="Switched to free running multi event mode"
			;;

		*)
			break
			;;

		esac

		LASTMSG="$LASTMSG\nRemember to restart the DAQ to apply the changes."

		break
	done
}

function menu_parameters {
	clear

	menu_headline "Parameters"

	OPTS=("Set Operation Mode", "Set Trigger Thresholds", "Expert: Start ./setpar to manually set parameters")

	if [ -f .febex.db.backup ]; then
		OPTS+=("Recover last febex.db")
		RECOVER=true
	else
		RECOVER=false
	fi

	OPTS+=("Return")

	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			menu_opmode
			;;

		2)
			menu_triggers
			;;

		3)
			log "# Caution! Wannabe 'Expert' around! Manually setting parameters..."
			./setpar febex.db list > ._setpar_before
			clear
			echo "To the 'expert': Type 'help' to see available commands, 'exit' to return to main menu"
			echo
			cp febex.db ._febex.db.backup
			logdo ./setpar febex.db
			./setpar febex.db list > ._setpar_after
			log "# Start of diff between old and new config..."
			DIFF=$(diff -u0 ._setpar_before ._setpar_after)
			if [ -z "$DIFF" ]; then
				log "# No changes"
				LASTMSG="No changes were made. Good boy!"
				rm ._febex.db.backup
			else
				echo "$DIFF" >> easy.log
				mv ._febex.db.backup .febex.db.backup
				LASTMSG="The original febex.db has been backed up as '.febex.db.backup'... Just in case... You may recover it (if needed) in the parameters menu."
			fi
			rm -f _.setpar_before _.setpar_after
			log "# ...End of diff"
			;;

		4)
			if $RECOVER; then
				log "# Recovering last febex.db"
				logdo mv .febex.db.backup febex.db
				LASTMSG="Recovered last febex.db"
			fi
			;;
		*)
			;;
		
		esac

		break		

	done
}

function create_default_config {
	clear

	echo "Before we can start, I've got some simple questions."

	while true; do
		echo
		echo "How many FEBEX crates are you using? [1 - 4, default: 1]"
	
		read -ei 1 NCRATES
		if [ -z "$NCRATES" ]; then
			NCRATES=1
		fi
	
		if [ "$NCRATES" -lt "1" -o "$NCRATES" -gt "4" ]; then
			echo "I'm expecting a number between 1 and 4."
			continue
		fi

		break
	done

	for I in $(seq 1 $NCRATES); do
		IDX=$(($I - 1))
		
		while true; do
			echo
			echo "How many FEBEX modules are installed in crate $I (SFP $IDX)? [1 - 16, default: 1]"

			read -ei 1 NFEBEX
			if [ -z "$NFEBEX" ]; then
				NFEBEX=1
			fi

			if [ "$NFEBEX" -lt "1" -o "$NFEBEX" -gt "16" ]; then
				echo "I'm expecting a number between 1 and 16."
				continue
			fi

			NFEB[$IDX]=$NFEBEX
			break
		done
	done

	echo
	echo "Your configuration will consist of $NCRATES crate(s)."
	for I in $(seq 0 $(($NCRATES - 1))); do
		echo "  ${NFEB[$I]} card(s) in crate $(($I + 1))"
	done

	echo
	echo "Is this correct, do you want to continue?"

	OPTS=("Yes - Proceed to create configuration.", "No - Ask me again!", "Nah - Just take me to the main menu.")
	select SEL in "${OPTS[@]}"; do
		case "$REPLY" in
			1)
				# Yeah, let's do this!
				log "# Creating default configuration"
				logdo cp ../scripts/.febex.db.factory febex.db
				# There already is one SFP in the default config
				if [ "$NCRATES" -gt 1 ]; then
					logdo ./setpar febex.db add sfp $(($NCRATES - 1))
				fi
				for I in $(seq 0 $(($NCRATES - 1))); do
					if [ "$I" -eq "0" ]; then
						# There already is one module on SFP 0 in the default config
						NFEB[$I]=$((${NFEB[$I]} - 1))
					fi
					if [ "${NFEB[$I]}" -gt "0" ]; then
						logdo ./setpar febex.db cp module 0 0 $I ${NFEB[$I]}
					fi
				done

				LASTMSG="Default configuration created.\nOperation mode: Free running multi event readout.\n\nYou may now start the data acquistion."
				;;

			2)
				create_default_config
				;;
			3)
				;;

			*)
				echo "Please select one of the options above"
				echo
				continue
				;;
		esac

		break
	done
	
}

function menu_file {
	clear

	menu_headline "File Output"

	check_status "fo" "/ucesb/empty/empty"
	FILE_OPEN=$?

	FILENAME=$(cat ../.run/filename 2>/dev/null)
	mkdir -p ../data
	if [[ -z "$FILENAME" ]]; then
		TS=$(date "+%Y-%d-%m_%H-%M")
		FILENAME="data/${TS}_0000.lmd"
	fi

	if [[ "$FILE_OPEN" -eq "1" ]]; then
		# File output is currently active
		echo -e "\e[7mFile open:\e[0;1m $FILENAME\e[0m\n"
		echo

		OPTS=("Close file", "Return")
		select SEL in "${OPTS[@]}"; do
			case "$REPLY" in
				1)
					break
					;;
				2)
					return
					;;
				3)
					continue
					;;
			esac	
		done

		log "# Closing output file"

		tmux select-pane -t 4
		tmux send-keys C-c

		LASTMSG="Output file closed"
	else
		# No file is currently open
		echo -e "\e[7mFile closed\e[0m"
		echo

		OPTS=("Open output file", "Return")
		select SEL in "${OPTS[@]}"; do
			case "$REPLY" in
				1)
					break
					;;

				2)
					return
					;;
				*)
					continue
					;;
			esac
		done

		echo "Enter filename to write to [$FILENAME]"
		read -ei "$FILENAME" FNAME
		if [[ -n "$FNAME" ]]; then
			FILENAME=$FNAME
		fi
		echo "$FILENAME" > ../.run/filename

		PORT=$(cat ../.run/eb.${HOSTNAME}.port)
	
		tmux select-pane -t 4
		tmux send-keys "scripts/fo.sh $PORT $HOSTNAME" C-m

		log "# Opened file $FILENAME"
		LASTMSG="File output started to \e[1m${FILENAME}\e[0m"
	fi	
}

##############################
# Main
##############################

mkdir -p .run

if [[ ! -f febex.db ]]; then
	clear

	menu_headline "Welcome to the Easy DAQ control interface"

	echo "There seems to be no configuration file, yet."
	echo "Do you want to create a default configuration file?"
	echo
	
	OPTS=("Yes", "No")

	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

			1)
				create_default_config
				break
				;;

			2)
				break
				;;

			3)
				echo "Please select yes or no."
				echo
				;;

		esac

	done
fi


while true; do

	clear

	menu_headline "Main Menu"

	if [ -n "$LASTLOG" ]; then
		HEADLINE=""
		string_repeat "$LBOXH" 10 HEADLINE
		HEADLINE+=" Executed command line(s) "
		string_repeat "$LBOXH" 10 HEADLINE
		LEN=${#HEADLINE}
		echo $HEADLINE
		echo -e "\e[2m$LASTLOG\e[0m"
		HEADLINE=""
		string_repeat "$LBOXH" $LEN HEADLINE
		echo $HEADLINE
		echo
	fi

	if [ -n "$LASTMSG" ]; then
		echo -e "$LASTMSG"
		echo
	fi


	LASTMSG=""
	LASTLOG=""

	OPTS=("MBS: Start/Stop Acquisition, ...", "Parameters", "Open/Close file", "Quit")

	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			menu_daq
			;;

		2)
			menu_parameters
			;;

		3)
			menu_file
			;;

		4)
			exit
			;;

		esac

	tmux select-pane -t 1

	break

	done

done




