#!/bin/sh

set -e

NEXUS_URL="http://repo1.corp.hp.com/nexus"
NEXUS_RELEASE_URL="${NEXUS_URL}/content/repositories/releases"
NEXUS_CAS_URL="${NEXUS_RELEASE_URL}/com/hp/it/118361"
PLATFORM_JOB_URL="${JENKINS_URL}/job/Platform%201%20Compile%20☆"
PLAYBOOK_JOB_URL="${JENKINS_URL}/job/Platform%203%20Playbook%20☆"
LDAP_URL="ldap://ldap.hp.com"

# Invoke curl with a standard set of parameters
#private
function web # (curlOptions) -> curl output
{
    curl --fail --location --silent --insecure "$@"
}

# Write the user's Unix account name to stdout, e.g. convert "quintin.may@hp.com" to "qam"
#public
function unixUserName # (userId)
{
    local userId="$1"
    local unixUserName=$(ldapsearch -x -H "${LDAP_URL}" -b "ou=People,o=hp.com" -s sub "uid=${userId}" | awk '/hpUnixUserName:/ {print $2}')
    echo "${unixUserName}"
}

# Write the archived artifact URLs of the platformBuildUrl to stdout
#private
function artifactUrls # (platformBuildUrl) -> [pomUrl cdiUrl]...
{
    local platformBuildUrl="$1"
    local artifactsJson=$(web "${platformBuildUrl}api/json?tree=artifacts%5brelativePath%5d&pretty=true")

    echo "${artifactsJson}" | tr -d '":' | awk -v "platformBuildUrl=${platformBuildUrl}" '
        $1 == "relativePath" {
            count = split($2, parts, "/")
            component = parts[1]
            components[component] = component
            if (parts[count] == "pom.xml") {
                poms[component] = $2
            } else {
                cdis[component] = $2
            }
        }
        END {
            for (component in components) {
                printf("%sartifact/%s %sartifact/%s\n", platformBuildUrl, poms[component], platformBuildUrl, cdis[component])
            }
        }
    '
}

# Write the text content of the tag in xml to stdout. Can't use XPath text() with security enabled in Jenkins.
#private
function xmlText # (xml, tag) -> text
{
    local xml="$1"
    local tag="$2"

    echo "${xml}" | xmllint --stream --noblanks --debug --nonet - | awk --posix -v tag="${tag}" '
    /^[[:digit:]]+ [[:digit:]]+/ {
        startElement = ""; endElement = ""; textNode = 0
        if ($2 == 1) startElement = $3
        if ($2 == 15) endElement = $3
        if ($2 == 3) textNode = 1
    }
    startElement == tag {inTag = 1; text = ""; next}
    inTag && textNode {
        sub(/([^[:space:]]+[[:space:]]+){5}/, "")
        text = text $0; next}
    endElement == tag {
        print text
        inTag = 0
    }'
}

# Write the version number produced by the buildUrl to stdout
#private
function version # (buildUrl) -> versionNumber
{
    local buildUrl="$1"
    local buildVersion=$(web "${buildUrl}api/xml?xpath=//displayName")
    buildVersion=$(xmlText "${buildVersion}" "displayName")
    echo "${buildVersion}"
}

# Write the platform buildUrl for the platformVersion to stdout
#private
function buildUrl # (platformVersion)
{
    local platformVersion="$1"
    local buildUrls=$(web "${PLATFORM_JOB_URL}/api/json?pretty=true&tree=builds%5burl%5d" | tr -d '"' | awk '$1 == "url" {print $3}')
    local buildUrl

    for buildUrl in ${buildUrls}
    do
        if [[ "$(version ${buildUrl})" == "${platformVersion}" ]]
        then
            echo "${buildUrl}"
            break
        fi
    done
}

# Write the Nexus CDI URLs for the specified platform version & artifact names (in order) to stdout
#private
function nexusInstallerUrls # (version, artifactName...)
{
    local version="$1"; shift 1

    for artifactName
    do
        echo "${NEXUS_CAS_URL}/${artifactName}/${version}/${artifactName}-${version}.cdi"
    done
}

# Write the platform version derived from the Nexus URL to stdout
#private
function versionFromNexusUrl # (cdiUrl)
{
    local cdiUrl="$1"
    if [[ "${cdiUrl}" =~ "/redirect" ]]
    then
        local version="${cdiUrl##*v=}"
        version="${version%%&*}"
        echo "${version}"
    else
        local version="${cdiUrl%.*}"
        version="${version##*-}"
        echo "${version}"
    fi
}

# Write the Jenkins CDI URLs for the specified platformVersion & artifact names (in order) to stdout
#private
function jenkinsInstallerUrls # (platformVersion, artifactName...)
{
    local platformVersion="$1"; shift 1
    local buildUrl=$(buildUrl "${platformVersion}")
    local cdiUrls=$(artifactUrls "${buildUrl}" | while read pomUrl cdiUrl
                                                 do
                                                     echo "${cdiUrl}"
                                                 done)
    # output in requested order
    for artifactName
    do
        for cdiUrl in ${cdiUrls}
        do
            if [[ "${cdiUrl}" =~ "/${artifactName}/" ]]
            then
                echo "${cdiUrl}"
                break
            fi
        done
    done
}

