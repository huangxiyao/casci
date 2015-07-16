FROM casci/jenkins-cas:latest
MAINTAINER Quintin May <quintin.may@hp.com>

WORKDIR ${JENKINS_SECURE}

USER root
COPY *.xml *.key *.crt ./
RUN    chown jenkins:jenkins *.xml *.key *.crt \
    && chmod u=r,go= *.xml *.key *.crt

USER jenkins

RUN    keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -storepass changeit \
               -file ssl-authority.crt \
               -alias server-authority \
    && keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -storepass changeit \
               -file ssl-server.crt \
               -alias server

VOLUME ${JENKINS_SECURE}
WORKDIR /home/jenkins
