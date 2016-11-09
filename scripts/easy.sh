#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

source ../scripts/menu.sh

if [[ "$#" -lt "1" ]]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"

LASTMSG=""
LASTLOG=""

RUNLOGF=""
RUNDIR=""
RUNNUMBER=""

function log {
	TS=$(date)
	printf "[%s] %s\n" "$TS" "$*" >> easy.log

	if [[ -n "$RUNLOGF" ]]; then
	  printf "[%s] %s\n" "$TS" "$*" >> $RUNLOGF
	fi

	if [[ -n "$LASTLOG" ]]; then
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
	TWIDTH=$(tput cols)

#	HEADLINE1=" Easy DAQ Control Interface "
	HEADLINE1=" DUCK - \e[33mD\e[39mAQ \e[33mU\e[39mser-friendly \e[33mC\e[39montrol \e[33mK\e[39mit "
	HEADLINE2=" $1 "

	LEN1=$(( ${#HEADLINE1} - 48 ))
	LEN2=${#HEADLINE2}
	POS1=$(( ($TWIDTH - 1 - $LEN1) / 2 ))
	POS2=$(( ($TWIDTH - 1 - $LEN2) / 2 ))

	TOP="$BOXLT"
	BOTTOM="$BOXLB"
	MIDDLE="$BOXVSEPL"
	string_repeat "$BOXH" $(($TWIDTH - 2)) TOP
	string_repeat "$BOXH" $(($TWIDTH - 2)) BOTTOM
	string_repeat "$LBOXH" $(($TWIDTH - 2)) MIDDLE
	TOP+="$BOXRT"
	BOTTOM+="$BOXRB"
	MIDDLE+="$BOXVSEPR"

	echo -en "\e[31m${TOP}\n${BOXV}\e[1;39m\e[${POS1}G${HEADLINE1}\e[0;31m\e[${TWIDTH}G${BOXV}\n${MIDDLE}\n${BOXV}\e[0;1;33m\e[${POS2}G${HEADLINE2}\e[0;31m\e[${TWIDTH}G${BOXV}\n${BOTTOM}\e[0m\n\n"
}

function shutdown {
	echo
	echo "Shutting down. Please wait..."

	tmux select-pane -t 0
	tmux send-keys "@shutdown" C-m
	log "Shut down"
	sleep 5 
	tmux send-keys "quit" C-m
	tmux send-keys "resl" C-m
	sleep 5
#	tmux send-keys "exit" C-m
#	tmux send-keys "exit" C-m
#
#	tmux select-pane -t 1
#	tmux send-keys "exit" C-m
#	tmux send-keys "exit" C-m
#
#	tmux select-pane -t 1
#	tmux send-keys C-c C-c C-c
#	tmux send-keys "exit" C-m

	tmux kill-session
	exit	

}

function menu_shutdown {
	clear

	menu_headline "Shutdown"
	echo "Do you want to shut down the DAQ and exit?"
	echo

	menu "Yes - Complete shutdown!" "No - Only quit this program" "No - Return to main menu"
	case "$?" in
		1)
			shutdown
			;;
		2)
			exit
			;;
		3)
			;;
	esac
}

function menu_daq {
	clear
	
	menu_headline "MBS (Data Acquistion)"

	menu "Restart" "Start Acquisition" "Stop Acquistion" "Return"
	REPLY=$?
	
#	select SEL in "${OPTS[@]}"; do

		tmux select-pane -t 0
		case "$REPLY" in

		1)
			LASTMSG="Sent '@r' to MBS"
			tmux send-keys "@r" C-m
			log "mbs> @r"
			check_ucesb
			;;

		2)
			LASTMSG="Sent 'sta ac' to MBS"
			tmux send-keys "sta ac" C-m
			log "mbs> sta ac"
			check_ucesb
			;;

		3)
			LASTMSG="Sent 'sto ac' to MBS"
			tmux send-keys "sto ac" C-m
			log "mbs> sto ac"
			;;


		*)
			;;

		esac

#		break

#	done
}


