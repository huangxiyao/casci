#!/bin/sh

docker ps -a | grep jenkins-data-hpq || docker create --name hpq-data casci/jenkins-data-hpq

docker run --rm --interactive --tty \
           --read-only \
           --publish 8080:8080 \
           --volumes-from hpq-data \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-cas bash

           #casci/jenkins-hpq bash

#           --publish 8443:8443 \
#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
