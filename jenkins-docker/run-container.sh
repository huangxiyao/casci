#!/bin/sh

# /tmp volume is to make container immutable

docker run --publish 8080:8080 \
           --read-only \
           --volume ~/Desktop/docker/var:/var/opt/jenkins \
           --volume ~/Desktop/docker/log:/var/log/jenkins \
           --volume ~/Desktop/docker/tmp:/tmp \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-cd
#           casci/jenkins-hpq

#           --publish 8443:8443 \
#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
