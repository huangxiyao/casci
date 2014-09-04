#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

SONAR_HOME="$(find ${CASFW_HOME}/software -maxdepth 1 -type d -name "sonar-*")"
#echo "copying Oracle jdbc-driver to ${SONAR_HOME}/extensions/jdbc-driver/oracle/."
ORACLE_JDBC_DRIVER=${CASFW_HOME}/software/ojdbc*.jar
cp -f ${ORACLE_JDBC_DRIVER} ${SONAR_HOME}/extensions/jdbc-driver/oracle/.

#echo "copying sonar plugin for pdfreport to ${SONAR_HOME}/extensions/plugins/."
SONAR_PDFREPORT_JAR=${CASFW_HOME}/software/sonar-pdfreport-plugin*.jar
cp -f ${SONAR_PDFREPORT_JAR} ${SONAR_HOME}/extensions/plugins/.

#echo "copying sonar plugin for timeline to ${SONAR_HOME}/extensions/plugins/."
SONAR_TIMELINE_JAR=${CASFW_HOME}/software/sonar-timeline-plugin*.jar
cp -f ${SONAR_TIMELINE_JAR} ${SONAR_HOME}/extensions/plugins/.

#echo "copying hudson plugin for sonar to ${CASFW_HOME}/etc/hudson/plugins/sonar.hpi "
HUDSON_SONAR_HPI=${CASFW_HOME}/software/sonar-*.hpi
cp -f ${HUDSON_SONAR_HPI} ${CASFW_HOME}/etc/hudson/plugins/sonar.hpi

#echo "copying hudson plugin for msbuild to ${CASFW_HOME}/etc/hudson/plugins/msbuild.hpi "
HUDSON_MSBUILD_HPI=${CASFW_HOME}/software/msbuild-*.hpi
cp -f ${HUDSON_MSBUILD_HPI} ${CASFW_HOME}/etc/hudson/plugins/msbuild.hpi

#echo "copying hudson plugin for mstest to ${CASFW_HOME}/etc/hudson/plugins/mstest.hpi "
HUDSON_MSTEST_HPI=${CASFW_HOME}/software/mstest-*.hpi
cp -f ${HUDSON_MSTEST_HPI} ${CASFW_HOME}/etc/hudson/plugins/mstest.hpi

#echo "copying hudson plugin for powershell to ${CASFW_HOME}/etc/hudson/plugins/powershell.hpi "
HUDSON_POWERSHELL_HPI=${CASFW_HOME}/software/powershell-*.hpi
cp -f ${HUDSON_POWERSHELL_HPI} ${CASFW_HOME}/etc/hudson/plugins/powershell.hpi

#echo "copying hudson plugin for maskpasswords to ${CASFW_HOME}/etc/hudson/plugins/mask-passwords.hpi "
HUDSON_MASKPASSWORDS_HPI=${CASFW_HOME}/software/mask-passwords-*.hpi
cp -f ${HUDSON_MASKPASSWORDS_HPI} ${CASFW_HOME}/etc/hudson/plugins/mask-passwords.hpi

#echo "copying hudson plugin for nestedview to ${CASFW_HOME}/etc/hudson/plugins/nested-view.hpi "
HUDSON_NESTEDVIEW_HPI=${CASFW_HOME}/software/nested-view-*.hpi
cp -f ${HUDSON_NESTEDVIEW_HPI} ${CASFW_HOME}/etc/hudson/plugins/nested-view.hpi

#echo "copying hudson plugin for Exclusive Execution to ${CASFW_HOME}/etc/hudson/plugins/exclusive-execution.hpi "
HUDSON_NESTEDVIEW_HPI=${CASFW_HOME}/software/exclusive-execution-*.hpi
cp -f ${HUDSON_NESTEDVIEW_HPI} ${CASFW_HOME}/etc/hudson/plugins/exclusive-execution.hpi

#echo "add bundle plugins."
#echo "copying hudson plugin for cvs to ${CASFW_HOME}/etc/hudson/plugins/cvs.hpi "
HUDSON_CVS_HPI=${CASFW_HOME}/software/cvs-*.hpi
cp -f ${HUDSON_CVS_HPI} ${CASFW_HOME}/etc/hudson/plugins/cvs.hpi

#echo "copying hudson plugin for git to ${CASFW_HOME}/etc/hudson/plugins/git.hpi "
HUDSON_GIT_HPI=${CASFW_HOME}/software/git-*.hpi
cp -f ${HUDSON_GIT_HPI} ${CASFW_HOME}/etc/hudson/plugins/git.hpi

