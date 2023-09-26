#!/bin/bash

#runs mbs over ssh
cd $(dirname $(readlink -f $0) )

. functions.sh

FOREVER=0
test "$1" == "--forever" && FOREVER=1

MBSPATH=$(echo $PWD | sed s@/u/land/@/land/usr/land/@ | sed s@/lynx/Lynx@@ )

LOOP=1
while test -n "$LOOP"
do
    check_daq_pc
    ssh -tt $MBSPC "/bin/bash --rcfile $MBSPATH/runmbs.bash"
    echo -n "Connection to $MBSPC was interrupted. "
    if test -n "$FOREVER"
    then
        echo "Will try to reestablish..."
        sleep 5
    else
        echo "Will terminate $0"
        LOOP=""
    fi
done
