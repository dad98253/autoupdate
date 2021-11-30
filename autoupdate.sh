#! /bin/bash
#
# check tripwire - if all is good, update system files - if not, send email
#
scriptName="${0##*/}"

LOCKDIR="/autoupdate-lock"

tripwire=/usr/sbin/tripwire
[ -x $tripwire ] || exit 0
tripwirecheck=/root/scripts/tripwire-check.sh
[ -x $tripwirecheck ] || exit 0

source settings.sh

umask 027

# Option to skip initial tripwire test
declare -i -g dotrip=1

#Remove the lock directory
function cleanup {
    if rmdir $LOCKDIR; then
        echo "Finished"
    else
        echo "Failed to remove lock directory '$LOCKDIR'"
        echo "Failed to remove lock directory '$LOCKDIR'" | logger
    	echo "Failed to remove lock directory '$LOCKDIR'" | mail -s "autoupdate problem" $myemail
        exit 1
    fi
}

function printUsage() {
    cat <<EOF

Synopsis
    $scriptName [-s] 
    Update all packages

    Check for unauthorized changes to system files. If everything looks okay,
    upadte all packages. If not, send an e-mail to the system manager.

    -s
        Skip the initial tripwire check.

EOF
}

# Options.
while getopts ":s" option; do
	case "$option" in
            s) dotrip=0 ;;
            *) printUsage; exit 1 ;;
	esac
done
shift $((OPTIND - 1))
option=$1

#
# tripwire exits 0 if no changes are detected. Otherwise the exit value is a bit mask:
#
#       1 At least one file or directory has been added.
#
#       2 At least one file or directory has been modified.
#
#       4 At least one file or directory has been modified.
#
#       8 Error(s) occurred during the check.
#

#
# create a cron job to run the script at an interval (eg run it once a day)
# crontab -e
# 0	3	*	*	*	/root/scripts/autoupdate.sh
#

hostroot=$HOSTNAME
echo $hostroot
# set up a lock directory to prevent multiple simultaneous executions of the script
if mkdir $LOCKDIR 2>/dev/null; then
    #Ensure that if we "grabbed a lock", we release it
    #Works for SIGTERM and SIGINT(Ctrl-C)
    trap "cleanup" EXIT
    echo "Acquired lock, running"
#if ["$hostroot" != "$targethost"]; then
#exit 2
#fi
today=`date +%Y-%m-%d.%H:%M:%S`
tripwiretext=/tmp/$hostroot.$today.tripwire.txt
tripwirereport=/var/lib/tripwire/report/$hostroot.$today.tripwire.twr
OS_PROBER_DISABLE_DEBUG=true
export OS_PROBER_DISABLE_DEBUG

if [[ $dotrip -eq 1 ]]; then
$tripwire --check --quiet
fi
if [ "$?" = "0" ]; then
echo "update repositories"  | logger
apt-get update -y 
echo upgrade  | logger
apt-get upgrade -y 
echo dist-upgrade | logger
apt-get dist-upgrade -y
echo autoclean | logger
apt-get autoclean -y 
echo clean | logger
apt-get clean -y
echo autoremove | logger
apt-get autoremove -y
# check if a reboot is required - if so, tripwire will need another update after
# (may work for red hat?) needs-restarting  -r ; if [ "$?" = 1 ]; then
if [ -f /var/run/reboot-required ]; then
  echo 'reboot required'
  echo 'reboot required' | logger
# the following line only works for debian based  
  cat /var/run/reboot-required.pkgs | mail -s "reboot required - re-update tripwire after" $myemail
fi
# update the tripwire database
echo "update tripwire files" | logger
#remove all old reports
rm -v /var/lib/tripwire/report/*
rm -v /tmp/*.tripwire.txt
echo "Old tripwire reports purged"
echo "Old tripwire reports purged" | logger
# generate a report of the changes
$tripwirecheck $tripwiretext $tripwirereport
echo "Tripwire report updated"
echo "Tripwire report updated" | logger
# find the report we just created	
last_report=`ls -t /var/lib/tripwire/report | head -n 1`
echo "New report is '$last_report'"
echo "New report is '$last_report'" | logger
# accept all changes and generate new database file
tripwire --update --silent --accept-all --twrfile /var/lib/tripwire/report/$last_report -P $tripwire_local_password
#tripwire --update         --accept-all --twrfile /var/lib/tripwire/report/$last_report -P $tripwire_local_password
echo "Tripwire database updated"
echo "Tripwire database updated" | logger
echo "tripwire update complete" | logger
else
  echo "tripwire failed!" 1>&2
  echo "tripwire failed!" | logger
  $tripwire --check --quiet --email-report
  exit 1
fi
echo "autoupdate script complete" | logger
exit 0
else
    echo "Could not create lock directory '$LOCKDIR'"
    echo "Could not create lock directory '$LOCKDIR'" | logger
    echo "Could not create lock directory '$LOCKDIR'" | mail -s "autoupdate problem" $myemail
    exit 1
fi

