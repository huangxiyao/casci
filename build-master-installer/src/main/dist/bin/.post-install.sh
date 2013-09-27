#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

# Print message about URL at which Hudson runs
tomcat_hudson_http_port=$(grep tomcat_hudson_connector_http_port ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
echo
###echo "Starting Tomcat with Hudson at http://$(hostname):${tomcat_hudson_http_port}/hudson/"
echo "Please starting Tomcat with Hudson at http://$(hostname):${tomcat_hudson_http_port}/hudson/"
###${CASFW_HOME}/bin/tomcat-hudson.sh start

tomcat_sonar_http_port=$(grep tomcat_sonar_connector_http_port ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
echo
###echo "Starting Tomcat with Sonar at http://$(hostname):${tomcat_sonar_http_port}/sonar/"
echo "Please starting Tomcat with Sonar at http://$(hostname):${tomcat_sonar_http_port}/sonar/"
###${CASFW_HOME}/bin/tomcat-sonar.sh start

echo
echo "Please check ${CASFW_HOME}/README.txt for details of the components included"
echo "in this installation."