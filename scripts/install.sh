#!/bin/bash

if [ "$#" -lt "1" ]; then
	echo "Usage: $0 hostname" >&2
	exit -1
fi

HOSTNAME="$1"
WDABS="$PWD"
WD=$(echo $PWD | sed -e "s#$HOME##g" | sed -e "s#^/##g")

if [ ! -f febex_set_param/setpar ]; then
	cd febex_set_param
	make || exit
	cd ../mbs
	rm -f setpar
	ln -s $WDABS/febex_set_param/setpar ./setpar
	cd ..
fi

if [ ! -f ucesb/empty/empty ]; then
	cd ucesb
	./make.sh || exit
	cd ..
fi

