#!/bin/bash
exec ssh -tt lxlandana01 $(readlink -f $(dirname $0))/fo.sh "$@"
