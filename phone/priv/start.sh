#!/bin/sh

if [ -f /data/aplay.pid ]
then
    kill $(cat /data/aplay.pid)
fi

# Start the program in the background
/usr/bin/aplay -q -d 30 --process-id-file /data/aplay.pid "$@" 
echo "Played Song"
ret=$?
exit $ret