#!/bin/bash

function_name="$1"
casfw_home="$2"
hudson_master_release_version="$3"
env="$4"
hudson_master_installer_url="http://repo1.corp.hp.com/nexus/content/repositories/releases/com/hp/it/200359/build-master-installer/${hudson_master_release_version}/build-master-installer-${hudson_master_release_version}.cdi"
hudson_master_dir="build-master-${hudson_master_release_version}"
hudson_master_cdi="build-master-installer-${hudson_master_release_version}.cdi"
host_name=$(hostname)
link="ci"
hudson_pid="${casfw_home}/${link}/var/tomcat-hudson.pid"
sonar_pid="${casfw_home}/${link}/var/tomcat-sonar.pid" 

function checkHudsonInstallation {
    if [ -d "${casfw_home}/${hudson_master_dir}" ]; then
        echo -ne "YES"
    else
        echo -ne "NO"
    fi
}

function finalCleanup {
    cd "${casfw_home}"
    if [ -f ${hudson_master_cdi} ]; then
        rm -f ${hudson_master_cdi}
    fi
}

function prepareInstallation {
    bash "${casfw_home}/${link}/bin/tomcat-sonar.sh" stop
    bash "${casfw_home}/${link}/bin/tomcat-hudson.sh" stop
    echo -ne "Current Hudson master & Sonar has been stoped"
}

function downloadCdiInstall {
    cd "${casfw_home}"
    wget -Nnv "${hudson_master_installer_url}"
    bash "./${hudson_master_cdi}" -d "${casfw_home}"
    echo -ne "Hudson master - CDI Installation Complete"
}

function configureHudson {
    # MUST "cd /opt/casfw" first as pre-config.sh/post-config.sh will take relative path
    cd "${casfw_home}"
    if [ "${env}"X = "pro"X ]; then
        bash "./${hudson_master_dir}/bin/config.sh" -e pro
    elif [ "${env}"X = "itg"X ]; then
        bash "./${hudson_master_dir}/bin/config.sh" -e itg
    else
        sed -i "s/build1-itg.core.hpecorp.net/${host_name}/g" "./${hudson_master_dir}/etc/casfw.properties.itg"
        bash "./${hudson_master_dir}/bin/config.sh" -e itg
    fi
    rm -rf ${link}
    echo -ne "Old ci link is removed"
    ln -sf "${hudson_master_dir}/" "${link}"
}

function startHudson {
    bash "${casfw_home}/${link}/bin/tomcat-hudson.sh" start
    bash "${casfw_home}/${link}/bin/tomcat-sonar.sh" start
}

$function_name