# Copy the Jenkins platform artifacts to the current job's workspace
#public
function copyPlatformArtifacts # (platformVersion)
{
    local platformVersion="$1"
    local platformBuildUrl=$(buildUrl "${platformVersion}")

    artifactUrls "${platformBuildUrl}" | while read pomUrl cdiUrl
    do
        local cdiName="${cdiUrl##*/}"
        echo "Copying ${cdiName} from ${platformBuildUrl}"
        web --remote-name-all "${cdiUrl}"
    done
}

# Copy the Jenkins platform artifacts referenced by the company/environment to Nexus if they are not already there
#public
function archiveToNexus # (company, environment)
{
    local company="$1"
    local environment="$2"
    local nexusUrls=$(grep -rh "${NEXUS_URL}" "inventory/${company}/${environment}/group_vars" | cut -d: -f2- | tr -d " '\"" | sort -u)
    local nexusUrl

    for nexusUrl in $nexusUrls
    do
        if ! web --head --max-time 5 "${nexusUrl}" > /dev/null
        then
            local platformVersion=$(versionFromNexusUrl "${nexusUrl}")
            local platformBuildUrl=$(buildUrl "${platformVersion}")

            if [[ -z "${platformBuildUrl}" ]]
            then
                echo "Artifacts for platform ${platformVersion} are not in Jenkins or Nexus."
                return 1
            fi

            artifactUrls "${platformBuildUrl}" | while read pomUrl cdiUrl
            do
                local cdiName="${cdiUrl##*/}"
                local installerName="${cdiName%-*}"
                local nexusQueryUrl=$(nexusInstallerUrls "${platformVersion}" "${installerName}")

                                # download to _archiveToNexus/deploy, but invoke Maven from _archiveToNexus so that we run 'mvn deploy' from
                                # a directory with no POM. Otherwise we have to have the parent POM available.
                echo "Deploying ${cdiName} to Nexus."
                rm -rf _archiveToNexus; mkdir -p _archiveToNexus/deploy; cd _archiveToNexus
                cd deploy; web --remote-name-all "${pomUrl}" "${cdiUrl}"; cd ..
                mvn -B deploy:deploy-file -DrepositoryId=release -DupdateReleaseInfo=true -Durl="${NEXUS_RELEASE_URL}" -DpomFile="deploy/pom.xml" -Dfile="deploy/${cdiName}"
                cd ..; rm -rf _archiveToNexus
            done
        fi
    done
}

# Write the version number of the last stable build for the specified job to stdout
#private
function lastStableVersion # (jobUrl)
{
    # TODO may want to use promoted version
    local jobUrl="$1"
    local stableUrl=$(web "${jobUrl}/api/xml?xpath=//lastStableBuild/url")
    stableUrl=$(xmlText "${stableUrl}" "url")
    local stableVersion=$(web "${stableUrl}api/xml?xpath=//displayName")
    stableVersion=$(xmlText "${stableVersion}" "displayName")
    echo "${stableVersion}"
}

# Write the version number of the last stable platform build to stdout
#public
function lastStablePlatformVersion # ()
{
    lastStableVersion "${PLATFORM_JOB_URL}"
}

# Write the version number of the last stable playbook build to stdout
#public
function lastStablePlaybookVersion # ()
{
    lastStableVersion "${PLAYBOOK_JOB_URL}"
}

# quote sed special characters
#private
function sedQuote # (string)
{
    echo "$*" | sed -e 's/[\&]/\\&/g'
}

# Update the specified inventory files to deploy the specified platformVersion
#public
function editInventory # (platformVersion, inventoryFile...)
{
    local platformVersion="$1"; shift
    local inventoryFiles="$@"
    local jobControllerInstallerUrl
    local batchInstallerUrl

    read jobControllerInstallerUrl batchInstallerUrl <<< $(jenkinsInstallerUrls "${platformVersion}" "job-controller-installer" "batch-installer")

    platformVersion=$(sedQuote "${platformVersion}")
    jobControllerInstallerUrl=$(sedQuote "${jobControllerInstallerUrl}")
    batchInstallerUrl=$(sedQuote "${batchInstallerUrl}")
    sed -ri -e "s|(^\s*casfw_release_version\s*:).*|\1 '${platformVersion}'|" \
            -e "s|(^\s*casfw_job_controller_installer_url\s*:).*|\1 '${jobControllerInstallerUrl}'|" \
            -e "s|(^\s*casfw_batch_installer_url\s*:).*|\1 '${batchInstallerUrl}'|" \
            ${inventoryFiles}
}

"$@"

