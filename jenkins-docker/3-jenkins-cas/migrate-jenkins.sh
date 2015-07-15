#!/bin/sh

variables="$1"
[[ -z "${variables}" ]] && echo "Variables file required" && exit 1
source "${variables}"

JENKINS_URL="https://${JENKINS_HOST}"
[[ -n "${JENKINS_PORT}" ]] && JENKINS_URL="${JENKINS_URL}:${JENKINS_PORT}"
[[ -n "${JENKINS_PREFIX}" ]] && JENKINS_URL="${JENKINS_URL}${JENKINS_PREFIX}"

rm -rf bin-migrated home-migrated
cp -R bin bin-migrated
cp -R home home-migrated

# ================================================================================
# bin
# ================================================================================

pushd bin-migrated

# database.sh
sed -i "" -e 's|/opt/casfw/jenkins-cas|/var/opt/jenkins|' database.sh

# deploy: nothing to do

# jenkins.sh, replacement in image
rm jenkins.sh

# notify.sh
sed -i "" -e "s|http://web-proxy.corp.hp.com:8080|${HTTPS_PROXY}|" \
		  -e "s|2009eae853bfabcd6f3dcaad2b3b4eda|${FLOW_TOKEN}|" \
		  notify.sh

# pipeline.sh
sed -i "" -e "s|http://repo1.corp.hp.com/nexus|${NEXUS_URL}|" \
          -e "s|118361|${CAS_EPR}|" \
          -e "s|ldap.hp.com|${LDAP_HOST}|" \
          pipeline.sh

# poms.sh: nothing to do

# report.sh
sed -i "" -e "s|cgit-pro.houston.hp.com|${GIT_HOST}|" report.sh

popd

# ================================================================================
# home
# ================================================================================

pushd home-migrated

# config.xml
cat > /tmp/config.sed << END_EDITS
\|<permission>.*PM-|d
\|<permission>.*@hp.com|d
\|<permission>.*anonymous|d
\|<permission>|s|ADMIN-HUDSON-118361-DEV|anonymous|
s|ldap.hp.com|${LDAP_HOST}|
s|<managerPasswordSecret>.*</managerPasswordSecret>|<managerPasswordSecret></managerPasswordSecret>|
\|<jdks>|,\|</jdks>|c\\
  <jdks>\\
    <jdk>\\
      <name>OpenJDK 7</name>\\
      <home>/etc/alternatives/java_sdk_1.7.0</home>\\
      <properties/>\\
    </jdk>\\
    <jdk>\\
      <name>OpenJDK 8</name>\\
      <home>/etc/alternatives/java_sdk_1.8.0</home>\\
      <properties/>\\
    </jdk>\\
  </jdks>
END_EDITS

sed -i "" -f /tmp/config.sed config.xml
rm /tmp/config.sed

# credentials.xml
sed -i "" "s|cgit-pro.houston.hp.com|${GIT_HOST}|" credentials.xml
# manually update ansible_vault & TeamForge GIT passwords

# hudson.plugins.git.GitTool.xml
sed -i "" "s|/usr/local/bin/git|/usr/bin/git|" hudson.plugins.git.GitTool.xml

# sidebar-link.xml
sed -i "" "s|https://cas-cd.corp.hp.com:2443/jenkins|${JENKINS_URL}|" sidebar-link.xml

popd

# ================================================================================
# jobs
# ================================================================================

pushd home-migrated/jobs

sed -i "" "s|cgit-pro.houston.hp.com|${GIT_HOST}|" */config.xml

popd
