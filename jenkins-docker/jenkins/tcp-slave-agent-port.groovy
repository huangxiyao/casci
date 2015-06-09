import jenkins.model.*;

Thread.start {
      sleep 10000
      println "Setting JNLP slave agent port"
      Jenkins.instance.setSlaveAgentPort(50000)
}
