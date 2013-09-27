#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

# Sonar: regenerate the WAR file
SONAR_HOME="$(find ${CASFW_HOME}/software -maxdepth 1 -type d -name "sonar-*")"

echo "Generating ${SONAR_HOME}/war/sonar.war"
pushd ${SONAR_HOME}/war 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err

# We cannot use directly Sonar's build-war.sh as it does not export ANT_HOME which makes building .war fail
# failing in the environments in which ANT is already installed
export ANT_HOME="${SONAR_HOME}/war/apache-ant-1.7.0"
./apache-ant-1.7.0/bin/ant 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err

last_exit_code=$? 
if [ ${last_exit_code} -ne 0 ]; then
	echo "ERROR:"
    echo "  Generating ${SONAR_HOME}/war/sonar.war failed with code ${last_exit_code}."
    echo "  Please check ${CASFW_HOME}/var/log/sonar/sonar-war.err"
    echo "  and ${CASFW_HOME}/var/log/sonar/sonar-war.out for more details."
    exit ${last_exit_code}
fi 

popd 1>>${CASFW_HOME}/var/log/sonar/sonar-war.out 2>>${CASFW_HOME}/var/log/sonar/sonar-war.err
