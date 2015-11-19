#!/bin/bash

function_name="$1"
casfw_home="$2"
nexus_release_version="$3"
nexus_installer_url="$4"
nexus_dir="nexus-${nexus_release_version}"
nexus_cdi="nexus-installer-${nexus_release_version}.cdi"
host_name=$(hostname)
link="nexus"
pid_file="${casfw_home}/${link}/software/nexus-2.10.0-02/bin/jsw/linux-x86-64/nexus.pid"

function checkNexusInstallation {
    if [ -d ${casfw_home}/${nexus_dir} ]; then
      echo -ne "YES"
    else 
      echo -ne "NO"
    fi
}

function checkNexusProgress {
    if [ -f $pid_file ]; then 
 	  s=$(printf " %s " $(ps -e | grep $(cat $pid_file)) | awk '{ print $1 }'); 
 	  if [ -n "$s" ]; then 
 		echo -ne "Running"; 
 	  fi;
    fi
}

function finalCleanup {
    cd ${casfw_home}
    if [ -f ${nexus_cdi} ]; then
      rm -f ${nexus_cdi}
    fi
}

function prepareInstallation {
    checkNexusProgress
    if [[ $? -eq Running ]]; then
      bash ${casfw_home}/${link}/bin/nexus.sh stop
    fi    
    echo -ne "Current Nexus has stopped"
}

function downloadCdiInstall {
    cd ${casfw_home}
    wget -Nnv "${nexus_installer_url}"
    bash ./${nexus_cdi} -d ${casfw_home}
    echo -ne "Nexus - CDI Installation Complete"
}

function configureNexus {
    ln -sf ${casfw_home}/${nexus_dir}/ ${casfw_home}/${link}
}

function startNexus {
    bash ${casfw_home}/${link}/bin/nexus.sh start
}

$function_name