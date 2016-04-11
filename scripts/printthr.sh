#!/bin/bash

THR=()
MOD=()
CH=()
SFP=()
I=0
./setpar febex.db get "*.*.*.$1" 2>/dev/null | gawk 'BEGIN { print "#!/bin/bash" }
match($0, /^([0-3])\.([0-9]{3})\.([0-9]{2})\.(\w+)[^:]+:\s*([0-9]+)/, a) {
  printf "SFP[$I]=%d\nMOD[$I]=%d\nCH[$I]=%d\nTHR[$((I++))]=%d\n", a[1], a[2], a[3], a[5]
}' > .tmp.sh 

source .tmp.sh
rm -f .tmp.sh

NUM=$I

function print_all_thr {
  echo -e "\e[1mCurrent thresholds\e[0m:"
  echo -e "\e[1mSFP\e[0m | \e[1mModule\e[0m | \e[1mChannel\e[0m | \e[1mThreshold\e[0m "
  echo "----+--------+---------+-----------"
  for I in $(seq 0 $(($NUM-1))); do
    printf "%3d | %6d | %7d | \e[1;32m%9d\e[0m\n" "${SFP[$I]}" "${MOD[$I]}" "${CH[$I]}" "${THR[$I]}"
  done

  exit
}

THRALL="${THR[0]}"
echo "$THRALL" > .thr.tmp
for I in $(seq 1 $(($NUM-1))); do
  if [[ "${THR[$I]}" -ne "$THRALL" ]]; then
    print_all_thr
  fi
done

echo -e "\e[1mCurrent threshold for all channels: \e[32m$THRALL\e[0m"

