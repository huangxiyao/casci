#!/bin/bash

function_name="$1"
casfw_home="$2"

function apacheTypeCheck {
    if [ -d /opt/cloudhost ]; then
        echo -ne "cloudhost"
    elif [ -d /opt/webhost/local ]; then
        echo -ne "webhost"
    fi
}

function copyCasfwConfToCloudApache {
    if [ ! -f /etc/httpd/conf.d/casfw.conf ]; then
        /opt/pb/bin/pbrun cp ${casfw_home}/casfw.conf /etc/httpd/conf.d/
        /opt/pb/bin/pbrun chmod 644 /etc/httpd/conf.d/casfw.conf
    fi
}

function copyCasfwConfToWebhostApache {
    if [ ! -f /opt/webhost/local/WHA-General-Inst/apache/conf.d/casfw.conf ]; then
        cp ${casfw_home}/casfw.conf /opt/webhost/local/WHA-General-Inst/apache/conf.d/
        chmod 644 /opt/webhost/local/WHA-General-Inst/apache/conf.d/casfw.conf
    fi
}

function restartCloudApacheInstance {
	sudo service httpd restart
}

function restartWebhostApacheInstance {
    /opt/webhost/whaeng/bin/restart_apache WHA-General-Inst
}

function finalCleanup {
    rm -f ${casfw_home}/casfw.conf
}

$function_name