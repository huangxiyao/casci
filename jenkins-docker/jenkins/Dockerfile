FROM centos
MAINTAINER Quintin May <quintin.may@hp.com>

# ======================================================================================================================
# Based on https://github.com/jenkinsci/docker but implements FHS, immutable containers and auto-resolution of plugin
# dependencies.
#
# Features:
# - Uses Linux Filesystem Hierarchy Standard (FHS) https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard.
# - Base container is immutable. All mutable state is in VOLUMEs.
# - Derived images can put JENKINS_HOME content into JENKINS_REFERENCE and it will be copied when the container starts.
#   Files that already exist in JENKINS_HOME will not be overwritten.
# - Derived images that wish to install Jenkins plugins should 'RUN plugins.sh plugins.txt' to cause the plugins listed
#   in plugins.txt to be installed when Jenkins is started for the first time.
# ======================================================================================================================

# Uncomment the following ENV & set the value for the HTTP proxy if a proxy is required
# 'http_proxy' is used by both 'yum' and 'curl'

# ENV http_proxy="http://web-proxy.corp.hp.com:8080"

RUN yum --assumeyes update && \
    yum --assumeyes install \
        java-1.8.0-openjdk-devel.x86_64

RUN useradd --uid 1000 \
            --create-home \
            --shell /bin/bash \
            jenkins

ENV JENKINS_BIN=/opt/jenkins/bin \
    JENKINS_REFERENCE=/opt/jenkins/ref \
    JENKINS_VAR=/var/opt/jenkins \
    JENKINS_HOME=/var/opt/jenkins/home \
    JENKINS_LOG=/var/log/jenkins

RUN mkdir --parents ${JENKINS_BIN} \
                    ${JENKINS_REFERENCE} \
                    ${JENKINS_VAR} \
                    ${JENKINS_HOME} \
                    ${JENKINS_LOG}

COPY jenkins.sh plugins.sh ${JENKINS_BIN}/
COPY *.groovy ${JENKINS_REFERENCE}/init.groovy.d/

RUN chown --recursive jenkins:jenkins \
          /opt/jenkins \
          /var/opt/jenkins \
          /var/log/jenkins

USER jenkins

RUN curl --output ${JENKINS_REFERENCE}/jenkins.war \
         --fail --location --silent \
         "http://mirrors.jenkins-ci.org/war/latest/jenkins.war"

ENV JENKINS_PLUGINS=/opt/jenkins/plugins.txt \
    JENKINS_WAR=${JENKINS_HOME}/jenkins.war \
    JENKINS_REFERENCE_LOG_FILE=${JENKINS_LOG}/reference.log \
    JENKINS_LOG_FILE=${JENKINS_LOG}/jenkins.log

ENV PATH="${JENKINS_BIN}:${PATH}"

# web interface & slave agents
EXPOSE 8080 50000

VOLUME ${JENKINS_VAR} ${JENKINS_LOG}
WORKDIR /home/jenkins
ENTRYPOINT [ "jenkins.sh" ]
