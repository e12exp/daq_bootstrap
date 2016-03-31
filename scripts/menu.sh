#!/bin/bash

function menu {
	POS=0
	
	# Hide cursor
	echo -en "\e[?25l"

	while true; do
		TWIDTH=$(tput cols)

		IDX=0
		for I in "$@"; do
			if [[ "$IDX" -eq "$POS" ]]; then
				M1="\e[7m"
			else
				M1=""
			fi
	
			printf "${M1}%-${TWIDTH}s\e[0m\n" " $(($IDX + 1))) ${I:0:$(( $TWIDTH - 10 ))}"
	
#			if [[ "$IDX" -lt "$#" ]]; then
#				echo -en "\n"
#			fi
	
			IDX=$(( $IDX + 1 ))
		done
	
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
		
		# Restore cursor position
		echo -en "\e[${#}F"
	
	done
}
