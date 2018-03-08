#!/bin/tcsh

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

#resl
$MBSBIN/m_remote reset -l
setenv NOWR 1
make && python init.py && touch .running && exec $MBSBIN/m_dispatch
