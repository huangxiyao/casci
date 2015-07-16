FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

# allow Unicode characters in file names
ENV LANG=en_US.UTF-8

USER root

COPY bin-migrated/ ${JENKINS_BIN}/
COPY home-migrated/ ${JENKINS_REFERENCE}/
RUN chown --recursive jenkins:jenkins ${JENKINS_BIN} ${JENKINS_REFERENCE}

USER jenkins

ENV JENKINS_OPTS="${JENKINS_OPTS} --httpsKeyStore=/home/jenkins/.pki/keystore.jks --httpsKeyStorePassword=changeit"
ENV JENKINS_OPTS="${JENKINS_OPTS} --httpsPort=8443"
# ENV JENKINS_OPTS="${JENKINS_OPTS} --httpPort=-1"

EXPOSE 8443
VOLUME /home/jenkins
