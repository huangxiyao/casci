#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"
echo "see the CASFW_HOME is ${CASFW_HOME} ."

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

#Delete the link ${CASFW_HOME}/software/sonatype-work to ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work 
#if it exists before execution casfw-config.sh

 if [[ -L ${CASFW_HOME}/software/sonatype-work ]]; then
      rm -f ${CASFW_HOME}/software/sonatype-work 1>/dev/null 2>/dev/null
      if [ $? -ne 0 ]; then
                echo "Cannot remove soft link ${CASFW_HOME}/software/sonatype-work. Please check user's privilege."
                echo "Aborting."
                exit 35
      fi   
 fi