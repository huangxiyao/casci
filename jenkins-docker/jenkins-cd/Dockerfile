FROM casci/jenkins:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

RUN yum --assumeyes update && \
    yum --assumeyes install \
        ansible \
        git \
        java-1.7.0-openjdk-devel.x86_64 \
        maven

RUN mkdir /home/jenkins/.m2
COPY maven-settings.xml /home/jenkins/.m2/settings.xml
RUN chown --recursive jenkins:jenkins /home/jenkins/.m2

RUN    mkdir ${JENKINS_VAR}/maven-repository \
    && chown jenkins:jenkins ${JENKINS_VAR}/maven-repository

VOLUME ${JENKINS_VAR}/maven-repository

COPY plugins.txt /tmp/
RUN chown jenkins:jenkins /tmp/plugins.txt

USER jenkins

RUN    plugins.sh /tmp/plugins.txt \
    && rm /tmp/plugins.txt
