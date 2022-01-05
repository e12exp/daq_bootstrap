#!/bin/bash
. config/local_settings.sh
test -n "$MBSPC" && /u/land/epics/adl/powercycle/text.bash $MBSPC

