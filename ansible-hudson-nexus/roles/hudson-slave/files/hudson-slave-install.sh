#!/bin/bash

function_name="$1"
casfw_home="$2"
hudson_slave_release_version="$3"
env="$4"
hudson_slave_installer_url="http://repo1.corp.hp.com/nexus/content/repositories/releases/com/hp/it/200359/build-slave-installer/${hudson_slave_release_version}/build-slave-installer-${hudson_slave_release_version}.cdi"
hudson_slave_dir="build-slave-${hudson_slave_release_version}"
hudson_slave_cdi="build-slave-installer-${hudson_slave_release_version}.cdi"
host_name=$(hostname)
link="ci"
hudson_pid="${casfw_home}/${link}/var/hudson-slave.pid"

function checkHudsonInstallation {
    if [ -d "${casfw_home}/${hudson_slave_dir}" ]; then
        echo -ne "YES"
    else
        echo -ne "NO"
    fi
}

function finalCleanup {
    cd "${casfw_home}"
    if [ -f ${hudson_slave_cdi} ]; then
        rm -f ${hudson_slave_cdi}
    fi
}

function prepareInstallation {
    bash "${casfw_home}/${link}/bin/slave.sh" stop
    echo -ne "Current Hudson slave has been stopped"
}

function downloadCdiInstall {
    cd "${casfw_home}"
    wget -Nnv "${hudson_slave_installer_url}"
    bash "./${hudson_slave_cdi}" -d "${casfw_home}"
    echo -ne "Hudson slave - CDI Installation Complete"
}

function configureHudson {
    cd "${casfw_home}"
    rm -rf ${link}
    ln -sf "${hudson_slave_dir}/" "${link}"
    if [ "${env}"X = "dev"X ]; then
        bash "${casfw_home}/${link}/bin/config.sh" -e itg
    else
        bash "${casfw_home}/${link}/bin/config.sh" -e ${env}_${host_name}
    fi
}

function startHudson {
    bash "${casfw_home}/${link}/bin/slave.sh" start
}

$function_name
