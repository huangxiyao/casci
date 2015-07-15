#!/bin/sh

./migrate-jenkins.sh hpq.properties

docker build -t casci/jenkins-cas:latest .