#echo "copying hudson plugin for maven-plugin to ${CASFW_HOME}/etc/hudson/plugins/maven-plugin.hpi "
HUDSON_MAVENPLUGIN_HPI=${CASFW_HOME}/software/maven-plugin-*.hpi
cp -f ${HUDSON_MAVENPLUGIN_HPI} ${CASFW_HOME}/etc/hudson/plugins/maven-plugin.hpi

#echo "copying hudson plugin for maven3-plugin to ${CASFW_HOME}/etc/hudson/plugins/maven3-plugin.hpi "
HUDSON_MAVEN3PLUGIN_HPI=${CASFW_HOME}/software/maven3-plugin-*.hpi
cp -f ${HUDSON_MAVEN3PLUGIN_HPI} ${CASFW_HOME}/etc/hudson/plugins/maven3-plugin.hpi

#echo "copying hudson plugin for maven3-snapshots to ${CASFW_HOME}/etc/hudson/plugins/maven3-snapshots.hpi "
HUDSON_MAVEN3SNAPSHOTS_HPI=${CASFW_HOME}/software/maven3-snapshots-*.hpi
cp -f ${HUDSON_MAVEN3SNAPSHOTS_HPI} ${CASFW_HOME}/etc/hudson/plugins/maven3-snapshots.hpi

#echo "copying hudson plugin for rest-plugin to ${CASFW_HOME}/etc/hudson/plugins/rest-plugin.hpi "
HUDSON_RESTPLUGIN_HPI=${CASFW_HOME}/software/rest-plugin-*.hpi
cp -f ${HUDSON_RESTPLUGIN_HPI} ${CASFW_HOME}/etc/hudson/plugins/rest-plugin.hpi

#echo "copying hudson plugin for ssh-slaves to ${CASFW_HOME}/etc/hudson/plugins/ssh-slaves.hpi "
HUDSON_SSHSLAVES_HPI=${CASFW_HOME}/software/ssh-slaves-*.hpi
cp -f ${HUDSON_SSHSLAVES_HPI} ${CASFW_HOME}/etc/hudson/plugins/ssh-slaves.hpi

#echo "copying hudson plugin for subversion to ${CASFW_HOME}/etc/hudson/plugins/subversion.hpi "
HUDSON_SUBVERSION_HPI=${CASFW_HOME}/software/subversion-*.hpi
cp -f ${HUDSON_SUBVERSION_HPI} ${CASFW_HOME}/etc/hudson/plugins/subversion.hpi

#echo "copying hudson-security to ${CASFW_HOME}/software/hudson-war-*/WEB-INF/classes/"
HUDSON_SECURITY=${CASFW_HOME}/software/hudson-custom-package/hudson/security/
cp -fr ${HUDSON_SECURITY} ${CASFW_HOME}/software/hudson-war-*/WEB-INF/classes/hudson/.

# Create Tomcat instances
TOMCAT_HOME="$(cd $(ls -d ${CASFW_HOME}/software/apache-tomcat-6.* | tail -n1) && pwd -P)"

# Create Tomcat Hudson instance
TOMCAT_HUDSON_HOME="${CASFW_HOME}/etc/tomcat-hudson"
echo "Creating Tomcat instance for ${TOMCAT_HOME}"
echo "in ${TOMCAT_HUDSON_HOME}"

cp -R ${TOMCAT_HOME}/conf ${TOMCAT_HUDSON_HOME}

mkdir -p ${CASFW_HOME}/var/log/tomcat-hudson
ln -sf ${CASFW_HOME}/var/log/tomcat-hudson ${TOMCAT_HUDSON_HOME}/logs

if ${cygwin}; then
    mkdir ${TOMCAT_HUDSON_HOME}/temp
    mkdir ${TOMCAT_HUDSON_HOME}/webapps
    mkdir ${TOMCAT_HUDSON_HOME}/work
else
    mkdir -p ${CASFW_HOME}/var/tomcat-hudson/temp
    mkdir -p ${CASFW_HOME}/var/tomcat-hudson/webapps
    mkdir -p ${CASFW_HOME}/var/tomcat-hudson/work

    # ${CASFW_HOME}/etc/tomcat-hudson should already exist as we will copy conf files there
    ln -sf ${CASFW_HOME}/var/tomcat-hudson/temp ${TOMCAT_HUDSON_HOME}/temp
    ln -sf ${CASFW_HOME}/var/tomcat-hudson/webapps ${TOMCAT_HUDSON_HOME}/webapps
    ln -sf ${CASFW_HOME}/var/tomcat-hudson/work ${TOMCAT_HUDSON_HOME}/work
fi

