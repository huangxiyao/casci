#!/bin/bash

# This file is deployed into {casfw_home}/bin so let's walk up
# the directory hierarchy to get to CASFW root directory
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

NEXUS_LOG_OUT=${CASFW_HOME}/var/log/nexus/nexus.log

source ${CASFW_HOME}/bin/.casfwrc

trust_store_path=${CASFW_HOME}/etc/security/java6_cacerts

if [[ "$(uname)" =~ "CYGWIN" ]]; then
    trust_store_path=$(cygpath -m ${trust_store_path})
fi

# Locate the home dir where the nexus professional bundle resides
NEXUS_HOME="$(find $CASFW_HOME/software/nexus-professional-* -type d -prune)"

case "$1" in

    'console' | 'start' | 'stop' | 'restart' | 'dump' )
        touch ${NEXUS_LOG_OUT}
        bash ${NEXUS_HOME}/bin/nexus $1 >> "${NEXUS_LOG_OUT}" 2>&1 &
        ;;
    'status' )
        bash ${NEXUS_HOME}/bin/nexus $1
        ;;
    *)
        echo "Usage: $0 { console | start | stop | restart | status | dump }"
        exit 1
        ;;
esac
