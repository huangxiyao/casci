#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

echo "Setting up Maven"
if ${cygwin}; then
    echo "Please update your $HOME/.m2/settings.xml"
    echo "file so it contains all the settings present in"
    echo "${CASFW_HOME}/etc/maven/settings.xml"
elif [[ ! -e $HOME/.m2/settings.xml && ! -L $HOME/.m2/settings.xml ]]; then
    if [[ ! -d $HOME/.m2 ]]; then
        mkdir $HOME/.m2
    fi
    echo "Copying ${CASFW_HOME}/etc/maven/settings.xml to $HOME/.m2"
    cp ${CASFW_HOME}/etc/maven/settings.xml $HOME/.m2
else
    echo "WARNING:"
    echo "  $HOME/.m2/settings.xml already exists."
    echo "  Please update it so it contains all the settings present in"
    echo "  ${CASFW_HOME}/etc/maven/settings.xml"
fi

# Print message about URL at which Hudson runs
tomcat_hudson_http_port=$(grep tomcat_hudson_connector_http_port ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
echo
echo "Starting Tomcat with Hudson at http://$(hostname):${tomcat_hudson_http_port}/hudson/"
${CASFW_HOME}/bin/tomcat-hudson.sh start

echo
echo "Please check ${CASFW_HOME}/README.txt for details of the components included"
echo "in this installation."