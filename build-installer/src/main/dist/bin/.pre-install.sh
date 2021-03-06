#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi
SONAR_HOME="$(find ${CASFW_HOME}/software -maxdepth 1 -type d -name "sonar-*")"

#echo "copying sonar plugin for pdfreport to ${SONAR_HOME}/extensions/plugins/."
SONAR_PDFREPORT_JAR=${CASFW_HOME}/software/sonar-pdfreport-plugin*.jar
cp -f ${SONAR_PDFREPORT_JAR} ${SONAR_HOME}/extensions/plugins/.

#echo "copying sonar plugin for timeline to ${SONAR_HOME}/extensions/plugins/."
SONAR_TIMELINE_JAR=${CASFW_HOME}/software/sonar-timeline-plugin*.jar
cp -f ${SONAR_TIMELINE_JAR} ${SONAR_HOME}/extensions/plugins/.

#echo "copying hudson plugin for sonar to ${CASFW_HOME}/etc/hudson/plugins/sonar.hpi "
HUDSON_SONAR_HPI=${CASFW_HOME}/software/sonar-*.hpi
mkdir -p ${CASFW_HOME}/etc/hudson/plugins
cp -f ${HUDSON_SONAR_HPI} ${CASFW_HOME}/etc/hudson/plugins/sonar.hpi

#echo "copying hudson plugin for maskpasswords to ${CASFW_HOME}/etc/hudson/plugins/mask-passwords.hpi "
HUDSON_MASKPASSWORDS_HPI=${CASFW_HOME}/software/mask-passwords-*.hpi
cp -f ${HUDSON_MASKPASSWORDS_HPI} ${CASFW_HOME}/etc/hudson/plugins/mask-passwords.hpi

echo "Copying Hudson plugin for Maven to ${CASFW_HOME}/etc/hudson/plugins/maven-plugin.hpi."
HUDSON_MAVEN_HPI=${CASFW_HOME}/software/maven-plugin-*.hpi
MAVEN_PLUGIN_HOME="$(cd $(ls -d ${CASFW_HOME}/software/hudson-war-* | tail -n1) && pwd -P)"
mv ${MAVEN_PLUGIN_HOME}/WEB-INF/plugins/maven-plugin.hpi ${MAVEN_PLUGIN_HOME}/WEB-INF/plugins/maven-plugin.hpi.ORIGINAL
cp -f ${HUDSON_MAVEN_HPI} ${MAVEN_PLUGIN_HOME}/WEB-INF/plugins/maven-plugin.hpi


#echo "copying hudson-security to ${CASFW_HOME}/software/hudson-war-*/WEB-INF/classes/"
HUDSON_SECURITY=${CASFW_HOME}/software/hudson-ldap-security-patch/hudson/security/
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


# Fix Hudson slow LDAP query
# Replace: groupSearchFilter = "(| (member={0}) (uniqueMember={0}) (memberUid={1}))";
#    With: groupSearchFilter = "(member={0})";
echo "Fixing Hudson slow LDAP user groups query"
for hudson_dir in $(ls -d ${CASFW_HOME}/software/hudson-*); do
    ldap_groovy=${hudson_dir}/WEB-INF/security/LDAPBindSecurityRealm.groovy
    if [ -e ${ldap_groovy} ]; then
        cp ${ldap_groovy} ${ldap_groovy}.ORIGINAL
        sed -i -e 's/groupSearchFilter = "(| (member={0}) (uniqueMember={0}) (memberUid={1}))";/groupSearchFilter = "(member={0})";/' ${ldap_groovy}
        diff ${ldap_groovy} ${ldap_groovy}.ORIGINAL 1>/dev/null 2>/dev/null
        # If file are the same this means sed didn't find the pattern
        if [ $? -eq 0 ]; then
            echo "WARNING: Unable to find Hudson LDAP search query in ${ldap_groovy}."
        fi
    fi
done


# Update Java "cacerts" file with the one that we ship and which contains HP Certificate Authority
echo "Installing HP Certificate Authority"
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.6.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java6_cacerts ${java_dir}/jre/lib/security/cacerts
done
for java_dir in $(ls -d ${CASFW_HOME}/software/oracle-java-1.5.* 2>/dev/null); do
    cp ${java_dir}/jre/lib/security/cacerts ${java_dir}/jre/lib/security/cacerts.ORIGINAL
    cp ${CASFW_HOME}/etc/security/java5_cacerts ${java_dir}/jre/lib/security/cacerts
done
