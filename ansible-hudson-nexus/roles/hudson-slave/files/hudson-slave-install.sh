#!/bin/bash

function_name="$1"
casfw_home="$2"
hudson_slave_release_version="$3"
environment="$4"
hudson_master="$5"
hudson_slave_installer_url="http://repo1.corp.hp.com/nexus/content/repositories/releases/com/hp/it/200359/build-slave-installer/${hudson_slave_release_version}/build-slave-installer-${hudson_slave_release_version}.cdi"
hudson_slave_dir="build-slave-${hudson_slave_release_version}"
hudson_slave_cdi="build-slave-installer-${hudson_slave_release_version}.cdi"
host_name=$(hostname)
link="ci"
pid_file="${casfw_home}/${link}/var/hudson-slave.pid"

function checkHudsonInstallation {
    if [ -d "${casfw_home}/${hudson_slave_dir}" ]; then
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
    if [ -f ${hudson_slave_cdi} ]; then
        rm -f ${hudson_slave_cdi}
    fi
}

function prepareInstallation {
    checkHudsonProgress
    if [[ $? -eq Running ]]; then
        bash "${casfw_home}/${link}/bin/slave.sh" stop
    fi
    echo -ne "Current Hudson slave has stopped"
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
    # to be modified...
    sed -i "s/gvt1344.austin.hp.com/${hudson_master}/g" casfw.properties.itg
    sed -i "s/g1t1044g.austin.hp.com/${host_name}/g" casfw.properties.itg
    bash "${casfw_home}/${link}/bin/config.sh" -e itg
}

function startHudson {
    bash "${casfw_home}/${link}/bin/slave.sh" start
}

$function_name