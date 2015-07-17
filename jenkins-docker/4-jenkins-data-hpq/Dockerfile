FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

COPY home .
RUN    ls -l && chown --recursive jenkins:jenkins * \
    && chmod --recursive u+rwX,go= *

USER jenkins

RUN    mv m2 .m2 \
    && mv pki .pki \
    && mv ssh .ssh

WORKDIR .pki

# install company CA for Linux utilities (git)
RUN    mkdir nssdb \
    && certutil -d nssdb -N \
    && certutil -d sql:nssdb -A -t "TCu,," -n authority -i authority.pem

# install company CA & server certificate for Java
RUN    keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -storepass changeit \
               -file authority.pem \
               -alias authority \
    && keytool -import -trustcacerts -noprompt \
               -keystore keystore.jks \
               -storepass changeit \
               -file server.pem \
               -alias server

WORKDIR /home/jenkins
VOLUME /home/jenkins
