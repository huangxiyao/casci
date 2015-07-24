FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

USER root

COPY jenkins .
RUN    chown --recursive jenkins:jenkins * \
    && chmod --recursive u+rwX,go= *

RUN mkdir bin
COPY bin bin/
RUN    chown --recursive jenkins:jenkins bin \
    && chmod u=rwx,go= bin/*

COPY home ${JENKINS_HOME}
RUN    chown --recursive jenkins:jenkins ${JENKINS_HOME}/* \
    && chmod --recursive u=rw,go= ${JENKINS_HOME}/* \
    && chmod --recursive u+X ${JENKINS_HOME}/*

COPY migrate.sh company.properties keystore.sh ./
RUN    chown jenkins:jenkins migrate.sh company.properties keystore.sh \
    && chmod u+x *.sh

USER jenkins

# ================================================================================
# Prepare security related files
# ================================================================================

RUN    mv m2 .m2 \
    && mv pki .pki \
    && mv ssh .ssh

WORKDIR .pki

# install company CA for Linux utilities (git)
RUN    mkdir nssdb \
    && certutil -d nssdb -N \
    && ../keystore.sh authorityCertificate | certutil -d sql:nssdb -A -t "TCu,," -n authority

# add cacerts to keystore
RUN    chmod u+w keystore.jks \
    && keytool -importkeystore \
               -srckeystore /etc/pki/java/cacerts \
               -destkeystore keystore.jks \
               -srcstorepass changeit \
               -deststorepass changeit \
    && chmod u=r,go= keystore.jks

WORKDIR /home/jenkins

# ================================================================================
# Other set up
# ================================================================================

RUN    git config --global user.name "Jenkins" \
    && git config --global user.email "Jenkins@$(./keystore.sh hostName)"

# ================================================================================
# Migrate Jenkins scripts & configuration
# ================================================================================

RUN JENKINS_HOST=$(./keystore.sh hostName) ./migrate.sh
RUN    rm migrate.sh company.properties keystore.sh \
    && chmod u-w bin/*

# ================================================================================
# Data volume container
# ================================================================================

VOLUME ${JENKINS_VAR} ${JENKINS_LOG} /tmp /home/jenkins
CMD echo "Data container"
