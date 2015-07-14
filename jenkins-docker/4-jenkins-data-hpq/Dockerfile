FROM casci/jenkins-cas:latest
MAINTAINER Quintin May <quintin.may@hp.com>

WORKDIR ${JENKINS_SECURE}

USER root
COPY *.xml *.key *.crt ./
RUN chown jenkins:jenkins *.xml *.key *.crt
USER jenkins

RUN    keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -keypass changeit \
               -storepass changeit \
               -file ssl-authority.crt \
               -alias company-authority \
    && keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -keypass changeit \
               -storepass changeit \
               -file ssl-server.crt \
               -alias server

WORKDIR /home/jenkins

VOLUME ${JENKINS_VAR} ${JENKINS_LOG} ${JENKINS_MAVEN_REPOSITORY} /tmp
