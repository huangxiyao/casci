#!/bin/sh

# Flowdock

ENVIRONMENT="$1"
UPPERENV=$(echo "$ENVIRONMENT" | tr '[[:lower:]]' '[[:upper:]]')

isTest="$2"
FLOW_TOKEN="ce5f92d6b2f7d4af2c7e06783fe6a073" # CAS Team Test Flow
if [[ "$isTest" == "" ]]
then
    FLOW_TOKEN="0c2eca8b943f665782821b0591dc948d" # CAS Team Flow
fi

RESULTFILE="casci-monitor-result.txt";
FAILEDRECORDS=""
TABLE=""
STATUS=""
COLOR=""

if [[ -f $RESULTFILE ]]
then
    FAILEDRECORDS=$(cat $RESULTFILE | grep "${JOB_NAME}-${BUILD_NUMBER}" | sed "s/${JOB_NAME}-${BUILD_NUMBER} //g")
fi

function retrieveFailedRecords {
    TABLE="<table border='1'><tr><th>Failed Url</th><th>Status Code</th></tr>";

while read record
do
    url=$(echo ${record} | awk '{print $1}');
    status=$(echo ${record} | awk '{print $2}');
    TABLE=${TABLE}"<tr><td><a href="${url}">"${url}"</a></td><td>"${status}"</td></tr>";
done << EOF
$FAILEDRECORDS
EOF

    TABLE=${TABLE}"</table>";
}

function postToFlowdock {
    curl --silent \
         --header "Accept: application/json" \
         --form "flow_token=$FLOW_TOKEN" \
         --form "event=activity" \
         --form "author[name]=Jenkins" \
         --form "author[avatar]=http://jenkins-ci.org/sites/default/files/images/headshot.png" \
         --form "title= <a href=${BUILD_URL}console>${JOB_NAME}-${BUILD_NUMBER} Console Output</a>" \
         --form "tags=AS-Monitoring" \
         --form "external_thread_id=extract:as:monitor:$UPPERENV" \
         --form "thread[title]=$JOB_NAME" \
         --form "thread[status][color]=${COLOR}" \
         --form "thread[status][value]=${STATUS}" \
         --form "body= ${TABLE}" \
         "https://api.flowdock.com/messages" > /dev/null
}

if [[ $FAILEDRECORDS != "" ]]
then
    echo "Sending out the FAILED Monitor notification..."
    STATUS="failure"
    COLOR="orange"
    retrieveFailedRecords
    postToFlowdock
    exit 1
else
    let lastBuildNumber=${BUILD_NUMBER}-1
    lastFailedRecords=$(cat $RESULTFILE | grep "${JOB_NAME}-${lastBuildNumber}" | sed "s/${JOB_NAME}-${lastBuildNumber} //g")
    if [[ $lastFailedRecords != "" ]]
    then
        STATUS="success"
        COLOR="green"
        TABLE="Services are back to normal now!"
        postToFlowdock
        echo "Services are back to normal"
        exit 0
    else
        echo "Monitors are SUCCESS!"
        exit 0
    fi
fi

while [[ condition ]]; do
	#statements
done