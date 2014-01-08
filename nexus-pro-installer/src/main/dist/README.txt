
CAS Nexus Environment
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




Nexus
-----

Nexus can be started/stopped using the following commands:

  prompt> $CASFW_HOME/bin/nexus.sh start
  prompt> $CASFW_HOME/bin/nexus.sh stop

After starting, Nexus will be available at http://{your host}:8081/nexus/.
The port can be changed by updating $CASFW_HOME/etc/casfw.properties and running
config.sh as explained above.






