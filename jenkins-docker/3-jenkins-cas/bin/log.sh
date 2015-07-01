#!/bin/sh

set -e

DATABASE="${JENKINS_VAR}/deploy.sqlite"
DEPLOY_HTML="${JENKINS_HOME}/userContent/deploy.html"
#FLOW_TOKEN="8bfeae603105a9f5623b35267b9dd021"   # Jenkins → Flowdock test
FLOW_TOKEN="2009eae853bfabcd6f3dcaad2b3b4eda"   # Jenkins → Flowdock
PLATFORM_GIT_URL="https://cgit-pro.houston.hp.com/gerrit/gitweb?p=cas-platform.git;a=commitdiff;h="
PLAYBOOK_GIT_URL="https://cgit-pro.houston.hp.com/gerrit/gitweb?p=casfw-infrastructure.git;a=commitdiff;h="
PLATFORM_GIT_REPOSITORY="cas-platform"
PLAYBOOK_GIT_REPOSITORY="."
export https_proxy="http://web-proxy.corp.hp.com:8080" # to send to Flowdock

shopt -s xpg_echo
TAB=$(echo "\t")

# ================================================================================
# Database
# ================================================================================

function sql
{
    {
        echo ".mode tabs"
        echo "$*;"
    } | sqlite3 "${DATABASE}"
}

# Create the DATABASE if it does not exist
#private
function createDatabase
{
    [[ -f "${DATABASE}" ]] || sqlite3 "${DATABASE}" <<EOF
    create table deployment (
        buildIdentifier TEXT,
        time INTEGER,
        companyCode TEXT,
        environmentCode TEXT,
        playbookVersion TEXT,
        platformVersion TEXT,
        userName TEXT,
        success INTEGER
    );
    create table company (
        code TEXT,
        displayOrder INTEGER
    );
    create table environment (
        code TEXT,
        displayOrder INTEGER
    );
    insert into company values ('hpe', 1);
    insert into company values ('hpi', 2);
    insert into environment values ('dev', 1);
    insert into environment values ('diet', 2);
    insert into environment values ('itg', 3);
    insert into environment values ('pro', 4);
EOF
}

createDatabase  # Always make sure we have a database

# ================================================================================
# Log
# ================================================================================

# Parse the platform version from the inventory
#private
function platformVersionFromInventory
{
    local company="$1"
    local environment="$2"

    grep "casfw_release_version" "inventory/${company}/${environment}/group_vars/all" | cut -d: -f2- | tr -d " '\""
}

# Log the deployment details
#private
function logDeployment
{
    local buildIdentifier="$1"
    local company="$2"
    local environment="$3"
    local playbookVersion="$4"
    local userName="$5"
    local status="$6"

    local success="0"
    [[ "${status}" == "success" ]] && success="1"

    local now=$(date '+%s')
    local platformVersion=$(platformVersionFromInventory "${company}" "${environment}")

    sql "insert into deployment (buildIdentifier, time, companyCode, environmentCode, playbookVersion, platformVersion, userName, success)" \
        " values ('${buildIdentifier}', '${now}', '${company}', '${environment}', '${playbookVersion}', '${platformVersion}', '${userName}', ${success})"
}

# ================================================================================
# Flowdock
# ================================================================================

#private
function sendNotification
{
    local company="$1"
    local environment="$2"
    local playbookVersion="$3"
    local status="$4"

    [[ "${environment}" == "dev" ]] && return

    local upperCompany=$(echo "${company}" | tr '[[:lower:]]' '[[:upper:]]')
    local upperEnvironment=$(echo "${environment}" | tr '[[:lower:]]' '[[:upper:]]')
    local platformVersion=$(sql \
              "select platformVersion" \
              "  from deployment" \
              "  join (" \
              "    select companyCode as cc, environmentCode as ec, max(time) as latestTime" \
              "      from deployment" \
              "     where companyCode='${company}' and environmentCode='${environment}'" \
              "  ) on deployment.time = latestTime")

    if [[ "${status}" == "success" ]]
    then
        local title="deployed platform ${platformVersion} to ${upperCompany} ${upperEnvironment}"
        local statusColor="green"
        local externalUrl="${JENKINS_URL}userContent/deploy.html"
    else
        local title="tried to deploy platform ${platformVersion} to ${upperCompany} ${upperEnvironment}"
        local statusColor="red"
        local externalUrl="${BUILD_URL}console"
    fi

    curl --header "Content-Type: application/json" --silent --data @- "https://api.flowdock.com/messages" <<EOF
    {
        "flow_token": "${FLOW_TOKEN}",
        "event": "activity",
        "author": {
            "name": "Jenkins",
            "avatar": "http://jenkins-ci.org/sites/default/files/images/headshot.png"
        },
        "title": "${title}",
        "tags": ["deploy", "${status}"],
        "external_thread_id": "deploy:cas-platform:${platformVersion}:${company}:${environment}",
        "thread": {
            "title": "Deploy platform to ${upperCompany} ${upperEnvironment}",
            "status": {
                "color": "${statusColor}",
                "value": "${status}"
            },
            "fields": [
                {
                    "label": "platform",
                    "value": "${platformVersion}"
                },
                {
                    "label": "playbook",
                    "value": "${playbookVersion}"
                }
            ],
            "external_url": "${externalUrl}"
        }
    }
EOF
}

