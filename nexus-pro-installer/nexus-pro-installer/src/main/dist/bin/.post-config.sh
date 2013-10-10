#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

NEXUS_SONATYPE_WORK_HOME=$(grep nexus_sonatype_work_dir ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
# Find our own nexus working directory to override the default one
# Splite nexus data directory to ${NEXUS_SONATYPE_WORK_HOME}
if [ -n "${NEXUS_SONATYPE_WORK_HOME}" ]; then
	if [ ! -d ${NEXUS_SONATYPE_WORK_HOME} ];then
        mkdir -p ${NEXUS_SONATYPE_WORK_HOME}
	    if [ $? -ne 0 ]; then
            echo "Cannot create ${NEXUS_SONATYPE_WORK_HOME} directory.Please check user's privilege."
            echo "Aborting."
            exit 31
        fi
    fi

    if [[ ! -L ${CASFW_HOME}/software/sonatype-work ]]; then
	    if [[ -d ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work && "$(ls -A ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work)" ]]; then
            rm -fr ${CASFW_HOME}/software/sonatype-work 1>/dev/null 2>/dev/null
            if [ $? -ne 0 ]; then
            	echo "Cannot delete ${CASFW_HOME}/var . Please check the user's privileges"
            	echo "Aborting."
            	exit 32
            fi
        else
            mv ${CASFW_HOME}/software/sonatype-work ${NEXUS_SONATYPE_WORK_HOME}/.
            if [  $? -ne 0 ];then
                echo "Cannot move ${CASFW_HOME}/software/sonatype-work to ${NEXUS_SONATYPE_WORK_HOME}. Please check user's privilege."
                echo "Aborting."
                exit 33
            fi
        fi
        ln -sf ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work ${CASFW_HOME}/software/sonatype-work
        if [ $? -ne 0 ]; then
            echo "Cannot link ${CASFW_HOME}/software/sonatype-work to ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work. Please check user's privelege."
            echo "Aborting."
            exit 34
        fi
    else
        NEXUS_ACTUAL_SONATYPE_WORK="$(readlink ${CASFW_HOME}/software/sonatype-work)"
        if [[ "${NEXUS_ACTUAL_SONATYPE_WORK}" != "${NEXUS_SONATYPE_WORK_HOME}/sonatype-work" ]]; then
	        echo "moving ${NEXUS_ACTUAL_SONATYPE_WORK} ${NEXUS_SONATYPE_WORK_HOME}/."
            rm -f ${CASFW_HOME}/software/sonatype-work 1>/dev/null 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Cannot remove soft link ${CASFW_HOME}/software/sonatype-work. Please check user's privilege."
                echo "Aborting."
                exit 35
            fi
            mv ${NEXUS_ACTUAL_SONATYPE_WORK} ${NEXUS_SONATYPE_WORK_HOME}/. 1>/dev/null 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Cannot move ${NEXUS_ACTUAL_SONATYPE_WORK} to ${NEXUS_SONATYPE_WORK_HOME}. Please check user's privilege. "
                echo "Aborting."
                exit 36
            fi
            echo "redirecting soft link to ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work"
            echo "create soft link ${NEXUS_SONATYPE_WORK_HOME}/var pointing to ${CASFW_HOME}/software/sonatype-work. "
            ln -sf ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work ${CASFW_HOME}/software/sonatype-work
            if [ $? -ne 0 ]; then
                echo "Cannot link the ${NEXUS_SONATYPE_WORK_HOME}/sonatype-work to ${CASFW_HOME}/software/sonatype-work. Please check user's privilege."
                echo "Aborting. "
                exit 37
            fi
        fi
    fi
else
    echo "NEXUS_SONATYPE_WORK_HOME variable has not been set. "
    
    if [[ -L ${CASFW_HOME}/software/sonatype-work ]]; then
        NEXUS_VAR_ACTUAL_HOME="$(readlink ${CASFW_HOME}/software/sonatype-work)"
        echo "expected sonatype-work directory is blank, so moving ${NEXUS_VAR_ACTUAL_HOME} back to ${CASFW_HOME}/software/sonatype-work."
        echo "delete original soft link"
        rm -f ${CASFW_HOME}/software/sonatype-work 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Cannot remove soft link ${CASFW_HOME}/software/sonatype-work. Please check the user's privileges"
            echo "Aborting."
            exit 38
        fi
        mv ${NEXUS_VAR_ACTUAL_HOME} ${CASFW_HOME}/software/. 1>/dev/null 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "Cannot move ${NEXUS_VAR_ACTUAL_HOME} to ${CASFW_HOME}/software/. Please check user's privileges"
            echo "Aborting."
            exit 39
        fi
    fi
    # if NEXUS_SONATYPE_WORK_HOME is null, modify the nexus-professinal-* configuration about nexus-work directory
    for nexus_dir in $(ls -d ${CASFW_HOME}/software/nexus-professional-*); do
        nexus_config=${nexus_dir}/conf/nexus.properties
        if [ -e ${nexus_config} ]; then
            cp ${nexus_config} ${nexus_config}.ORIGINAL
            # add escapes for slashes
            safe_casfw_home=$(echo "${CASFW_HOME}" | sed 's/\//\\\//g')
            sed -i -e "s/nexus-work=\/sonatype-work/nexus-work=${safe_casfw_home}\/software\/sonatype-work/" ${nexus_config}
            diff ${nexus_config} ${nexus_config}.ORIGINAL 1>/dev/null 2>/dev/null
            # If files are the same this means sed did not find the pattern
            if [ $? -eq 0 ]; then
                echo "WARING: Unable to find nexus configuration file in ${nexus_config}"
            fi
        fi
    done
fi
echo "spliting nexus data directory successfully"