# Create Tomcat Sonar instance
TOMCAT_SONAR_HOME="${CASFW_HOME}/etc/tomcat-sonar"
echo "Creating Tomcat instance for ${TOMCAT_HOME}"
echo "in ${TOMCAT_SONAR_HOME}"

cp -R ${TOMCAT_HOME}/conf ${TOMCAT_SONAR_HOME}

mkdir -p ${CASFW_HOME}/var/log/tomcat-sonar
ln -sf ${CASFW_HOME}/var/log/tomcat-sonar ${TOMCAT_SONAR_HOME}/logs

if ${cygwin}; then
    mkdir ${TOMCAT_SONAR_HOME}/temp
    mkdir ${TOMCAT_SONAR_HOME}/webapps
    mkdir ${TOMCAT_SONAR_HOME}/work
else
    mkdir -p ${CASFW_HOME}/var/tomcat-sonar/temp
    mkdir -p ${CASFW_HOME}/var/tomcat-sonar/webapps
    mkdir -p ${CASFW_HOME}/var/tomcat-sonar/work

    # ${CASFW_HOME}/etc/tomcat-sonar should already exist as we will copy conf files there
    ln -sf ${CASFW_HOME}/var/tomcat-sonar/temp ${TOMCAT_SONAR_HOME}/temp
    ln -sf ${CASFW_HOME}/var/tomcat-sonar/webapps ${TOMCAT_SONAR_HOME}/webapps
    ln -sf ${CASFW_HOME}/var/tomcat-sonar/work ${TOMCAT_SONAR_HOME}/work
fi


# Setup Hudson configuration
echo "Creating Hudson jobs directory"
if ${cygwin}; then
    mkdir -p ${CASFW_HOME}/etc/hudson/jobs
else
    mkdir -p ${CASFW_HOME}/var/hudson-jobs
    ln -sf ${CASFW_HOME}/var/hudson-jobs ${CASFW_HOME}/etc/hudson/jobs
fi


# Sonar conf dir
echo "Creating symbolic link to Sonar conf directory"
ln -sf ${SONAR_HOME}/conf ${CASFW_HOME}/etc/sonar

# Setup other /var directories
echo "Creating Maven local repository"
mkdir -p ${CASFW_HOME}/var/maven-repository
echo "Creating Sonar log directory"
mkdir -p ${CASFW_HOME}/var/log/sonar

# Fix permissions
echo "Setting permissions"

# In general we want:
# - user to read+write+browse (i.e. execute for directories, and if execute for files was already there we are fine), 
# - group to read+browse, 
# - others to do nothing
chmod -R u+rwX,g=rX,o= ${CASFW_HOME}

# And now we explicitely set 'execute' permissions for files we know we need
chmod ug+x ${CASFW_HOME}/bin/*.sh
for app_dir in $(ls -d ${CASFW_HOME}/software/apache-tomcat-*); do
    chmod ug+x ${app_dir}/bin/*.sh
done
for app_dir in $(ls -d ${CASFW_HOME}/software/apache-maven-*); do
    chmod ug+x ${app_dir}/bin/mvn
    chmod ug+x ${app_dir}/bin/mvnDebug
done
for app_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-* 2>/dev/null); do
    chmod ug+x ${app_dir}/bin/*
    chmod ug+x ${app_dir}/jre/bin/*
done
chmod ug+x ${SONAR_HOME}/war/build-war.sh
chmod ug+x ${SONAR_HOME}/war/apache-ant-*/bin/*

#set 'execute' permissions for files in java-1.7.0-openjdk-1.7.*/bin/*
for java_dir in $(ls -d ${CASFW_HOME}/software/openjdk-java-1.7.* 2>/dev/null); do
    chmod ug+x ${java_dir}/usr/lib/jvm/java-1.7.0-openjdk-1.7.*/bin/*
    chmod ug+x ${java_dir}/usr/lib/jvm/java-1.7.0-openjdk-1.7.*/jre/bin/*
    chmod ug+x ${java_dir}/bin/*
done

# Fix Hudson slow LDAP query
# Replace: groupSearchFilter = "(| (member={0}) (uniqueMember={0}) (memberUid={1}))";
#    With: groupSearchFilter = "(member={0})";
# do this in the hudson/security/LDAPSecurityRealm.java

# Update Java "cacerts" file with the one that we ship and which contains HP Certificate Authority
echo "Installing HP Certificate Authority"
for java_dir in $(ls -d ${CASFW_HOME}/software/openjdk-java-1.7.* 2>/dev/null); do
    cp ${java_dir}/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.65.x86_64/jre/lib/security/cacerts ${java_dir}/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.65.x86_64/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.65.x86_64/jre/lib/security/cacerts
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
