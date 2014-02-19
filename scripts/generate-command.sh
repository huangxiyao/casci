#!/bin/bash

if [ $# -ne 3 ]; then
    echo -e "please enter report file name or command file name or the environment \n";
    exit 1;
fi

if [ ! -f "$1" ]; then
    echo -e "report file didn't exit \n";
    exit 1;
fi

report_file=$1
command_file=$2

repositoryId="$(awk -F $'\t' '{print $2}' ${report_file} | sed 's!.*storage/!!' | awk -F $'/' '{print $1}' |sort| uniq |sed '/^$/d')"

if [ "${repositoryId}"x = "releases"x -o "${repositoryId}"x = "snapshots"x ] ; then
	echo "delete artifacts on nexus releases or snapshots repository ."
else 
	echo "please enter the correct report file ."
	exit 1;
fi

if [ "$3"x = "itg"x ]; then
	#for ITG
	awk -F $'\t' '$4 ~ /X/ {print $2}' ${report_file} |sed "s!/storage/${repositoryId}/!/storage/${repositoryId}/content/!" | sed 's!.*storage/!curl -X DELETE -u admin:casiscool http://gvt1344.austin.hp.com/nexus/service/local/repositories/!' > ${command_file}
elif [ "$3"x = "pro"x ]; then
	#for PRO
	awk -F $'\t' '$4 ~ /X/ {print $2}' ${report_file} |sed "s!/storage/${repositoryId}/!/storage/${repositoryId}/content/!" | sed 's!.*storage/!curl -X DELETE -u admin:casiscool http://repo1.corp.hp.com/nexus/service/local/repositories/!' > ${command_file}
else 
	echo "please enter the correct environment."
	exit 1;
fi

