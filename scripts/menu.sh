#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

function rebuild_menu {
		TWIDTH=$(tput cols)

		if [[ "$FIRSTRUN" -eq "0" ]]; then
			# Restore cursor position
			echo -en "\e[${#MENUOPTS[@]}F"
		fi

		IDX=0
		for I in "${MENUOPTS[@]}"; do
			if [[ "$IDX" -eq "$POS" ]]; then
				M1="\e[7m"
			else
				M1=""
			fi
	
			printf "${M1}%-${TWIDTH}s\e[0m\n" " $(($IDX + 1))) ${I:0:$(( $TWIDTH - 10 ))}"
	
			IDX=$(( $IDX + 1 ))
		done

		FIRSTRUN="0"
}

function menu {
	POS=0

	# Hide cursor
	echo -en "\e[?25l"

	MENUOPTS=("$@")
	FIRSTRUN="1"

	if [[ "$MENU_RETURN_ON_RESIZE" -eq "1" ]]; then
		trap "return 0" SIGWINCH
	elif [[ "$MENU_NO_TRAP" -ne "1" ]]; then
		trap rebuild_menu SIGWINCH
	fi
	MENU_NO_TRAP=0
	MENU_RETURN_ON_RESIZE=0

	while true; do
		rebuild_menu
	
		STATE=0
		while true; do
			read -s -N 1 CHAR

			if [[ "$CHAR" =~ [1-9] && "$CHAR" -le "$#" ]]; then
				echo -en "\e[?25h"
				return $CHAR
			fi
	
			CC=$(printf "%x" "'$CHAR")
			case "$CC" in
				"0")
					# Make cursor visible again
					echo -en "\e[?25h"
					# Return position via exit code
					return $(( $POS + 1 ))
					;;
				"1b")
					STATE=1
					;;
				"5b")
					if [[ "$STATE" -eq "1" ]]; then
						STATE=2
					fi
					;;
				"41")
					if [[ "$STATE" -eq "2" && "$POS" -gt "0" ]]; then
						# up
						POS=$(( $POS - 1 ))
						break
					fi
					STATE=0
					;;
				"42")
					if [[ "$STATE" -eq "2" && "$POS" -lt "$(( $# - 1 ))" ]]; then
						# down
						POS=$(( $POS + 1 ))
						break
					fi
					STATE=0
					;;
				*)
					STATE=0
					;;
			esac
		done
	done
}
