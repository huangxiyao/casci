#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"
#Find old version config.xml file of hudson 
CONFIG_FILE="$(find ${CASFW_HOME}/../build-master* -type f -name config.xml 2>/dev/null -exec ls -1rt "{}" + | tail -n1)"
if [ -n "${CONFIG_FILE}" ]; then
    echo "Find ${CONFIG_FILE} file"
    master_home="$(ls -d ${CASFW_HOME} 2>/dev/null | tail -n1)"
    master_version="$(basename ${master_home} | sed 's/build-master-//')"
    cp ${CONFIG_FILE} ${CASFW_HOME}/old-version-config-"${master_version}".xml
else
    echo "Didn't old hudson config.xml"
fi