#!/bin/tcsh

##############################################
# DUCK - DAQ User-friendly Control Kit
#
# Max Winkel <max.winkel@ph.tum.de>
# 2016, Apr 11
##############################################

#resl
$MBSBIN/m_remote reset -l
./ini_chane 0 1
./ini_chane 0 1
setenv NOWR 1
make
#mbs
$MBSBIN/m_dispatch