function menu_triggers 
{
	clear

	menu_headline "Trigger Thresholds"

	echo "Which threshold do you want to set?"
	echo -e "\e[1mHint:\e[0m Usually, you want to set the \e[1mGAMMA\e[0m threshold"
	echo

  menu "Gamma ('High')" "Timing ('Low')" "Proton" "Never mind, get me back to the main menu!"
	REPLY=$?

	THR=""
#	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			THR="discr_threshold_gamma"
			;;
		2)
			THR="discr_threshold_timing"
			;;
		3)
			THR="discr_threshold_proton"
			;;		

		*)
			return
			;;
		esac

    echo
    echo "Aye!"
    # Print current threshold(s)
    ../scripts/printthr.sh $THR
    THRVAL=$(cat .thr.tmp)
    rm -f .thr.tmp

		echo
		echo -e "Please give me the desired value for the \e[1m$THR\e[0m threshold [0 - 4095, empty = cancel]:"
		read -ei "$THRVAL" THRVAL

		if [ -z "$THRVAL" ]; then
			LASTMSG="Abort, abort, abort!"
			return
		fi

		if [ "$THRVAL" -gt "4095" ]; then
			LASTMSG="Invalid value! Try again if sober..."
			return
		fi

		logdo ./setpar febex.db set *.*.*.$THR $THRVAL
		LASTMSG="Aye aye cap'n! $THR threshold set to $THRVAL. Please restart DAQ to apply the new thresholds."

#		break
#	done
}

function menu_opmode {
	clear

	menu_headline "Select operation mode"

	menu "Single Event - External trigger only" "Single Event - Self trigger enabled" "Single Event - External + internal coincidence" "Multi Event - Free running" "Free running single event trace mode (QPID probably not working!)" "Back to Main Menu" #"Ouh, actually, I don't think it was a good idea comming here... Could you bring me back to the main menu?"
	REPLY=$?

#	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			log "# Switching to single event mode without internal triggers"	
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 0
			logdo ./setpar febex.db set *.*.*.discr_enable_walk_correction 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.signal_delay 110
			logdo ./setpar febex.db set *.*.qpid_delay 100
			logdo ./setpar febex.db set *.*.num_events_readout 255
			logdo ./setpar febex.db set *.*.*.opmode_enable_trace 0
			
			LASTMSG="Switched to single event mode without internal triggers"
			;;

		2)
			log "# Switching to single event mode with internal trigger requests (gamma trigger)"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0x40
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 0
			logdo ./setpar febex.db set *.*.*.discr_enable_walk_correction 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.signal_delay 110
			logdo ./setpar febex.db set *.*.qpid_delay 100
			logdo ./setpar febex.db set *.*.num_events_readout 255
			logdo ./setpar febex.db set *.*.*.opmode_enable_trace 0
			
			LASTMSG="Switched to single event mode with internal trigger requests (gamma trigger)"
			;;

		3)
			log "# Switching to single event mode with external + internal trigger coincidence (gamma (trigger request) + timing thresholds)"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0x40
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x80
			logdo ./setpar febex.db set *.*.*.trigger_validation_src 0x30
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 1
			logdo ./setpar febex.db set *.*.*.discr_enable_walk_correction 1
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.trigger_validation_delay 80
			logdo ./setpar febex.db set *.*.*.trigger_validation_gate_length 120
			logdo ./setpar febex.db set *.*.*.signal_delay 150
			logdo ./setpar febex.db set *.*.qpid_delay 100
			logdo ./setpar febex.db set *.*.num_events_readout 199
			logdo ./setpar febex.db set *.*.*.opmode_enable_trace 0
			
			LASTMSG="Switched to single event mode with external + internal trigger coincidence (gamma (trigger request) + timing thresholds)"
			;;

		4)
			log "# Switching to free running multi event mode"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x80
			logdo ./setpar febex.db set *.*.*.trigger_validation_src 0x100
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 1
			logdo ./setpar febex.db set *.*.*.discr_enable_walk_correction 1
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.trigger_validation_delay 80
			logdo ./setpar febex.db set *.*.*.trigger_validation_gate_length 120
			logdo ./setpar febex.db set *.*.*.signal_delay 60
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 199
			logdo ./setpar febex.db set *.*.*.opmode_enable_trace 0

			LASTMSG="Switched to free running multi event mode"
			;;

		5)
			log "# Switching to free running single event trace mode"
			logdo ./setpar febex.db set *.*.*.trigger_timing_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_gamma_dst 0
			logdo ./setpar febex.db set *.*.*.trigger_timing_src 0x80
			logdo ./setpar febex.db set *.*.*.trigger_validation_src 0x100
			logdo ./setpar febex.db set *.*.*.trigger_enable_validation 1
			logdo ./setpar febex.db set *.*.*.discr_enable_walk_correction 1
			logdo ./setpar febex.db set *.*.*.trigger_timing_delay 0
			logdo ./setpar febex.db set *.*.*.trigger_validation_delay 80
			logdo ./setpar febex.db set *.*.*.trigger_validation_gate_length 120
			logdo ./setpar febex.db set *.*.*.signal_delay 250 # will break qpid
			logdo ./setpar febex.db set *.*.qpid_delay 10
			logdo ./setpar febex.db set *.*.num_events_readout 1
			logdo ./setpar febex.db set *.*.*.opmode_enable_trace 1
			logdo ./setpar febex.db set *.*.*.tracemode 0

			LASTMSG="Switched to free running single event trace mode"
			;;


		*)
			return
			;;

		esac

		LASTMSG="$LASTMSG\nRemember to restart the DAQ to apply the changes."

