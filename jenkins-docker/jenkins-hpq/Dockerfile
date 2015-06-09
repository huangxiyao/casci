FROM casci/jenkins-cd:latest
MAINTAINER Quintin May <quintin.may@hp.com>

# RUN curl --fail --location --silent --insecure "https://digitalbadge.corp.hp.com/hp/CAs/hpca2ssG2_ns.crt" | \
#     keytool -import -trustcacerts -noprompt \
#             -alias root \
#             -keystore ${JENKINS_REFERENCE}/keystore.jks \
#             -keypass changeit \
#             -storepass changeit
#
# ENV JENKINS_OPTS="${JENKINS_OPTS} --httpsKeyStore=${JENKINS_HOME}/keystore.jks --httpsKeyStorePassword=changeit --httpPort=-1 --httpsPort=8443"
# EXPOSE 8443

USER root

COPY maven-settings.xml ${JENKINS_REFERENCE}/.m2/settings.xml
RUN chown jenkins:jenkins ${JENKINS_REFERENCE}/.m2/settings.xml

USER jenkins
