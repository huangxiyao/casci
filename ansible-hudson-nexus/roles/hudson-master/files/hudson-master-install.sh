#!/bin/bash

function_name="$1"
casfw_home="$2"
hudson_master_release_version="$3"
environment="$4"
hudson_master_installer_url="http://repo1.corp.hp.com/nexus/content/repositories/releases/com/hp/it/200359/build-master-installer/${hudson_master_release_version}/build-master-installer-${hudson_master_release_version}.cdi"
hudson_master_dir="build-master-${hudson_master_release_version}"
hudson_master_cdi="build-master-installer-${hudson_master_release_version}.cdi"
host_name=$(hostname)
link="ci"
pid_file="${casfw_home}/${link}/var/tomcat-hudson.pid" 

function checkHudsonInstallation {
    if [ -d "${casfw_home}/${hudson_master_dir}" ]; then
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
    if [ -f ${hudson_master_cdi} ]; then
      rm -f ${hudson_master_cdi}
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
    wget -Nnv "${hudson_master_installer_url}"
    bash "./${hudson_master_cdi}" -d "${casfw_home}"
    echo -ne "Hudson master - CDI Installation Complete"
}

function configureHudson {
    cd "${casfw_home}"
    ln -sf "${hudson_master_dir}/" "${link}"
    cd "${link}/etc"
    if [[ ${environment} == "pro" ]]; then
        sed -i "s/build1.core.hpecorp.net/${host_name}:18780/g" casfw.properties.pro
        bash "${casfw_home}/${link}/bin/config.sh" -e pro
    else
        sed -i "s/build1-itg.core.hpecorp.net/${host_name}:18780/g" casfw.properties.itg
        bash "${casfw_home}/${link}/bin/config.sh" -e itg
    fi
}

function startHudson {
    bash "${casfw_home}/${link}/bin/tomcat-hudson.sh" start
}

$function_name