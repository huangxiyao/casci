#!/bin/sh

docker run --publish 8080:8080 \
           --volume ~/Desktop/docker/var:/var/opt/jenkins \
           --volume ~/Desktop/docker/log:/var/log/jenkins \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-hpq

#           --publish 8443:8443 \
#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
