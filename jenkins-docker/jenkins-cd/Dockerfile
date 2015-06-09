FROM casci/jenkins:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

RUN yum --assumeyes update && \
    yum --assumeyes install \
        ansible \
        git \
        java-1.7.0-openjdk-devel.x86_64 \
        maven

RUN mkdir ${JENKINS_REFERENCE}/.m2
COPY maven-settings.xml ${JENKINS_REFERENCE}/.m2/settings.xml
RUN chown --recursive jenkins:jenkins ${JENKINS_REFERENCE}/.m2

RUN    mkdir ${JENKINS_HOME}/maven-repository \
    && chown jenkins:jenkins ${JENKINS_HOME}/maven-repository

VOLUME ${JENKINS_HOME}/maven-repository

COPY plugins.txt /tmp/
RUN chown jenkins:jenkins /tmp/plugins.txt

USER jenkins

RUN    plugins.sh /tmp/plugins.txt \
    && rm /tmp/plugins.txt
