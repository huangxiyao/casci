# Jenkins Docker Images

The projects in this collection implement a fully functional [Jenkins](http://jenkins-ci.org/) server.

<img src="http://jenkins-ci.org/sites/default/files/jenkins_logo.png"/>

## Overview of the images

### Jenkins
Implements a fully functional Jenkins instance. This image is based on the latest CentOS and adds the latest release of [Jenkins](http://jenkins-ci.org/) and [Java 8](http://openjdk.java.net). If you are looking for a basic Jenkins installation that you can customize yourself this is the image you want.

### Jenkins CD
Builds on the Jenkins image and adds plugins that the CAS team finds useful in building Continuous Delivery (CD) pipelines. In addition to common Jenkins plugins it includes [Java 7](http://openjdk.java.net), [Git](http://www.git-scm.com), [Maven](https://maven.apache.org) and [Ansible](http://www.ansible.com). This is the image you want if you're building a Continuous Delivery pipeline.

### Jenkins CAS
Builds on the Jenkins CD image and adds CAS-specific Jenkins jobs and scripts. This image is meant for use by the CAS team primarily to support the company separation and the use of Jenkins going forward.

## Why develop a new Jenkins image?

The [Official Jenkins Docker image](https://github.com/jenkinsci/docker) provides some of the concepts upon which these images are based. CAS feels that these images improve upon the official image with the following features.

* The images use the Linux [Filesystem Hierarchy Standard](https://en.wikipedia.org/wiki/Filesystem_Hierarchy_Standard) (FHS). This is the preferred directory layout for Linux systems.

* The containers created by these images are immutable; all mutable state is maintained in mounted volumes. This is a Docker security best-practice.

* Derived images can add plugins via their Dockerfile using the supplied `plugins.sh` utility. The official image provides similar functionality but requires the builder of the derived image to resolve transitive plugin dependencies manually.

## Basic usage

	docker run --publish 8080:8080 casci/jenkins

This will store all Jenkins work files within the Jenkins container. You may want to use a separate persistent volume container:

	docker run --publish 8080:8080 \
               --volumes-from jenkins-data \
               casci/jenkins

See the Dockerfile for the volumes you'll want to define. Refer to the Docker documentation about how to handle volumes.

## Attach build executors

Builds can be run on the master (out of the box) but if you want to attache build slave servers then map the port `--publish 50000:50000` when you connect a slave agent.

## Pass JVM parameters

It is possible to customize the JVM running Jenkins, typically to pass system properties or adjust memory settings. Use the `JAVA_OPTS` environment variable for this purpose either from the command line or in derived images.

	docker run --publish 8080:8080 \
	           --env JAVA_OPTS="-Dhudson.footerURL=http://my-company.com" \
	           casci/jenkins

## Pass Jenkins launcher parameters

Arguments passed to to Docker running the Jenkins image are passed to the Jenkins launcher, for example:

	docker run casci/jenkins --version

This will output the Jenkins version just as though you were starting Jenkins from the command line.

Jenkins parameters can also be defined with the `JENKINS_OPTS` environment variable. This is useful when customizing derived images.

	FROM casci/jenkins:latest
	ENV JENKINS_OPTS="${JENKINS_OPTS} --httpPort=-1 --httpsPort=8083"

## Explore the Jenkins container

The Jenkins `ENTRYPOINT` script, in addition to allowing you to pass parameters to the Jenkins launcher allows you to run any command within the container. If you'd like to start the container (but not Jenkins) and explore the container from a command line:

	docker run --interactive --tty \
	           --volumes-from jenkins-data \
	           casci/jenkins bash

## The Jenkins image

The Jenkins image is based on the latest CentOS and adds the latest release of Jenkins and Java 8. The image defines important file system locations as environment variables for use by derived images.

The image installs the `plugins.sh` utility. Derived images can provide a file containing the names of plugins to install and pass this file to the utility. The file should list the short name of plugins, one per line. The utility must be run as the `jenkins` user.

	FROM casci/jenkins:latest

	USER root
	COPY plugins.txt /tmp/
	RUN chown jenkins:jenkins /tmp/plugins.txt

	USER jenkins
	RUN plugins.sh /tmp/plugins.txt && rm /tmp/plugins.txt

Derived images can place content destined for `JENKINS_HOME` into `JENKINS_REFERENCE`. The content of `JENKINS_REFERENCE` is copied to `JENKINS_HOME` without overwriting the content of `JENKINS_HOME` when a container starts. This allows the initialization of `JENKINS_HOME` when it is mounted as a volume (immutability of the base image) and preserves customizations made to a Jenkins instance via the UI.

## The Jenkins CD image

The Jenkins CD image builds on the Jenkins image and adds Java 7, Git, Maven and Ansible. It includes several plugins that are useful when using Jenkins in a continuous delivery pipeline. See the file `plugins.txt` for a full list. The image defines the environment variable `JENKINS_MAVEN_REPOSITORY` for use by derived images and exposes the Maven repository directory as a volume.

## The Jenkins CAS image

The Jenkins CAS images builds on the Jenkins CD image. The image installs CAS-specific Jenkins & job configuration and establishes the framework for a secured Jenkins implementation. It enables the Jenkins HTTPS port & disables the HTTP port. SSH, SSL and Maven security settings must be provided by a mapped volume referenced by the `JENKINS_SECURE` environment variable.

## The Jenkins Data Dockerfile

For security reasons the Jenkins Data project contains only a Dockerfile. The Dockerfile builds an image that is used to create a data volume container whose volumes are mounted by a Jenkins container.

In order to create an image, add the following files to the directory containing the Dockerfile:

* `maven-settings.xml`: this will be mapped to `/home/jenkins/.m2/settings.xml`. The file should reference the repository with `<localRepository>${env.JENKINS_MAVEN_REPOSITORY}</localRepository>`.

* `ssh-private.key` & `ssh-public.key`: these will be mapped to `/home/jenkins/.ssh/casfw-dev & casfw-dev.pub`.

* `ssl-authority.crt` & `ssl-server.crt`: should contain the certificate authority certificate and server certificate respectively. These will be added to the Java keystore used by Jenkins.

Build the image (update the tag of the image as required).

	docker build --tag casci/jenkins-data-hpq:latest .

Create the container (update the name of the image & tag as required).

	docker create --name hpq-data casci/jenkins-data-hpq

## Run the Jenkins CAS image

A command similar to the following is used to run the Jenkins CAS image, mount a data volume container and a local Maven repository:

	docker run --read-only \
			   --publish 8443:8443 \
			   --volumes-from hpq-data \
			   --volume ~/Library/Caches/org.apache.maven/repository:/var/opt/jenkins/maven-repository \
			   casci/jenkins-cas
