FROM centos
MAINTAINER Quintin May <quintin.may@hp.com>

# ======================================================================================================================
# Based on https://github.com/jenkinsci/docker
#
# /usr/share/jenkins/ref contains reference configuration used for a new installation. Put additional plugins or
# configuration there to package it with your Docker image. The files are copied to JENKINS_HOME.
#
# /usr/local/bin/plugins.sh can be used from a derived Dockerfile: 'RUN plugins.sh plugins.txt' to install plugins to
# /usr/share/jenkins/ref/plugins.
# ======================================================================================================================

# Uncomment the following ENV & set the value for the HTTP proxy if a proxy is required
# 'http_proxy' is used by both 'yum' and 'curl'

# ENV http_proxy="http://web-proxy.corp.hp.com:8080"

RUN yum --assumeyes update && \
    yum --assumeyes install \
        java-1.8.0-openjdk-devel.x86_64

ENV JENKINS_HOME="/var/jenkins_home" \
    JENKINS_REFERENCE="/usr/share/jenkins/ref" \
    JENKINS_WAR="/usr/share/jenkins/jenkins.war" \
    JENKINS_PLUGINS="/usr/share/jenkins/plugins.txt" \
    COPY_REFERENCE_FILE_LOG="/var/log/jenkins/copy_reference_file.log" \
    JENKINS_LOG="/var/log/jenkins/jenkins.log"

RUN useradd --home "${JENKINS_HOME}" \
            --uid 1000 \
            --create-home \
            --shell /bin/bash \
            jenkins

RUN    mkdir --parents /usr/share/jenkins \
    && touch ${JENKINS_PLUGINS} \
    && curl --output ${JENKINS_WAR} \
            --fail --location --silent \
            "http://mirrors.jenkins-ci.org/war/latest/jenkins.war" \
    && chown --recursive jenkins:jenkins /usr/share/jenkins

RUN mkdir --parents ${JENKINS_REFERENCE}/init.groovy.d
COPY *.groovy ${JENKINS_REFERENCE}/init.groovy.d/
RUN chown --recursive jenkins:jenkins ${JENKINS_REFERENCE}

RUN    mkdir --parents $(dirname ${COPY_REFERENCE_FILE_LOG}) $(dirname ${JENKINS_LOG}) \
    && touch ${COPY_REFERENCE_FILE_LOG} ${JENKINS_LOG} \
    && chown --recursive jenkins:jenkins $(dirname ${COPY_REFERENCE_FILE_LOG}) $(dirname ${JENKINS_LOG})

COPY jenkins.sh plugins.sh /usr/local/bin/
RUN chown jenkins:jenkins /usr/local/bin/jenkins.sh /usr/local/bin/plugins.sh

VOLUME ${JENKINS_HOME}

# web interface & slave agents
EXPOSE 8080 50000

USER jenkins
WORKDIR ${JENKINS_HOME}
ENTRYPOINT [ "/usr/local/bin/jenkins.sh" ]
