import jenkins.model.*;

def LOGGER = Logger.getLogger("PortSetter")

Thread.start {
      sleep 10000
      LOGGER.info("Setting JNLP slave agent port to 50000")
      Jenkins.instance.setSlaveAgentPort(50000)
}