#		break
#	done
}

function menu_parameters {
	clear

	menu_headline "Parameters"

  OPTS=("Set Trigger Thresholds" "Set Operation Mode" "Expert: Start ./setpar to manually set parameters")

	if [ -f .febex.db.backup ]; then
    OPTS+=("Recover last febex.db")
		RECOVER=true
	else
		RECOVER=false
	fi

  OPTS+=("Return")

  menu "${OPTS[@]}"
	REPLY=$?

#	select SEL in "${OPTS[@]}"; do

		case "$REPLY" in

		1)
			menu_triggers
			;;

		2)
			menu_opmode
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
			DIFF=$(diff -U 0 ._setpar_before ._setpar_after)
			if [[ -z "$DIFF" ]]; then
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

#		break		

#	done
}

function create_default_config {

	echo
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

	clear
	echo "Your configuration will consist of $NCRATES crate(s)."
	for I in $(seq 0 $(($NCRATES - 1))); do
		echo "  ${NFEB[$I]} card(s) in crate $(($I + 1))"
	done

	echo
	echo "Is this correct, do you want to continue?"

	menu "Yes - Proceed to create configuration." "No - Ask me again!" "Nah - Just take me to the main menu."
	REPLY=$?
#	select SEL in "${OPTS[@]}"; do
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

		esac

#		break
#	done
	
}

function start_run {
  clear

  if [[ -f ../.run/runnumber ]]; then
    RUNNUMBER=$(cat ../.run/runnumber)
  else
    RUNNUMBER=1
  fi 

  NRF=$(printf "%03d" "$RUNNUMBER")

  if [[ -f ../.run/rundescription ]]; then
    DESCR=$(cat ../.run/rundescription)
  else
    DESCR=""
  fi

  menu_headline "Start run"

#  while true; do
    printf "Time:       \e[1m%s\e[0m\n" "$(date '+%Y-%m-%d %H:%M')"
    printf "Run number: \e[1m%03d\e[0m\n" "$RUNNUMBER"

    echo
    echo "Enter short description (Beam energy, target, detector setup, ...):"
    read -e -i "$DESCR" DESCR

    if [[ -z "$DESCR" ]]; then
      return
    fi

    RUNTS=$(date '+%s')
    RUNDIR=$(printf "%03d_%s" "$RUNNUMBER" "$(date -d @$RUNTS '+%Y-%m-%d_%H-%M-%S')")

    mkdir -p ../data/$RUNDIR
    RUNLOGF=../data/$RUNDIR/log.txt
    cp febex.db ../data/$RUNDIR/febex.db
    ./setpar febex.db list > ../data/$RUNDIR/febex_db.txt

    log "# Run $NRF started"
    log "# > $DESCR"

    printf "\"START\";\"%03d\";\"%s\";\"%d\";\"%s\"\n" "$RUNNUMBER" "$(date -d @$RUNTS '+%Y-%m-%d %H:%M:%S')" "$RUNTS" "$DESCR" >> ../data/runlog.csv

    open_file "data/$RUNDIR/data_.lmd"

    LASTMSG="Run \e[1m$RUNDIR\e[0m started"

    echo $((RUNNUMBER + 1)) > ../.run/runnumber
    echo "$DESCR" > ../.run/rundescription

#    menu "Return"
#  done
}

