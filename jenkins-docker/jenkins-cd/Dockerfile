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

COPY plugins.txt /tmp/

RUN chown --recursive jenkins:jenkins /home/jenkins/.m2 \
                                      /tmp/plugins.txt

USER jenkins

ENV JENKINS_MAVEN_REPOSITORY=${JENKINS_VAR}/maven-repository

RUN    mkdir ${JENKINS_MAVEN_REPOSITORY} \
    && plugins.sh /tmp/plugins.txt \
    && rm /tmp/plugins.txt

VOLUME ${JENKINS_MAVEN_REPOSITORY}
