#!/bin/bash

# This file is deployed into {casfw_home}/bin so let's walk up
# the directory hierarchy to get to CASFW root directory
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

source ${CASFW_HOME}/bin/.casfwrc

hudson_home=${CASFW_HOME}/etc/hudson
trust_store_path=${CASFW_HOME}/etc/security/java6_cacerts

if [[ "$(uname)" =~ "CYGWIN" ]]; then
    hudson_home=$(cygpath -m ${hudson_home})
    trust_store_path=$(cygpath -m ${trust_store_path})
fi

default_catalina_opts="-Djava.awt.headless=true -DHUDSON_HOME=${hudson_home} -Djavax.net.ssl.trustStore=${trust_store_path}"
default_memory_opts="-Xms1024m -Xmx4g -XX:MaxPermSize=700m"

# Find the latest tomcat 6
export CATALINA_HOME="$(cd $(ls -d ${CASFW_HOME}/software/apache-tomcat-6.* | tail -n1) && pwd -P)"
export CATALINA_BASE=${CASFW_HOME}/etc/tomcat-hudson
if [ -z "${HUDSON_CATALINA_OPTS}" ]; then
    export CATALINA_OPTS="${default_catalina_opts} ${default_memory_opts}"
else
    export CATALINA_OPTS="${default_catalina_opts} ${HUDSON_CATALINA_OPTS}"
fi
export CATALINA_PID=${CASFW_HOME}/var/tomcat-hudson.pid
export DISPLAY=

${CATALINA_HOME}/bin/catalina.sh $*

 