#!/bin/bash

HOME="/opt/casfw"
userinput="$1"
nexus_dir_name="nexus-{{ casfw_nexus_release_version }}"
nexus_cdi_file="nexus-installer-{{ casfw_nexus_release_version }}.cdi"
host_name=$(hostname)
pid_file="{{ casfw_home }}/nexus/software/nexus-2.10.0-02/bin/jsw/linux-x86-64/nexus.pid"

function checkNexusInstallation {
    if [ -d {{ casfw_home }}/${nexus_dir_name} ]; then
        echo "YES"
    else 
        echo "NO"
    fi
}

function checkNexusProgress {
    if [ -f $pid_file ]; then 
 	  s=$(printf " %s " $(ps -e | grep $(cat $pid_file)) | awk '{ print $1 }'); 
 	  if [ -n "$s" ]; then 
 		echo "Running"; 
 	  fi;
    fi
}

function finalCleanup {
    cd {{ casfw_home }}
    if [ -f nexus-installer*.cdi ]; then
        rm -f nexus-installer*.cdi
    fi
    rm -f nexus-install.sh
}

function prepareInstallation {
    checkNexusProgress
    if [[ $? -eq Running ]]; then
        {{ casfw_home }}/nexus/bin/nexus.sh stop
    fi
    rm -rf {{ casfw_home }}/nexus-2*    
    echo -ne "Current Nexus stopped and deleted"
}

function downloadCdiInstall {
    cd {{ casfw_home }}
    wget -Nnv "{{ casfw_nexus_installer_url }}"
    bash ./${nexus_cdi_file} -d {{ casfw_home }}
    echo "nexus-installer - CDI Installation Complete"
}

function configureNexus {
    ln -sf {{ casfw_home }}/${nexus_dir_name}/ {{ casfw_home }}/nexus
}

function startNexus {
    {{ casfw_home }}/nexus/bin/nexus.sh start
}

$userinput
