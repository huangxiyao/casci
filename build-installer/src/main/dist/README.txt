
CAS Build Environment
=====================

In the below sections $CASFW_HOME refers to the directory in which this README.txt
file is located. It should be replaced with the actual directory path.


Distribution Configuration
--------------------------

The most common configuration parameters have been extracted as tokens and placed
in $CASFW_HOME/etc/casfw.properties. The files which contain the tokens (@@xyz@@)
have ".casfwcfg" extension.
To update the configuration values, change them in $CASFW_HOME/etc/casfw.properties
and run the follwoing command:

  promtp> $CASFW_HOME/bin/config.sh

This will backup your existing files and regenerate based on *.casfwcfg files
and the values in $CASFW_HOME/etc/casfw.properties. This token-based configuration
approach will simplify the automated migration to newer versions of this
distribution.

In addition, if your environment requires additional environment variables you can
add it to $HOME/.casfwrc file. This file is sources by all the commands in this
distribution.


Hudson
------

Hudson can be started/stopped using the following commands:

  prompt> $CASFW_HOME/bin/tomcat-hudson.sh start
  prompt> $CASFW_HOME/bin/tomcat-hudson.sh stop

After starting, Hudson will be available at http://{your host}:8780/hudson/.
The port can be changed by updating $CASFW_HOME/etc/casfw.properties and running
config.sh as explained above.

Hudson web application is protected by the LDAP groups: ADMIN-{epr_id}-DEV and
USERS-{epr_id}-DEV. You can create these groups at https://directoryworks.core.hp.com/.
People belonging to the first group will be able to manage Hudson installation
and jobs, the second group members will be able to manually run jobs.


Sonar
-----

Sonar can be started/stopped using the following commands:

  prompt> $CASFW_HOME/bin/tomcat-sonar.sh start
  prompt> $CASFW_HOME/bin/tomcat-sonar.sh stop

After starting, Sonar will be available at http://{your host}:8580/sonar/.
The port can be changed by updating $CASFW_HOME/etc/casfw.properties and running
config.sh as explained above.


Maven
-----

Maven settings are available in $CASFW_HOME/etc/maven/settings.xml. If you have
your own $HOME/.m2/settings.xml file, please update it so it contains the settings
present in the distribution-provided file.


Subversion
----------

Subversion is not provided in this distribution but is required if you want to
Maven-release your artifacts from Hudson. Subversion can usually be installed
using the following command (requires root access):

  prompt> yum install subversion


This will include 'svn' application in your PATH. If subversion is installed
in a location which is not available in your PATH (e.g. /opt/Subversion) you will
need to update $HOME/.casfwrc (create the file if it does not exist) with the following
line:

  export PATH=$PATH:/opt/Subversion/bin


Apache
------

If Apache is installed on this server you can connect it to Hudson by including
in Apache's configuration file (e.g. /opt/webhost/local/WHA-General-Inst/apache/conf/httpd.conf)
the line below and restart Apache (e.g. using /opt/webhost/dwheng/bin/restart_apache):

  Include $CASFW_HOME/etc/apache/proxy_ajp_casfw_hudson.conf

In addition, Apache can also be connected to Sonar by including the line below:

  Include $CASFW_HOME/etc/apache/proxy_ajp_casfw_sonar.conf

