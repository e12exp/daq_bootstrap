#!/bin/bash
cd $(dirname $0)

. functions.sh 
. ../config/local_settings.sh

mbs_send "$@"


