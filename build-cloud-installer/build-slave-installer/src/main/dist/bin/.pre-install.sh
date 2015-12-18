#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

# Fix permissions
echo "Setting permissions"

# In general we want:
# - user to read+write+browse (i.e. execute for directories, and if execute for files was already there we are fine), 
# - group to read+browse, 
# - others to do nothing
chmod -R u+rwX,g=rX,o=rX ${CASFW_HOME}

# - user + group to 'execute' for slave.sh {start/stop}
chmod ug+x ${CASFW_HOME}/bin/slave*.sh

# And now we explicitely set 'execute' permissions for files we know we need
for app_dir in $(ls -d ${CASFW_HOME}/software/apache-maven-*); do
    chmod ug+x ${app_dir}/bin/mvn
    chmod ug+x ${app_dir}/bin/mvnDebug
done
for app_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-* 2>/dev/null); do
    chmod ug+x ${app_dir}/bin/*
    chmod ug+x ${app_dir}/jre/bin/*
done

#set 'execute' permissions for files in openjdk-1.7.*/bin/*
for java_dir in $(ls -d ${CASFW_HOME}/software/openjdk-java-1.7.* 2>/dev/null); do
    chmod ug+x ${java_dir}/bin/*
    chmod ug+x ${java_dir}/jre/bin/*
done

# Update Java "cacerts" file with the one that we ship and which contains HP Certificate Authority
echo "Installing HP Certificate Authority"
for java_dir in $(ls -d ${CASFW_HOME}/software/openjdk-java-1.7.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/jre/lib/security/cacerts
done
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.7.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/jre/lib/security/cacerts
done
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.6.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/jre/lib/security/cacerts
done
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.5.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java5_cacerts ${java_dir}/jre/lib/security/cacerts
done
