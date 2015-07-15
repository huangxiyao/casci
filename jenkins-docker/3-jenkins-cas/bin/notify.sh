#!/bin/sh

# ================================================================================
# Flowdock
# ================================================================================

buildIdentifier="$1"

shopt -s xpg_echo
TAB=$(echo "\t")

IFS="${TAB}" read buildIdentifier displayName time companyCode environmentCode playbookVersion platformVersion userName success <<< "$(database.sh deployment "${buildIdentifier}")"

[[ "${environmentCode}" == "dev" ]] && exit 0

set -e
export https_proxy="http://web-proxy.corp.hp.com:8080"

#FLOW_TOKEN="8bfeae603105a9f5623b35267b9dd021"   # Jenkins → Flowdock test
FLOW_TOKEN="2009eae853bfabcd6f3dcaad2b3b4eda"   # Jenkins → Flowdock

upperCompany=$(echo "${companyCode}" | tr '[[:lower:]]' '[[:upper:]]')
upperEnvironment=$(echo "${environmentCode}" | tr '[[:lower:]]' '[[:upper:]]')

if (( success == 1 ))
then
	status="success"
	title="ran playbook ${playbookVersion} for ${upperCompany} ${upperEnvironment}"
	statusColor="green"
	externalUrl="${JENKINS_URL}userContent/deploy.html"
else
	status="partial"
	title="tried to run playbook ${playbookVersion} for ${upperCompany} ${upperEnvironment}"
	statusColor="orange"
	externalUrl="${BUILD_URL}console"
fi

curl --header "Content-Type: application/json" --silent --data @- "https://api.flowdock.com/messages" << END_JSON
{
	"flow_token": "${FLOW_TOKEN}",
	"event": "activity",
	"author": {
		"name": "Jenkins",
		"avatar": "http://jenkins-ci.org/sites/default/files/images/headshot.png"
	},
	"title": "${title}",
	"tags": ["deploy", "${status}"],
	"external_thread_id": "deploy:cas-platform:${playbookVersion}:${companyCode}:${environmentCode}",
	"thread": {
		"title": "Run playbook ${playbookVersion} for ${upperCompany} ${upperEnvironment}",
		"status": {
			"color": "${statusColor}",
			"value": "${status}"
		},
		"fields": [
			{
				"label": "playbook",
				"value": "${playbookVersion}"
			},
			{
				"label": "platform",
				"value": "${platformVersion}"
			}
		],
		"external_url": "${externalUrl}"
	}
}
END_JSON

