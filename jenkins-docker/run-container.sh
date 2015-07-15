#!/bin/sh

docker ps -a | grep hpq-data || docker create --name hpq-data casci/jenkins-data-hpq

docker run --read-only \
		   --publish 8443:8443 \
           --volumes-from hpq-data \
           --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
           casci/jenkins-cas

#           --env HTTP_PROXY="http://web-proxy.corp.hp.com:8080" \
