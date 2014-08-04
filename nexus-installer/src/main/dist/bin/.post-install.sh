#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

NEXUS_PORT=$(grep jetty_nexus_connector_http_port ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')

NEXUS_PATH=$(grep nexus_webapp_context_path ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')

echo "Please start Nexus with Jetty at http://$(hostname):${NEXUS_PORT}/${NEXUS_PATH}/"
echo "Using ${CASFW_HOME}/bin/bash nexus.sh start "

echo
echo "Please check ${CASFW_HOME}/README.txt for details of the components included"
echo "in this installation."