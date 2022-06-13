#!/bin/bash
. $(dirname $0)/../config/local_settings.sh
. /u/land/opt/epics/epicsfind.bash
export EPICS_CA_ADDR_LIST=landgw01

if test -z "$TDK"
then
    echo "No TDK variable!"
    exit 1
fi
caput -c $TDK 0 | grep -v New
sleep 5
caput $TDK 1 | grep -v New
sleep 1
caget $TDK
