#!/bin/bash

function_name="$1"
casfw_home="$2"
nexus_release_version="$3"
nexus_installer_url="http://repo1.corp.hp.com/nexus/content/repositories/releases/com/hp/it/200359/nexus-installer/${nexus_release_version}/nexus-installer-${nexus_release_version}.cdi"
nexus_dir="nexus-${nexus_release_version}"
nexus_cdi="nexus-installer-${nexus_release_version}.cdi"
host_name=$(hostname)
link="nexus"
nexus_pid="${casfw_home}/${link}/software/nexus-2.10.0-02/bin/jsw/linux-x86-64/nexus.pid"

function checkNexusInstallation {
    if [ -d "${casfw_home}/${nexus_dir}" ]; then
        echo -ne "YES"
    else
        echo -ne "NO"
    fi
}

function finalCleanup {
    cd "${casfw_home}"
    if [ -f ${nexus_cdi} ]; then
        rm -f ${nexus_cdi}
    fi
}

function prepareInstallation {
    bash "${casfw_home}/${link}/bin/nexus.sh" stop
    echo -ne "Current Nexus has been stopped"
}

function downloadCdiInstall {
    cd "${casfw_home}"
    wget -Nnv "${nexus_installer_url}"
    bash "./${nexus_cdi}" -d "${casfw_home}"
    echo -ne "Nexus - CDI Installation Complete"
}

function configureNexus {
    cd "${casfw_home}"
    rm -rf ${link}
    ln -sf "${nexus_dir}/" "${link}"
}

function startNexus {
    bash "${casfw_home}/${link}/bin/nexus.sh" start
}

$function_name