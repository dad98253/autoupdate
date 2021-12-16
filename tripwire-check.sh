#!/bin/bash

twprint=/usr/sbin/twprint

if [[ $3 -eq 1 ]]; then
    echo 'debug mode' | logger
    tripwire --check -r $2 | logger
    twprint -m r -r $2 -t 4 2>&1 | tee $1 | logger
else
    tripwire --check -r $2 > /dev/null 2> $1
    twprint -m r -r $2 -t 4 > $1 2>&1
fi
exit 0
