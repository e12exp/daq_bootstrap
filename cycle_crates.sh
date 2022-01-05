#!/bin/bash
. config/local_settings.sh
test -n "$TDK" && ssh lxg1290 ". /u/land/opt/epics/epicsfind.bash ; caput -c $TDK 0 | grep -v New; sleep 5; caput $TDK 1 | grep -v New ; sleep 1; caget $TDK "
