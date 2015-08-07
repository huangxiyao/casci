#! /bin/sh

set -e

: ${JAVA_OPTS:='-Xms1024M -Xmx2048M -Djdk.tls.ephemeralDHKeySize=2048'}

if [[ -n "${HTTP_PROXY}" ]]
then
	proxyHost=${HTTP_PROXY#http://}
	proxyHost=${proxyHost%:*}
	proxyPort=${HTTP_PROXY##*:}
	nonProxyHosts=$(echo "${proxyHost}" | awk -F'.' '{printf "*.%s.%s\n", $(NF-1), $(NF)}')

	JAVA_OPTS="${JAVA_OPTS} -Dhttp.proxyHost=${proxyHost} -Dhttp.proxyPort=${proxyPort} -Dhttp.nonProxyHosts=${nonProxyHosts}"
	JAVA_OPTS="${JAVA_OPTS} -Dhttps.proxyHost=${proxyHost} -Dhttps.proxyPort=${proxyPort} -Dhttps.nonProxyHosts=${nonProxyHosts}"
fi

# create VOLUME directories if required
[[ -d ${JENKINS_VAR}  ]] || mkdir --parents ${JENKINS_VAR}
[[ -d ${JENKINS_HOME} ]] || mkdir --parents ${JENKINS_HOME}
[[ -d ${JENKINS_LOG}  ]] || mkdir --parents ${JENKINS_LOG}

# Copy files from JENKINS_REFERENCE to JENKINS_HOME.
# Do not overwrite files in JENKINS_HOME.
function copyReferenceFile
{
	local sourceFile="${1%/}"

	local relative="${sourceFile#${JENKINS_REFERENCE}/}"
	local targetFile="${JENKINS_HOME}/${relative}"

	if [[ ! -e "${targetFile}" ]]
	then
		echo "$(date '+%F %T') Copy '${sourceFile}' to '${targetFile}'" >> ${JENKINS_REFERENCE_LOG_FILE}
		mkdir --parents "$(dirname "${targetFile}")"
		cp "${sourceFile}" "${targetFile}"
		# pin plugins on initial copy
		[[ "${relative}" == plugins/*.jpi ]] && touch "${targetFile}.pinned"
	fi
}

export -f copyReferenceFile
find ${JENKINS_REFERENCE} -type f -exec bash -c 'copyReferenceFile "{}"' \;
unset -f copyReferenceFile

# if the first argument to 'docker run' starts with '--' then the user is passing jenkins launcher arguments
if (( $# == 0 )) || [[ "$1" == "--"* ]]
then
   exec java ${JAVA_OPTS} -jar ${JENKINS_WAR} ${JENKINS_OPTS} "$@" > "${JENKINS_LOG_FILE}" 2>&1
fi

# Since we're not launching Jenkins, allow the user to run another command
exec "$@"
