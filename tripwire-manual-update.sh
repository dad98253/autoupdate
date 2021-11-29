#!/bin/bash

tripwire=/usr/sbin/tripwire
[ -x $tripwire ] || exit 0

source settings.sh

tripwire --check --silent

last_report=`ls -t /var/lib/tripwire/report | head -n 1`

umask 027

shopt -s extglob
rm -v /var/lib/tripwire/report/!($last_report)
shopt -u extglob

tripwire --update --silent --accept-all --twrfile /var/lib/tripwire/report/$last_report -P $tripwire_local_password
#tripwire --update          --accept-all --twrfile /var/lib/tripwire/report/$last_report -P $tripwire_local_password
