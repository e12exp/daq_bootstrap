#!/bin/bash
. $(dirname $0)/../config/local_settings.sh
test -n "$MBSPC" && /u/land/epics/adl/powercycle/text.bash $MBSPC

