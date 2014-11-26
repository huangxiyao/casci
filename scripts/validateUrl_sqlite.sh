#!/bin/bash

validateEnvironment="$1"
validateComponent="$2"
sqlite3="sqlite3"
FAILED_COUNT=0
SUCCESS_COUNT=0
HTTP_STATUS_CODE=0
CHECKURL=""
CHECK_NAME="$validateEnvironment-Batch-Cloud"
dbName=/casfw/var/data/$validateEnvironment-$validateComponent-Failure-Urls.db
emailReciplients="${EMAIL_RECIPIENTS:-li-na.du@hp.com}"
#emailReciplients="${EMAIL_RECIPIENTS:-USERS-CAS-CORE-DEV@groups.hp.com,PDL-TEAM-CAS-GADSC-DEV@hp.com}"

function setupDB {
	# download SQLite if the sqlite3 didn't exist
	if [ ! -f $sqlite3 ]; then
		echo -ne "\n download and unzip sqlite3 file ."
		wget http://repo1.corp.hp.com/nexus/content/repositories/thirdparty/org/sqlite/sqlite-shell-linux/3.6.20/sqlite-shell-linux-3.6.20-x86.zip -O sqlite.zip; unzip sqlite.zip; rm sqlite.zip; 
	fi
	# create the DB if the DB didn't exist
	if [ ! -f $dbName ]; then
		#Create DB schema (sqlite3 XXX.db "create table ...;")
		sqlite "create table states (url varchar(512), successCount smallint, failureCount smallInt);"
		chmod 777 $dbName
	fi
}

function sqlite {
	sqlite3 $dbName "$1"
}

function getMonitorState {
	FAILED_COUNT=$(sqlite "select failureCount from states where url = '$CHECKURL'")
	SUCCESS_COUNT=$(sqlite "select successCount from states where url = '$CHECKURL'")
}


function downloadServerList {
	echo -ne "\n Pulling the Servers list\n"
	curl -s https://code1.corp.hp.com/svn/cas/build-scripts/auto-deployment/$validateEnvironment-$validateComponent-urls.txt -o $validateEnvironment-$validateComponent-urls.txt
	validateServerList="$validateEnvironment-$validateComponent-urls.txt"
	if [ ! -f $validateServerList ]; then
		echo -ne "\n$validateServerList - Either file does not exist in SVN or download failed or there is no disk space on the box where the validation script is run"
		exit 1
	fi
}

function checkUrl {
	#read HTTP STATUS CODE
	HTTP_STATUS_CODE=$(curl -o "/dev/null" -sk --insecure -w "%{http_code}" --connect-timeout 30 $CHECKURL)
	if [[ $HTTP_STATUS_CODE -eq 200 || $HTTP_STATUS_CODE -eq 204 ]]; then
		return 0
	else
		return 1  
	fi
}

function validate {
	TEMPURL=$(sqlite "select url from states where url = '$CHECKURL'")
	checkUrl
	if [[ $? -eq 0 ]]; then
		echo "success -$HTTP_STATUS_CODE"
		if [ -n "$TEMPURL" ];then
			echo "The $CHECKURL have exist in the $dbName . "
			successState
		fi
	else
		echo "failure -$HTTP_STATUS_CODE"
		if [ -n "$TEMPURL" ];then
			echo "The $CHECKURL have exist in the $dbName . "
			failedState
		else
			FAILED_COUNT=1
			sqlite "insert into states values ('$CHECKURL',0,1)"
			sendFailureMail &
		fi
	fi
}

function startValidate {
	while read line; do  
		CHECKURL="$line"
		echo -ne "$CHECKURL - "
		sleep 2s
		validate
	done < $validateServerList
}

function successState {
	getMonitorState
	if [[ $SUCCESS_COUNT -lt 3 ]]; then
		((SUCCESS_COUNT++))
		if [[ $SUCCESS_COUNT -eq 3 ]]; then
			sendSuccessMail &
			sqlite "delete from states where url = '$CHECKURL'"
		else 
			sqlite "update states set successCount=$SUCCESS_COUNT where url = '$CHECKURL'"
		fi
	else 
		echo "have successful 3 times ."
	fi
}

function failedState {
	getMonitorState
	if [[ $SUCCESS_COUNT != 0 ]]; then
		sqlite "update states set successCount=0 where url = '$CHECKURL'"
	fi
	if [[ $FAILED_COUNT -lt 3 ]]; then
		((FAILED_COUNT++))
		sendFailureMail &
		sqlite "update states set failureCount=$FAILED_COUNT where url = '$CHECKURL'"
	else
		echo "have reminded 3 times ."
	fi
}

# This Function is to send Failed mails
function sendFailureMail {
	sendmail -t <<EOM
date: todays-date
to: ${emailReciplients}
Subject: FAILURE - $CHECK_NAME - HTTP Error - $HTTP_STATUS_CODE - Notice ( $FAILED_COUNT ) 
from: noreply@hp.com

$BUILD_URL running on slave node : $(hostname). 

ERROR :

$CHECKURL failed with HTTP Error code : $HTTP_STATUS_CODE
EOM
}

# This Function is to send success mails
function sendSuccessMail {
	sendmail -t <<EOM
date: todays-date
to: ${emailReciplients}
Subject: SUCCESS - $CHECK_NAME - HTTP Status - $HTTP_STATUS_CODE
from: noreply@hp.com

$BUILD_URL completed on slave node : $(hostname). 

$CHECKURL SUCCEEDED with HTTP status code : $HTTP_STATUS_CODE
EOM
}

downloadServerList
setupDB
startValidate
rm $validateEnvironment-$validateComponent-urls.txt

