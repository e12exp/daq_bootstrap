#!/bin/bash

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

#resl
bash pexheal.sh
sleep 1
$MBSBIN/m_remote reset -l
export LD_PRELOAD=$PWD/libreuse/libreuse.so
#export NOWR 1
make && python init.py && touch .running && exec $MBSBIN/m_dispatch
