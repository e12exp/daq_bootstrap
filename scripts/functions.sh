
~/dabc/trunk/dabclogin 2>&1 | grep -v ^Configure

for i in . ..
do
    if test -d $i/config
    then
        source $i/config/local_settings.sh
    fi
done

test -z "$MBSPC" && echo "functions.sh: Warning: no local settings found, pwd is $PWD"
# mbscmd
function check_daq_pc
{
    while ! ssh -o ConnectTimeout=5 -o PasswordAuthentication=no \
            -n ${MBSPC} /bin/true
    do
        echo "host is not responding, still trying (^C to quit)"
        sleep 5
    done
}

function mbs_send
{
    echo "waiting to send $@ to mbs..."
    # wait for the connection to become available
    while ! nc $MBSPC 6019 -q 0 </dev/null &>/dev/null
    do
        sleep 1
    done
    mbscmd x86l-76 -cmd "$@"
}


function restart_mbs_pane
{
    PREV=$(tmux run "echo #{pane_id}")
    tmux select-pane -t 0
    if test "$1" == "--init"
    then
        tmux send-keys "scripts/remote_mbs.sh --forever" C-m
        shift
    else
        tmux send-keys C-m "~." C-m # sends hangup to ssh, quits the bash, then restarts because we used --forever

        # sourcing mbs.env on the tmux box is terrible. At least do we do it in a subshell. 
        ( . ../config/local_settings.sh ; . ../scripts/mbs.env ; ssh $MBSPC $MBSBIN/m_remote reset -l &>/dev/null )
        # even if a dabc connection survived the ssh disconnect, it should defintely be dead now.
    fi
    tmux select-pane -t $PREV
    # note that you will want to do     mbs_send "@ss" afterwards!
}

function reboot_daq_pc
{
    ./scripts/reboot.sh
    check_daq_pc
}
