#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"
echo "see the CASFW_HOME is ${CASFW_HOME} ."

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

echo "Creating Nexus log link"
NEXUS_HOME="$(cd $(ls -d ${CASFW_HOME}/software/nexus-* | tail -n1) && pwd -P)"
echo ${NEXUS_HOME}
ln -sf ${NEXUS_HOME}/logs ${CASFW_HOME}/var/log/nexus
echo "${CASFW_HOME}/var/log"
if [ $? -ne 0 ]; then
    echo "Cannot create ${CASFW_HOME}/var/log link. Please check user's privilege"
    echo "Aborting."
    exit 33
fi

# Fix permissions
echo "Setting permissions"

# In general we want:
# - user to read+write+browse (i.e. execute for directories, and if execute for files was already there we are fine), 
# - group to read+browse, 
# - others to do nothing
chmod -R u+rwX,g=rX,o= ${CASFW_HOME}

# And now we explicitely set 'execute' permissions for files we know we need
chmod ug+x ${CASFW_HOME}/bin/*.sh

for app_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-* 2>/dev/null); do
    chmod ug+x ${app_dir}/bin/*
    chmod ug+x ${app_dir}/jre/bin/*
done

for app_dir in $(ls -d ${CASFW_HOME}/software/nexus-* 2>/dev/null); do
    chmod -R ug+x ${app_dir}/bin
done

# Update Java "cacerts" file with the one that we ship and which contains HP Certificate Authority
echo "Installing HP Certificate Authority"
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.7.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/jre/lib/security/cacerts
done

