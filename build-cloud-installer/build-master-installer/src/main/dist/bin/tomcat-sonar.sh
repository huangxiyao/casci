#!/bin/bash

# This file is deployed into {casfw_home}/bin so let's walk up
# the directory hierarchy to get to CASFW root directory
USER="casfw"
umask u=rwx,g=rx,o=rx

if [ $(id -un) != "casfw" ]; then
    exec su -m "${USER}" -c "$0 $@"
fi

CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

source ${CASFW_HOME}/bin/.casfwrc

new_sonar_home="$(find ${CASFW_HOME}/software -maxdepth 1 -type d -name "sonar-*")"

#Need to keep consistent for "sonar_home" configuration in casfw_var_home and in CASFW_HOME, if not delete it in casfw_var_home and reload sonar.war from CASFW_HOME.
CASFW_VAR_DIR_HOME=$(grep casfw_var_home ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
sonar_war_properties_path=${CASFW_VAR_DIR_HOME}/var/tomcat-sonar/webapps/sonar/WEB-INF/classes/sonar-war.properties
if [ "$1" = "start" ]; then
 if [ -f "${sonar_war_properties_path}" ]; then     
    if [ -r "${sonar_war_properties_path}" ]; then    
      source ${sonar_war_properties_path}
      old_sonar_home=${SONAR_HOME}      
      if [ "${old_sonar_home}" != "${new_sonar_home}" ]; then         
         rm -fr ${CASFW_VAR_DIR_HOME}/var/tomcat-sonar/webapps/sonar
      fi
    fi
 fi
fi

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
# fix oracle database timezone issue:-Duser.timezone=America/Los_Angeles
export JAVA_OPTS="-Duser.timezone=America/Los_Angeles"


${CATALINA_HOME}/bin/catalina.sh $*
