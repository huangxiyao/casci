#!/bin/sh

docker ps -a | grep hpq-data || docker create --name hpq-data casci/jenkins-data-hpq

docker run --rm --interactive --tty \
           --read-only \
           --publish 9080:8080 \
           --publish 9443:8443 \
           --env HTTP_PROXY=http://web-proxy.corp.hpcom:8080 \
           --volumes-from hpq-data \
           --volume /opt/casfw/var/maven-repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-cas bash