function stop_run {
  close_file

  STOPTS=$(date '+%s')
  STOPTSH="$(date -d @$STOPTS '+%Y-%m-%d %H:%M:%S')"
  NRF=$(printf "%03d" "$RUNNUMBER")

  log "# Run $NRF stopped"
  printf "\"STOP\";\"%03d\";\"%s\";\"%d\";\"\"\n" "$RUNNUMBER" "$STOPTSH" "$STOPTS" >> ../data/runlog.csv

  RUNDIR=""
  RUNNUMBER=""
  RUNLOGF=""

  LASTMSG="Run \e[1m$NRF\e[0m stopped"
}

function menu_run {
  clear

  menu_headline "Run Management"

  check_status "fo" "/ucesb/empty/empty"
  RUN_ACTIVE=$?

  if [[ "$RUN_ACTIVE" -eq "1" && -n "$RUNDIR" ]]; then
    
    menu "Stop Run $RUNDIR" "Return"
    REPLY="$?"

    case "$REPLY" in
      1)
	stop_run
	;;
      2)
	return
	;;
    esac

  elif [[ "$RUN_ACTIVE" -eq "1" ]]; then

    echo "A file is open, but no run seems to be started. Please close the current file to proceed."
    menu "Return"

    return

  else
    
    menu "Start Run" "Return"
    REPLY=$?

    case "$REPLY" in
      1)
	start_run
	;;
      2)
	return
	;;
    esac
  fi

}

function open_file {
		FILENAME=$1
		echo "$FILENAME" > ../.run/filename
		PORT=$(cat ../.run/eb.${HOSTNAME}.port)
	
		tmux select-pane -t 4
		tmux send-keys "scripts/fo.sh $PORT $HOSTNAME" C-m

		log "# Opened file $FILENAME"
		LASTMSG="File output started to \e[1m${FILENAME}\e[0m"
}

function close_file {
		log "# Closing output file"

		tmux select-pane -t 4
		tmux send-keys C-c

		LASTMSG="Output file closed"
}

function menu_file {
	clear

	menu_headline "File Output"

	check_status "fo" "/ucesb/empty/empty"
	FILE_OPEN=$?

	FILENAME=$(cat ../.run/filename 2>/dev/null)
	mkdir -p ../data
	if [[ -z "$FILENAME" ]]; then
		TS=$(date "+%Y-%m-%d_%H-%M")
		FILENAME="data/${TS}_.lmd"
	fi

	if [[ "$FILE_OPEN" -eq "1" ]]; then
		# File output is currently active
		echo -e "\e[7mFile open:\e[0;1m $FILENAME\e[0m\n"
		echo

		menu "Close file" "Return"
		REPLY=$?
#		select SEL in "${OPTS[@]}"; do
			case "$REPLY" in
				1)
					;;
				2)
					return
					;;
			esac	
#		done

		close_file

	else
		# No file is currently open
		echo -e "\e[7mFile closed\e[0m"
		echo

		menu "Open output file" "Return"
		REPLY=$?
#		select SEL in "${OPTS[@]}"; do
			case "$REPLY" in
				1)
					;;

				2)
					return
					;;
			esac
#		done

		echo
		echo "Enter filename to write to [$FILENAME]"
		echo -e "\e[1mNote:\e[0m A running file number will be added to the filename.\n"
		read -ei "$FILENAME" FNAME
		if [[ -n "$FNAME" ]]; then
			FILENAME=$FNAME
		fi
		
		open_file "$FILENAME"
	fi	
}

##############################
# Main
##############################

mkdir -p .run

if [[ ! -f febex.db ]]; then
	clear

	menu_headline "Welcome to the Easy DAQ control interface"

	create_default_config
fi


function main_menu {
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

#	OPTS=("MBS: Start/Stop Acquisition, ...", "Parameters", "Open/Close file", "Quit")
	menu "MBS: Start/Stop Acquisition" "Parameters" "Run Management" "Open/Close file" "Quit"

	REPLY=$?

#	select SEL in "${OPTS[@]}"; do
#
		case "$REPLY" in

		1)
			menu_daq
			;;

		2)
			menu_parameters
			;;

		3)
		  menu_run
		  ;;

		4)
			menu_file
			;;

		5)
			menu_shutdown
			;;

		esac

	tmux select-pane -t 1
}


while true; do
	main_menu
done




