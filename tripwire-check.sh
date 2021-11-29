#!/bin/bash

if [ $1 ];
then
    tripwire --check -r $2 > /dev/null 2> $1
    twprint -m r -r $2 -t 4 > $1 2>&1
else
    tripwire --check
fi
exit 0
