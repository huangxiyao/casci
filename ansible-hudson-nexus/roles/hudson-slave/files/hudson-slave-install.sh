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
    if [ -s "${hudson_pid}" ]; then
        bash "${casfw_home}/${link}/bin/slave.sh" stop
        if [[ $? -eq 0 && ! -s "${hudson_pid}" ]]; then
            echo -ne "Current Hudson slave has stopped"
        fi
    fi
    rm -rf ${casfw_home}/${link}
    rm -rf ${casfw_home}/build-slave-*
    echo -ne "Current Hudson slave has been removed"
}

function downloadCdiInstall {
    cd "${casfw_home}"
    wget -Nnv "${hudson_slave_installer_url}"
    bash "./${hudson_slave_cdi}" -d "${casfw_home}"
    echo -ne "Hudson slave - CDI Installation Complete"
}

function configureHudson {
    cd "${casfw_home}"
    ln -sf "${hudson_slave_dir}/" "${link}"
    cd "${link}/etc"
    if [ "${env}"x = "pro"x ]; then
        bash "${casfw_home}/${link}/bin/config.sh" -e pro_${host_name}
    elif [ "${env}"x = "itg"x ]; then
        bash "${casfw_home}/${link}/bin/config.sh" -e itg_${host_name}
    else
        bash "${casfw_home}/${link}/bin/config.sh" -e itg
    fi
}

function startHudson {
    bash "${casfw_home}/${link}/bin/slave.sh" start
}

$function_name