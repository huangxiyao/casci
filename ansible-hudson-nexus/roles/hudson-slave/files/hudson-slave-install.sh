#!/bin/bash

function_name="$1"
casfw_home="$2"
build_release_version="$3"
build_slave_installer_url="$4"
build_slave_dir="build-slave-${build_release_version}"
build_slave_cdi="build-slave-installer-${build_release_version}.cdi"
host_name=$(hostname)
link="ci"
pid_file="${casfw_home}/${link}/var/hudson-slave.pid" 
hudson_master="c4t17569.itcs.hpecorp.net:18780"

function checkHudsonInstallation {
    if [ -d ${casfw_home}/${build_slave_dir} ]; then
        echo -ne "YES"
    else 
        echo -ne "NO"
    fi
}

function checkHudsonProgress {
    if [ -f $pid_file ]; then 
 	  s=$(printf " %s " $(ps -e | grep $(cat $pid_file)) | awk '{ print $1 }'); 
 	  if [ -n "$s" ]; then 
 		echo -ne "Running"; 
 	  fi;
    fi
}

function finalCleanup {
    cd ${casfw_home}
    if [ -f ${build_slave_cdi} ]; then
      rm -f ${build_slave_cdi}
    fi
}

function prepareInstallation {
    checkHudsonProgress
    if [[ $? -eq Running ]]; then
      bash ${casfw_home}/${link}/bin/slave.sh stop
    fi   
    echo -ne "Current Hudson slave has stopped"
}

function downloadCdiInstall {
    cd ${casfw_home}
    wget -Nnv "${build_slave_installer_url}"
    bash ./${build_slave_cdi} -d ${casfw_home}
    echo -ne "Hudson slave - CDI Installation Complete"
}

function configureHudson {
    ln -sf ${casfw_home}/${build_slave_dir}/ ${casfw_home}/${link}
    cd ${casfw_home}/${link}/etc
    sed -i 's/gvt1344.austin.hp.com/${hudson_master}/g' casfw.properties.itg
    sed -i 's/g1t1044g.austin.hp.com/${host_name}/g' casfw.properties.itg
    bash ${casfw_home}/${link}/bin/config.sh -e itg
}

function startHudson {
    bash ${casfw_home}/${link}/bin/slave.sh start
}

$function_name
