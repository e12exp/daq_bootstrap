#!/bin/bash
# this script is to be called by config/Makefile only!
# in particular, it assumes that 
. local_settings.sh

function log()
{
    test -n "$DEBUG" || return
    echo $@ >&2
}

function backup()
{
    echo running "$0 $@"
    if ! ( cd ../mbs/ ; md5sum -c febex.db.local.md5 &>/dev/null )
    then
        BASEDIR=$PWD
        cd ../mbs/ 
        md5sum febex.db > febex.db.local.md5
        LOCALMD5=$(cut -d ' ' -f 1 febex.db.local.md5)
        mkdir -p oldconf
        BACKUP="oldconf/febex.db.${LOCALMD5}"
        cp febex.db oldconf/febex.db.${LOCALMD5}
        cd ${BASEDIR}
        test "$1" == "--commit" && git commit --allow-empty -m "Started using manually modified mbs/$BACKUP as febex.db"
    fi
}

log "running commit.sh"

if ( cd ../mbs/ ; test -f febex.db && ! md5sum -c febex.db.md5 &>/dev/null )
then
    echo "*******************************************************************************"
    echo "MANUAL CHANGES IN febex.db DETECTED."
    echo "Automatic updating from text-generated version disabled."
    echo "Remove mbs/febex.db away to reenable."
    echo "*******************************************************************************"
    backup --commit
    exit 0
fi

GITARGS=""
MSG=""
COPY=""

if ! diff febex.db.md5 ../mbs/febex.db.md5 &>/dev/null
then
    log "md5sum of config/febex.db changed"
    MSG+="Updated changes from text file. "
    COPY=1
fi

if ! test -f ../mbs/febex.db
then
    log "mbs/febex.db is missing"
    MSG+="Started using text generated febex.db. "
    COPY=1
fi

if test -n "$COPY"
then
    log "copying config/febex.db to mbs/"
    cp febex.db* ../mbs/
    GITARGS+="--allow-empty"
    MD5=$(cut -d ' ' -f 1 febex.db.md5)
    MSG+="Now using febex.db with md5=$MD5. "
    backup # store in oldconf, but no separate commit here!
else
    log "not copying config/febex.db not mbs/"
    MSG="Cosmetic changes only."
fi

git add -A 
git commit  ${GITARGS} -m "$MSG" | tee git.commit.out | grep -vE "On branch|nothing to commit"
test -n "$?" || grep "nothing to commit" git.commit.out || { echo "git commit failed:" ; exit -1;  }
