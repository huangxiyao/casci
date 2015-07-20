FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

# allow Unicode characters in file names
ENV LANG=en_US.UTF-8 \
    PATH=/home/jenkins/bin:$PATH \
    JENKINS_OPTS="--httpsPort=8443 --httpsKeyStorePassword=changeit" \
    JAVA_OPTS="${JAVA_OPTS} -Xms1024M -Xmx2048M -Djavax.net.ssl.trustStore=/home/jenkins/.pki/keystore.jks"

# ENV JENKINS_OPTS="${JENKINS_OPTS} --httpPort=-1"

EXPOSE 8443
VOLUME ${JENKINS_VAR} ${JENKINS_LOG} ${JENKINS_MAVEN_REPOSITORY} /tmp /home/jenkins
