#!/bin/sh

if [ -f "/data/aplay.pid" ]
then
    echo "Killing $(cat /data/aplay.pid)\n"
    kill $(cat /data/aplay.pid)
else
    echo "Not Running"
fi
ret=$?
exit $ret