#!/bin/bash

function_name="$1"
casfw_home="$2"
build_release_version="$3"
build_master_installer_url="$4"
build_master_dir="build-master-${build_release_version}"
build_master_cdi="build-master-installer-${build_release_version}.cdi"
host_name=$(hostname)
link="ci"
pid_file="${casfw_home}/${link}/var/tomcat-hudson.pid" 

function checkHudsonInstallation {
    if [ -d "${casfw_home}/${build_master_dir}" ]; then
      echo -ne "YES"
    else 
      echo -ne "NO"
    fi
}

function checkHudsonProgress {
    if [ -f "${pid_file}" ]; then
 	  s=$(printf " %s " $(ps -e | grep $(cat "${pid_file}")) | awk '{ print $1 }');
 	  if [ -n "$s" ]; then
 	    echo -ne "Running";
 	  fi; 
    fi
}

function finalCleanup {
    cd "${casfw_home}"
    if [ -f ${build_master_cdi} ]; then
      rm -f ${build_master_cdi}
    fi
}

function prepareInstallation {
    checkHudsonProgress
    if [[ $? -eq Running ]]; then
      bash "${casfw_home}/${link}/bin/tomcat-hudson.sh" stop
    fi
    echo -ne "Current Hudson master has stopped"
}

function downloadCdiInstall {
    cd "${casfw_home}"
    wget -Nnv "${build_master_installer_url}"
    bash "./${build_master_cdi}" -d "${casfw_home}"
    echo -ne "Hudson master - CDI Installation Complete"
}

function configureHudson {
    cd "${casfw_home}"
    ln -sf "${build_master_dir}/" "${link}"
    cd "${link}/etc"
    sed -i "s/gvt1344.austin.hp.com/${host_name}:18780/g" casfw.properties.itg
    bash "${casfw_home}/${link}/bin/config.sh" -e itg
}

function startHudson {
    bash "${casfw_home}/${link}/bin/tomcat-hudson.sh" start
}

$function_name