# ================================================================================
# HTML
# ================================================================================

# Write the changes between versions begin..end to stdout. Fields are separated by tabs.
#private
function gitLog
{
    local begin="$1"
    local end="$2"

    [[ -z "${end}" ]] && end="HEAD"

    local format="%h${TAB}%an${TAB}%s"

    if [[ -n "${begin}" ]]
    then
        git log --pretty=format:"${format}" "${begin}..${end}" 2> /dev/null
    else
        git log --pretty=format:"${format}" "${end}" --max-count=20 2> /dev/null
    fi | awk '$2 != "Jenkins" {print}'
}

#private
function htmlEscape # (string)
{
    echo "$1" | sed -e "s/</\&lt;/g" \
                    -e "s/>/\&gt;/g" \
                    -e "s/\&/\&amp;/g"
}

# Create the HTML table of Git changes
#private
function gitLogTable
{
    local component="$1"
    local gitUrl="$2"
    local begin="$3"
    local end="$4"

    local changes=$(gitLog "${begin}" "${end}")
    [[ -z "${changes}" ]] && return

    local caption="Recent ${component} changes"
    [[ -n "${begin}" ]] && caption="${component} changes since ${begin}"

    echo "<table><caption>${caption}</caption>"
    echo "<thead><tr><th></th><th>Author</th><th>Subject</th></tr></thead><tbody>"
    echo "${changes}" | while IFS="${TAB}" read commit author subject
    do
        subject=$(htmlEscape "${subject}")
        echo "<tr><th><a href='${gitUrl}${commit}' target='_blank'>${commit}</a></th><td>${author}</td><td>${subject}</td></tr>"
    done
    echo "</tbody></table>"
}

# Create the HTML table of platform changes
#private
function platformGitLogTable # (begin end)
{
    pushd "${PLATFORM_GIT_REPOSITORY}" > /dev/null
    gitLogTable "Platform" "${PLATFORM_GIT_URL}" "$1" "$2"
    popd > /dev/null
}

# Create the HTML table of playbook changes
#private
function playbookGitLogTable # (begin end)
{
    pushd "${PLAYBOOK_GIT_REPOSITORY}" > /dev/null
    gitLogTable "Playbook" "${PLAYBOOK_GIT_URL}" "$1" "$2"
    popd > /dev/null
}

# Create the HTML history table
#private
function historyTable
{
    echo "<table id='history'><caption>Deployment History</caption><thead>"
    echo "<tr><th></th><th>Time</th><th>Company</th><th>Environment</th><th>Platform</th><th>Playbook</th><th>Status</th><th>User</th></tr></thead><tbody>"
    local buildIdentifier dateTime companyCode environmentCode platformVersion playbookVersion status userName

    sql "select buildIdentifier, time, datetime(time, 'unixepoch'), companyCode, environmentCode, playbookVersion, platformVersion, userName, success" \
        "  from deployment order by time desc" |
    while IFS="${TAB}" read buildIdentifier time dateTime companyCode environmentCode playbookVersion platformVersion userName success
    do
        local status="success"
        (( success == 0 )) && status="failure"

        local buildIdentifierData="<th>${buildIdentifier}</th>"
        local dateTimeData="<td>${dateTime}</td>"
        local companyCodeData="<td>${companyCode}</td>"
        local environmentCodeData="<td>${environmentCode}</td>"
        local platformVersionData="<td>${platformVersion}</td>"
        local playbookVersionData="<td>${playbookVersion}</td>"
        local statusData="<td>${status}</td>"
        local userNameData="<td>${userName}</td>"

        if (( success ))
        then
            IFS="${TAB}" read previousPlatformVersion previousPlaybookVersion <<< \
                "$(sql "select platformVersion, playbookVersion" \
                       "  from deployment" \
                       "  join (" \
                       "    select companyCode as cc, environmentCode as ec, max(time) as previousTime" \
                       "      from deployment" \
                       "     where companyCode = '${companyCode}' and environmentCode = '${environmentCode}' and success = 1 and time < ${time}" \
                       "  ) on deployment.time = previousTime")"

            local platformGitLogTable=$(platformGitLogTable "${previousPlatformVersion}" "${platformVersion}")
            [[ -n "${platformGitLogTable}" ]] && platformVersionData="<td class='master'>${platformVersion}${platformGitLogTable}</td>"

            local playbookGitLogTable=$(playbookGitLogTable "${previousPlaybookVersion}" "${playbookVersion}")
            [[ -n "${playbookGitLogTable}" ]] && playbookVersionData="<td class='master'>${playbookVersion}${playbookGitLogTable}</td>"
        fi
        echo "<tr class='${status}'>${buildIdentifierData}${dateTimeData}${companyCodeData}${environmentCodeData}${platformVersionData}${playbookVersionData}${statusData}${userNameData}</tr>"
    done
    echo "</tbody></table>"
}

