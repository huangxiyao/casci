FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

COPY bin/ ${JENKINS_BIN}/
COPY home/ ${JENKINS_REFERENCE}/
RUN chown --recursive jenkins:jenkins ${JENKINS_BIN} ${JENKINS_REFERENCE}

USER jenkins

ENV JENKINS_SECURE=/opt/jenkins/secure

RUN mkdir ${JENKINS_SECURE}
VOLUME ${JENKINS_SECURE}

# replace Maven settings with symbolic link

RUN    rm /home/jenkins/.m2/settings.xml \
    && ln --symbolic ${JENKINS_SECURE}/maven-settings.xml /home/jenkins/.m2/settings.xml

RUN    mkdir /home/jenkins/.ssh \
    && chmod u=rwx,go= /home/jenkins/.ssh \
    && ln --symbolic ${JENKINS_SECURE}/ssh-private.key /home/jenkins/.ssh/casfw-dev \
    && ln --symbolic ${JENKINS_SECURE}/ssh-public.key /home/jenkins/.ssh/casfw-dev.pub
