FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

# allow Unicode characters in file names
ENV LANG=en_US.UTF-8 \
    PATH=/home/jenkins/bin:$PATH \
    JENKINS_OPTS="${JENKINS_OPTS} --httpsKeyStore=/home/jenkins/.pki/keystore.jks --httpsKeyStorePassword=changeit" \
    JENKINS_OPTS="${JENKINS_OPTS} --httpsPort=8443"

# ENV JENKINS_OPTS="${JENKINS_OPTS} --httpPort=-1"

EXPOSE 8443
VOLUME ${JENKINS_VAR} ${JENKINS_LOG} ${JENKINS_MAVEN_REPOSITORY} /tmp /home/jenkins
