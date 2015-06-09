#! /bin/sh

set -e

: ${JAVA_OPTS:='-Xms1024M -Xmx2048M'}

if [[ -n "${HTTP_PROXY}" ]]
then
	proxyHost=${HTTP_PROXY#http://}
	proxyHost=${proxyHost%:*}
	proxyPort=${HTTP_PROXY##*:}
	nonProxyHosts=$(echo "${proxyHost}" | awk -F'.' '{printf "*.%s.%s\n", $(NF-1), $(NF)}')

	JAVA_OPTS="${JAVA_OPTS} -Dhttp.proxyHost=${proxyHost} -Dhttp.proxyPort=${proxyPort} -Dhttp.nonProxyHosts=${nonProxyHosts}"
	JAVA_OPTS="${JAVA_OPTS} -Dhttps.proxyHost=${proxyHost} -Dhttps.proxyPort=${proxyPort} -Dhttps.nonProxyHosts=${nonProxyHosts}"
fi

# Copy files from /usr/share/jenkins/ref into /var/jenkins_home.
# Does not overwrite files in /var/jenkins_home.
function copyReferenceFile
{
	local sourceFile=${1%/}
	local relative=${sourceFile#${JENKINS_REFERENCE}/}
	local targetFile=${JENKINS_HOME}/${relative}

	if [[ ! -e ${JENKINS_HOME}/${relative} ]]
	then
		echo "$(date '+%F %T') Copy ${relative} to JENKINS_HOME" >> ${COPY_REFERENCE_FILE_LOG}
		mkdir -p $(dirname ${targetFile})
		cp -r ${sourceFile} ${targetFile}
		# pin plugins on initial copy
		[[ ${relative} == plugins/*.jpi ]] && touch ${targetFile}.pinned
	fi
}

export -f copyReferenceFile
find ${JENKINS_REFERENCE} -type f -exec bash -c 'copyReferenceFile {}' \;

# if the first argument to 'docker run' starts with '--' then the user is passing jenkins launcher arguments
if (( $# == 0 )) || [[ "$1" == "--"* ]]
then
   exec java ${JAVA_OPTS} -jar ${JENKINS_WAR} ${JENKINS_OPTS} "$@" > "${JENKINS_LOG}" 2>&1
fi

# Since we're not launching Jenkins, allow the user to run another command
exec "$@"
