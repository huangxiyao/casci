import jenkins.model.*
import java.util.logging.*

def LOGGER = Logger.getLogger("PluginInstaller")

def pluginsFile = new File(System.getenv()["JENKINS_PLUGINS"])

if (! pluginsFile.exists()) {
    return
}

def pluginManager = Jenkins.instance.pluginManager
def updateCenter = Jenkins.instance.updateCenter

// wait for the update center to become available by polling for a plugin
while (! updateCenter.getPlugin("ant")) {
	LOGGER.info("Waiting for Update Center to become available for plugin installation")
	sleep 2000
}

def installationJobs = []

pluginsFile.eachLine { shortName ->
	if (shortName == null || shortName ==~ /\s*#.*/ || shortName ==~ /\s*/) {
		return
	}

	def plugin = pluginManager.getPlugin(shortName)
	if (plugin == null) {
		plugin = updateCenter.getPlugin(shortName)
		if (plugin == null) {
			LOGGER.severe("Plugin ${shortName} not found in Update Center")
		} else {
			installationJobs.add(plugin.deploy())
		}
	}
}

# delete the plugins file so that installation doesn't happen on subsequent starts
pluginsFile.delete()

while (installationJobs.any { !it.done }) {
	sleep 2000
}

if (updateCenter.restartRequiredForCompletion) {
	LOGGER.info("Scheduling Jenkins restart to complete plugin installation")
	Jenkins.instance.safeRestart()
} else {
    LOGGER.info("Plugin installation complete")
}
