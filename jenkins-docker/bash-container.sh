#!/bin/sh

docker run --rm --interactive --tty \
           --publish 8080:8080 \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/jenkins_home/maven-repository \
           casci/jenkins-hpq bash

#           --publish 8443:8443 \
#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