# Create the HTML table showing the latest deployments to the various environments
#private
function installationTable
{
    sql "select date(time, 'unixepoch'), environmentCode, companyCode, platformVersion" \
        "  from deployment" \
        "    join company on company.code = companyCode" \
        "    join environment on environment.code = environmentCode" \
        "    join (" \
        "      select companyCode as cc, environmentCode as ec, max(time) as latestTime" \
        "        from deployment" \
        "       where success = 1" \
        "       group by companyCode, environmentCode" \
        "    ) on deployment.time=latestTime" \
        " order by environment.displayOrder, company.displayOrder" |
    awk -F"${TAB}" '
    BEGIN {
        print "<table id=\"installation\"><caption>Platform Installations</caption><thead>"
        companyCount = 0
        environmentCount = 0
    }
    {
        date = $1
        environment = $2
        company = $3
        platform = $4

        platforms[company,environment] = platform
        dates[company,environment] = date

        if (! (company in companies)) {
            companies[company] = company
            orderedCompanies[++companyCount] = company
        }
        if (! (environment in environments)) {
            environments[environment] = environment
            orderedEnvironments[++environmentCount] = environment
        }
    }
    END {
        printf "<tr><th></th>"
        for (c = 1; c <= companyCount; ++c) {
            printf "<th>%s</th>", toupper(orderedCompanies[c])
        }
        printf "</tr></thead><tbody>\n"

        for (e = 1; e <= environmentCount; ++e) {
            printf "<tr><th>%s</th>", toupper(orderedEnvironments[e])
            for (c = 1; c <= companyCount; ++c) {
                printf "<td>%s<time>%s</time></td>", platforms[orderedCompanies[c],orderedEnvironments[e]], dates[orderedCompanies[c],orderedEnvironments[e]]
            }
            printf "</tr>\n"
        }

        print "</tbody></table>"
    }'
}

# Generate the deployment history HTML report
#private
function generateHtml
{
    cat > "${DEPLOY_HTML}" <<EOF
<!DOCTYPE html>
<html lang=en><head><meta charset=utf-8 /><title>Deployment History</title>
<style>
body {
    font-family: helvetica, sans-serif;
}
#history {
    float: left;
}
#installation {
    float: left;
    margin-left: 2em;
}
table {
    font-size: smaller;
    border-spacing: 0 1px;
    border-collapse: collapse;
}
caption {
    font-size: larger;
    font-weight: bold;
    margin-bottom: 1em;
}
tbody > tr:nth-child(even) {
    background-color: #ebebeb;
}
th, td {
    text-align: left;
    padding: .5em 1em;
    border: 1px #e5e5e5 solid;
}
th, th a {
    color: white;
}
thead > tr > th {
    border-left: #46771d;
    border-right: #46771d;
    background-color: #46771d;
}
tbody > tr > th {
    background-color: #5f5f5f;
    border-left: #5f5f5f;
}
.master:after { content: ' 🔎'; }
.master table {
    display: none;
    font-size: smaller;
}
.master:hover table {
    display: block;
    padding: 6px;
    border: 1px solid #bbb;
    box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
    background-color: #fefefe;
    position: absolute;
    z-index: 100;
}
#installation td, #installation thead th {
    text-align: center;
}
td time {
    display: block;
    font-size: smaller;
    color: #888;
}
.failure td:nth-child(7) {
    color: red;
}
</style>
</head><body>
$(historyTable)
$(installationTable)
</body></html>
EOF
}

# ================================================================================
# Main
# ================================================================================

# Log the deployment details, generate reports, send email
#public
function deployed # (buildIdentifier, company, environment, playbookVersion, userName, status)
{
    local buildIdentifier="$1"
    local company="$2"
    local environment="$3"
    local playbookVersion="$4"
    local userName="$5"
    local status="$6"

    logDeployment "${buildIdentifier}" "${company}" "${environment}" "${playbookVersion}" "${userName}" "${status}"
    generateHtml
    sendNotification "${company}" "${environment}" "${playbookVersion}" "${status}"
}

"$@"

