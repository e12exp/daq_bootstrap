#!/bin/bash

source $(dirname $0 | xargs readlink -f )/../config/local_settings.sh

function set_crate()
{
    STATE=$1
    CRATE=$2
    ssh landgw01 ssh e12exp@${SLOWCONTROL} picocom febex_power_delay/${SIDE}/sfp${CRATE} -b 115200 --raise-dtr --raise-rts -r -t ${STATE} -x 0 -q 
}

ACTION=""
CRATES=""

for ARG in "$@"
do
    case $ARG
    in
        (--help)
            echo "here be help" ;;
        (--on)
            ACTION="1" ;;
        (--off)
            ACTION="0" ;;
        (--cycle)
            ACTION="0 ; 1" ;;
        (--all)
            CRATES="0 1 2 3" ;;
        ([0-3])
            CRATES+=" $ARG" ;;
        (*)
            echo "unknown argument $ARG. bye." ; exit -1 ;;
    esac
        
done

test -z "$ACTION" && echo "no action specified" && exit -1
test -z "$CRATES" && echo "no crates specified" && exit -1

for A in $ACTION
do
    if test "$A" == ";"
    then
        #echo "waiting"
        sleep 2
        continue
    fi

    for C in $CRATES
    do
        set_crate $A $C
    done
done
