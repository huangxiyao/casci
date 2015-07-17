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

COPY migrate.sh company.properties ./
RUN chown jenkins:jenkins migrate.sh company.properties

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

# ================================================================================
# Other set up
# ================================================================================

RUN    git config --global user.name "Jenkins" \
    && git config --global user.email "Jenkins@$(eval $(grep JENKINS_HOST company.properties); echo $JENKINS_HOST)"

# ================================================================================
# Migrate Jenkins scripts & configuration
# ================================================================================

RUN chmod u+x migrate.sh
RUN ./migrate.sh
RUN    rm migrate.sh company.properties \
    && chmod u-w bin/*

# ================================================================================
# Data volume container
# ================================================================================

VOLUME ${JENKINS_VAR} ${JENKINS_LOG} /tmp /home/jenkins
CMD echo "Data container"
