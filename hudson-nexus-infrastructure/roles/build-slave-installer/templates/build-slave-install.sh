#!/bin/bash

HOME="/opt/casfw"
userinput="$1"
build_slave_dir_name="build-slave-{{ casfw_build_release_version }}"
build_slave_cdi_file="build-slave-installer-{{ casfw_build_release_version }}.cdi"
host_name=$(hostname)
pid_file="{{ casfw_home }}/ci/var/hudson-slave.pid" 
hudson_master_url2="c0004714.itcs.hp.com:18780"

function checkHudsonInstallation {
    if [ -d {{ casfw_home }}/${build_slave_dir_name} ]; then
        echo "YES"
    else 
        echo "NO"
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
    if [ -f build-slave-installer*.cdi ]; then
        rm -f build-slave-installer*.cdi
    fi
    rm -f build-slave-install.sh
}

function prepareInstallation {
    checkHudsonProgress
    if [[ $? -eq Running ]]; then
        {{ casfw_home }}/ci/bin/slave.sh stop
    fi
    rm -rf {{ casfw_home }}/build-slave-2*    
    echo -ne "Current Hudson slave stopped and deleted"
}

function downloadCdiInstall {
    cd {{ casfw_home }}
    wget -Nnv "{{ casfw_build_slave_installer_url }}"
    bash ./${build_slave_cdi_file} -d {{ casfw_home }}
    echo "build-slave-installer - CDI Installation Complete"
}

function configureHudson {
    ln -sf {{ casfw_home }}/${build_slave_dir_name}/ {{ casfw_home }}/ci2
    cd {{ casfw_home }}/ci2/etc
    sed -i 's/gvt1344.austin.hp.com/${hudson_master_url2}/g' casfw.properties.itg
    sed -i 's/g1t1044g.austin.hp.com/${host_name}/g' casfw.properties.itg
    bash {{ casfw_home }}/ci2/bin/config.sh -e itg
}

function startHudson {
    {{ casfw_home }}/ci2/bin/slave.sh start
}

$userinput
