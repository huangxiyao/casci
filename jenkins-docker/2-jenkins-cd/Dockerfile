FROM casci/jenkins:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

RUN    yum --assumeyes update \
    && yum --assumeyes install epel-release \
    && yum --assumeyes install \
			ansible \
			git \
			java-1.7.0-openjdk-devel.x86_64

# URLGRABBER_DEBUG=1 yum … for debugging

# Install Maven, yum repo has old version
RUN    cd /usr/local \
    && curl --fail --location --silent "http://www.us.apache.org/dist/maven/maven-3/3.3.3/binaries/apache-maven-3.3.3-bin.tar.gz" | tar xzf - \
    && ln -s apache-maven-3.3.3 maven \
    && cd bin && ln -s ../maven/bin/mvn mvn && cd .. \
    && chown --recursive jenkins:jenkins apache-maven-3.3.3 maven bin/mvn

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
