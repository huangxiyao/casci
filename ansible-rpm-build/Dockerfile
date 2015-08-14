FROM centos:7
MAINTAINER slawek.zachcial@hpe.com

ENV http_proxy http://web-proxy.corp.hp.com:8080
ENV https_proxy http://web-proxy.corp.hp.com:8080

RUN yum --assumeyes update
RUN yum --assumeyes install epel-release
RUN yum --assumeyes groupinstall "Development Tools"
RUN yum --assumeyes install rpm-build python2-devel python-setuptools asciidoc

VOLUME /out

COPY build.sh /tmp/

ENTRYPOINT ["/tmp/build.sh"]
