#!/bin/bash
# 
# update the tripwire config and pol files - generate new baseline database
#
# call :
# ./tripwire-update-config.sh <site-password> <local-password>
#

LOCKDIR="/autoupdate-lock"
source settings.sh

#Remove the lock directory
function cleanup {
    if rmdir $LOCKDIR; then
        echo "Finished"
    else
        echo "Failed to remove lock directory '$LOCKDIR'"
        echo "Failed to remove lock directory '$LOCKDIR'" | logger
        echo "Failed to remove lock directory '$LOCKDIR'" | mail -s "autoupdate lock problem" john.c.kuras@gmail.com
        exit 1
    fi
}

# set up a lock directory to prevent multiple simultaneous executions of the script
if mkdir $LOCKDIR 2>/dev/null; then
    #Ensure that if we "grabbed a lock", we release it
    #Works for SIGTERM and SIGINT(Ctrl-C)
    trap "cleanup" EXIT
    echo "Acquired lock, running"
    #if ["$hostroot" != "$targethost"]; then
    #exit 2
    #fi

    read -s -p "Tripwire Site Password: " tripwire_site_password
    echo -e -n "\n"
    cd /etc/tripwire
    twadmin --create-cfgfile --site-keyfile site.key --site-passphrase $tripwire_site_password twcfg.txt
    twadmin --create-polfile --site-keyfile site.key --site-passphrase $tripwire_site_password twpol.txt
    tripwire --init --site-keyfile site.key --local-keyfile $targethost-local.key -P $tripwire_local_password
    cd ~

    echo "update config script complete" | logger
    exit 0
else
    echo "Could not create lock directory '$LOCKDIR'"
    echo "Could not create lock directory '$LOCKDIR'" | logger
    echo "Could not create lock directory '$LOCKDIR'" | mail -s "autoupdate problem" john.c.kuras@gmail.com
    exit 1
fi

