#!/bin/sh

[[ -d ~Desktop/docker ]] || mkdir -p ~/Desktop/docker/var ~/Desktop/docker/log ~/Desktop/docker/tmp

docker run --rm --interactive --tty \
           --read-only \
           --publish 8080:8080 \
           --volume ~/Desktop/docker/var:/var/opt/jenkins \
           --volume ~/Desktop/docker/log:/var/log/jenkins \
           --volume ~/Desktop/docker/tmp:/tmp \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-cd bash

           #casci/jenkins-hpq bash

#           --publish 8443:8443 \
#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
