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

HUDSON_SLAVE_LOG_OUT=${CASFW_HOME}/var/log/hudson-slave.log
SLAVE_JAR_PATH="$(ls -d ${CASFW_HOME}/software/hudson-remoting-*.jar | tail -n1)"

#modified here: delete HUDSON_MASTER_HOST,HUDSON_MASTER_PORT,HUDSON_MASTER_APP, combine them into 3 in 1 format
HUDSON_MASTER_URL=$(grep hudson_master_url ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}' | sed 's/\\//g')
HUDSON_SLAVE_NAME=$(grep hudson_slave_name ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')
if [[ -z "$HUDSON_MASTER_URL" || -z "$HUDSON_SLAVE_NAME"   ]]; then
	echo "HUDSON_MASTER_URL and HUDSON_SLAVE_NAME variables must be set."
	echo "Aborting."
	exit 1
fi

export HUDSON_SLAVE_PID=${CASFW_HOME}/var/hudson-slave.pid
export DISPLAY=

if  [ "$1" = "start" ] ; then

  if [ ! -z "${HUDSON_SLAVE_PID}" ]; then
    if [ -f "${HUDSON_SLAVE_PID}" ]; then
      if [ -s "${HUDSON_SLAVE_PID}" ]; then
        echo "Existing PID file found during start."
        if [ -r "${HUDSON_SLAVE_PID}" ]; then
          PID=`cat "${HUDSON_SLAVE_PID}"`
          ps -p $PID >/dev/null 2>&1
          if [ $? -eq 0 ] ; then
            echo "hudson slave appears to still be running with PID $PID. Start aborted."
            exit 1
          else
            echo "Removing/clearing stale PID file."
            rm -f "${HUDSON_SLAVE_PID}" >/dev/null 2>&1
            if [ $? != 0 ]; then
              if [ -w "${HUDSON_SLAVE_PID}" ]; then
                cat /dev/null > "${HUDSON_SLAVE_PID}"
              else
                echo "Unable to remove or clear stale PID file. Start aborted."
                exit 1
              fi
            fi
          fi
        else
          echo "Unable to read PID file. Start aborted."
          exit 1
        fi
      else
        rm -f "${HUDSON_SLAVE_PID}" >/dev/null 2>&1
        if [ $? != 0 ]; then
          if [ ! -w "${HUDSON_SLAVE_PID}" ]; then
            echo "Unable to remove or write to empty PID file. Start aborted."
            exit 1
          fi
        fi
      fi
    fi
  fi

  touch "${HUDSON_SLAVE_LOG_OUT}"
  "${JAVA_HOME}/bin/java" -jar "${SLAVE_JAR_PATH}" \
      -jnlpUrl "${HUDSON_MASTER_URL}/slaveJnlp?name=${HUDSON_SLAVE_NAME}" \
      >> "${HUDSON_SLAVE_LOG_OUT}" 2>&1 &
	  
  if [ ! -z "${HUDSON_SLAVE_PID}" ]; then
    echo $! > "${HUDSON_SLAVE_PID}"
  fi
	echo "Started hudson slave successfully "
	echo "with hudson slave at ${HUDSON_MASTER_URL} with name { ${HUDSON_SLAVE_NAME} }."
	echo "Done! "

elif [ "$1" = "stop" ] ; then

	if [ -f "${HUDSON_SLAVE_PID}" ]; then
        PID=`cat "${HUDSON_SLAVE_PID}"`
        echo "Killing hudson slave with the PID: $PID"
        kill -9 $PID
        rm -f "${HUDSON_SLAVE_PID}" >/dev/null 2>&1
        if [ $? != 0 ]; then
          echo "hudson slave was killed but the PID file could not be removed."
        fi
    fi
	echo "Stopped hudson slave successfully "
	echo "with hudson slave at ${HUDSON_MASTER_URL} with name { ${HUDSON_SLAVE_NAME} }."
	echo "Done! "
else

  echo "Usage: slave.sh ( commands ... )"
  echo "commands:"
  echo "  start             Start hudson slave in a separate window"
  echo "  stop              Stop hudson slave"
  exit 1

fi

