#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################



if test "$0" == "/bin/bash" # we are invoked by --rcfile from ssh
then
    cd $(dirname ${BASH_SOURCE[0]})/../mbs
    if test -z "$MBSBIN"
    then
        source ../scripts/mbs.env
    fi
    alias mbs=./mbs
    INITARGS="" # if a user want to cycle stuff, let them do from the PC running tmux
    EXEC=""
else # we are invoked by a subsequent call via ./mbs
    INITARGS= "$@"
    EXEC=exec
fi

bash pexheal.sh
sleep 1
$MBSBIN/m_remote reset -l
export LD_PRELOAD=$PWD/libreuse/libreuse.so
#export NOWR 1
make && make -sC ../config/ commit && python init.py ${INITARGS} && touch .running && $EXEC $MBSBIN/m_dispatch -dabc

