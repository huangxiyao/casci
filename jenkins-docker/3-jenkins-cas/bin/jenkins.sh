#!/bin/sh

umask u=rwx,g=rx,o=rx

# physical location of this script after resolving any symbolic links
SELF="$(readlink --canonicalize "$0")"
SELF_BIN="${SELF%/*}"
SELF_HOME="${SELF_BIN%/*}"

cd "${SELF_HOME}"

SELF_INSTANCE="${SELF_HOME##*/}"
case "${SELF_INSTANCE}" in
    jenkins-cas) HTTP_PORT=-1; HTTPS_PORT=2443 ;;
     jenkins-ad) HTTP_PORT=-1; HTTPS_PORT=2543 ;;
              *) echo "Unknown instance name '${SELF_INSTANCE}'" >&2; exit -1 ;;
esac

export JENKINS_HOME="${SELF_HOME}/home"

CAS_ROOT=/opt/casfw
SOFTWARE="${CAS_ROOT}/software"
export JAVA_HOME="${SOFTWARE}/openjdk7"
MAVEN_HOME="${SOFTWARE}/maven"
export PATH="${SELF_BIN}:${JAVA_HOME}/bin:${MAVEN_HOME}/bin:/usr/local/bin:/usr/bin:/bin" 
KEYSTORE="${CAS_ROOT}/ssl/keystore.jks"
KEYSTORE_PASSWORD="changeit"

PROXY_HOST="web-proxy.corp.hp.com"
PROXY_PORT=8080
NON_PROXY_HOSTS="'*.hp.com'"
HTTP_PROXY_OPTS="-Dhttp.proxyHost=${PROXY_HOST} -Dhttp.proxyPort=${PROXY_PORT} -Dhttp.nonProxyHosts=${NON_PROXY_HOSTS}"
HTTPS_PROXY_OPTS="-Dhttps.proxyHost=${PROXY_HOST} -Dhttps.proxyPort=${PROXY_PORT} -Dhttps.nonProxyHosts=${NON_PROXY_HOSTS}"
PROXY_OPTS="${HTTP_PROXY_OPTS} ${HTTPS_PROXY_OPTS}"

JAVA_OPTS="-Xms1024M -Xmx2048M ${PROXY_OPTS}"

HOST="cas-cd.corp.hp.com"
PREFIX=/jenkins
LOG=jenkins.log
JENKINS_URL="https://${HOST}:${HTTPS_PORT}${PREFIX}"
JENKINS_CLI="${JENKINS_HOME}/war/WEB-INF/jenkins-cli.jar"

# see ${JENKINS_URL}/cli/ for more commands
function jenkins
{
    java -jar "${JENKINS_CLI}" -s "${JENKINS_URL}" -i ~/.ssh/casfw-dev "$@"
}

case "$1" in
    start) nohup java ${JAVA_OPTS} -jar jenkins.war --prefix="${PREFIX}" --httpPort=${HTTP_PORT} --httpsPort=${HTTPS_PORT} --httpsKeyStore="${KEYSTORE}" --httpsKeyStorePassword="${KEYSTORE_PASSWORD}" >${LOG} 2>&1 &
           echo "Jenkins is at ${JENKINS_URL}"
           ;;
     stop) echo "Stopping Jenkins"
           jenkins safe-shutdown
           #ssh -o IdentityFile=~/.ssh/casfw-dev -p 44022 casfw@localhost safe-shutdown
           #curl -X POST --insecure "${JENKINS_URL}/exit"
           ;;
        *) jenkins "$@"
           ;;
esac

# To make Jenkins work with the 'casfw' account
# 1. In Jenkins 'Configure Global Security' add 'casfw' to the matrix with 'Administer' permission
# 2. cd $JENKINS_HOME/users
# 3. cp -r <a user that has logged in> casfw
# 4. cd casfw
# 5. vi config.xml
# 6. replace <authorizedKeys> with contents of casfw-dev.pub
# 7. clean up the file: replace <fullName> and delete <jenkins.security.LastGrantedAuthoritiesProperty>

