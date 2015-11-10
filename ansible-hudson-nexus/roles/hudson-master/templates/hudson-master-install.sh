#!/bin/bash

HOME="/opt/casfw"
userinput="$1"
build_master_dir_name="build-master-{{ casfw_build_release_version }}"
build_master_cdi_file="build-master-installer-{{ casfw_build_release_version }}.cdi"
host_name=$(hostname)
pid_file="{{ casfw_home }}/ci/var/tomcat-hudson.pid" 

function checkHudsonInstallation {
    if [ -d {{ casfw_home }}/${build_master_dir_name} ]; then
        echo -ne YES
    else 
        echo -ne NO
    fi
}

function checkHudsonProgress {
    if [ -f $pid_file ]; then 
 	s=$(printf " %s " $(ps -e | grep $(cat $pid_file)) | awk '{ print $1 }'); 
 	if [ -n "$s" ]; then 
 		echo "Running"; 
 	fi; 
    fi
}

function finalCleanup {
    cd {{ casfw_home }}
    if [ -f build-master-installer*.cdi ]; then
        rm -f build-master-installer*.cdi
    fi    
}

function prepareInstallation {
    checkHudsonProgress
    if [[ $? -eq Running ]]; then
        {{ casfw_home }}/ci/bin/tomcat-hudson.sh stop
    fi
    rm -rf {{ casfw_home }}/build-master-*    
    echo -ne "Current Hudson master stopped and deleted"
}

function downloadCdiInstall {
    cd {{ casfw_home }}
    wget -Nnv "{{ casfw_build_master_installer_url }}"
    bash ./${build_master_cdi_file} -d {{ casfw_home }}
    echo "Hudson master - CDI Installation Complete"
}

function configureHudson {
    ln -sf {{ casfw_home }}/${build_master_dir_name}/ {{ casfw_home }}/ci
    cd {{ casfw_home }}/ci/etc
    sed -i 's/gvt1344.austin.hp.com/${host_name}:18780/g' casfw.properties.itg	
    bash {{ casfw_home }}/ci/bin/config.sh -e itg
}

function startHudson {
    {{ casfw_home }}/ci/bin/tomcat-hudson.sh start
}

$userinput