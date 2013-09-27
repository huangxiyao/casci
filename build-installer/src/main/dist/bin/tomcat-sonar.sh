#!/bin/bash

# This file is deployed into {casfw_home}/bin so let's walk up
# the directory hierarchy to get to CASFW root directory
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

source ${CASFW_HOME}/bin/.casfwrc

trust_store_path=${CASFW_HOME}/etc/security/java6_cacerts
derby_log_path=${CASFW_HOME}/var/log/sonar/derby.log

if [[ "$(uname)" =~ "CYGWIN" ]]; then
    trust_store_path=$(cygpath -m ${trust_store_path})
    derby_log_path=$(cygpath -m ${derby_log_path})
fi

default_catalina_opts="-Dorg.apache.jasper.runtime.BodyContentImpl.LIMIT_BUFFER=true -Djava.awt.headless=true -Djavax.net.ssl.trustStore=${trust_store_path} -Dderby.stream.error.file=${derby_log_path}"
default_memory_opts="-Xms1024m -Xmx1024m -XX:MaxPermSize=256m"

# Find the latest tomcat 6
export CATALINA_HOME="$(cd $(ls -d ${CASFW_HOME}/software/apache-tomcat-6.* | tail -n1) && pwd -P)"
export CATALINA_BASE=${CASFW_HOME}/etc/tomcat-sonar
if [ -z "${SONAR_CATALINA_OPTS}" ]; then
    export CATALINA_OPTS="${default_catalina_opts} ${default_memory_opts}"
else
    export CATALINA_OPTS="${default_catalina_opts} ${SONAR_CATALINA_OPTS}"
fi
export CATALINA_PID=${CASFW_HOME}/var/tomcat-sonar.pid
export DISPLAY=

${CATALINA_HOME}/bin/catalina.sh $*
 