#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

NEXUS_PORT=$(grep jetty_nexus_connector_http_port ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')

NEXUS_PATH=$(grep nexus_webapp_context_path ${CASFW_HOME}/etc/casfw.properties | awk -F "=" '{print $2}')

capability_file="${CASFW_HOME}/software/sonatype-work/conf/capabilities.xml"
yum_config="
    <capability>\n
      <version>1</version>\n
      <id>0003f1764c48ad75</id>\n
      <typeId>yum.generate</typeId>\n
      <properties>\n
        <property>\n
          <key>repository</key>\n
          <value>releases</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessing</key>\n
          <value>true</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessingDelay</key>\n
          <value>10</value>\n
        </property>\n
      </properties>\n
    </capability>\n
    <capability>\n
      <version>1</version>\n
      <id>0003f1764c48ad76</id>\n
      <typeId>yum.generate</typeId>\n
      <properties>\n
        <property>\n
          <key>repository</key>\n
          <value>snapshots</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessing</key>\n
          <value>true</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessingDelay</key>\n
          <value>10</value>\n
        </property>\n
      </properties>\n
    </capability>\n
    <capability>\n
      <version>1</version>\n
      <id>0003f1764c48ad79</id>\n
      <typeId>yum.generate</typeId>\n
      <properties>\n
        <property>\n
          <key>repository</key>\n
          <value>thirdparty</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessing</key>\n
          <value>true</value>\n
        </property>\n
        <property>\n
          <key>deleteProcessingDelay</key>\n
          <value>10</value>\n
        </property>\n
      </properties>\n
    </capability>\n
  </capabilities>\n
</capabilitiesConfiguration>"

if [[ -f ${capability_file} && $(cat ${capability_file}|grep -c "yum.generate") == 0 ]]; then
    sed -i 'N;$d;P;D' ${capability_file}
    echo -e ${yum_config} >> ${capability_file}
else
    echo "No capability file or YUM config already exists."
fi

echo "Please start Nexus with Jetty at http://$(hostname):${NEXUS_PORT}/${NEXUS_PATH}/"
echo "Using ${CASFW_HOME}/bin/bash nexus.sh start "

echo
echo "Please check ${CASFW_HOME}/README.txt for details of the components included"
echo "in this installation."