TODO
====

* Implement immutable container
  * Maybe symlinks to mounted volume directories & files
  * `docker run --read-only`
* Maybe a common volume container layout:
  * `/configuration`: potentially sensitive information
  * `/persistent`: application data, backed up
  * `/transient`: not backed up, e.g. logs, pids, caches

Examples for Jenkins
--------------------
    /var/jenkins_home/             -> /persistent/jenkins/home/
    /home/jenkins/.m2/settings.xml -> /configuration/maven/settings.xml
    /home/jenkins/.m2/repository/  -> /transient/maven/repository/
    /var/log/jenkins/              -> /transient/jenkins/log/

-- or --

    /var/jenkins/                  -> /persistent/jenkins/ (VOLUME)
                                                          deploy.sqlite
                                                          home/
                                                          jenkins.log
                                                          jenkins.war
    /home/jenkins/.m2/settings.xml -> /configuration/maven/settings.xml (symbolic link)
    /home/jenkins/.m2/repository/  -> /transient/maven/repository/ (VOLUME, pro=container, dev=workstation)

Need `ENV http_proxy` in Dockerfile for `yum` and `curl`.

* comment out if developer building image on workstation

Handle at runtime: `ENV HTTP_PROXY` (set for server, unset for workstation)
