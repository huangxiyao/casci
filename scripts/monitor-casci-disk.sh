#!/bin/bash

# To start the script:
# 
# $ nohup ./monitor-fez-disk.sh > /dev/null 2>&1 &
#
#
# The script is configured by default for FEZ-PRO server monitoring.
# It can be invoked with other values as following:
#
# $ env MOUNT_TO_CHECK=/dev/sdb1 THRESHOLD_PRECENT=60 CHECK_INTERVAL=1m EMAIL_RECIPIENTS="slawomir.zachcial@hp.com,hugh.mckee@hp.com" ENVIRONMENT=FOR-TEST-ONLY nohup ./monitor-fez-disk.sh > /dev/null 2>&1 &
# 
# All this is single line. All of the variables are optional.
#

mountToCheck="${MOUNT_TO_CHECK:-/casfw/var/data}"
emailReciplients="${EMAIL_RECIPIENTS:-PDL-TEAM-CAS-GADSC-DEV@hp.com,USERS-CAS-CORE-DEV@groups.hp.com}"
environment="${ENVIRONMENT:-PRO-CASCI}"
thresholdPercent="${THRESHOLD_PERCENT:-80}"
checkInterval="${CHECK_INTERVAL:-10m}"


function checkDisk {
    percentUsed="$(df -P | awk '{ if ($6 == "'$mountToCheck'") { print substr($5,0,length($5)-1) }}')"

    if [ -n "$percentUsed" ] && [ "$percentUsed" -gt "$thresholdPercent" ]; then
         sendmail -t <<EOM
date: todays-date
to: ${emailReciplients}
Subject: ${environment} WARNING: ${mountToCheck} use on $(hostname) is >${thresholdPercent}%: ${percentUsed}% !
from: noreply@hp.com

${mountToCheck} use on $(hostname) is ${percentUsed}% !!!
Disk clean-up required.
EOM
    fi
}


while [ 1 ]; do
    checkDisk
    sleep $checkInterval
done

