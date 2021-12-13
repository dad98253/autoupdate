#!/bin/bash

if [[ $3 -eq 1 ]]; then
    tripwire --check -r $2 > /dev/null | logger
    twprint -m r -r $2 -t 4 > $1 2>&1 | logger
else
    tripwire --check -r $2 > /dev/null 2> $1
    twprint -m r -r $2 -t 4 > $1 2>&1
fi
exit 0
