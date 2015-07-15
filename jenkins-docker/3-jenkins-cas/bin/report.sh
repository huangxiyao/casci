#!/bin/sh

set -e

DEPLOY_HTML="${JENKINS_HOME}/userContent/deploy.html"
PLATFORM_GIT_URL="https://cgit-pro.houston.hp.com/gerrit/gitweb?p=cas-platform.git;a=commitdiff;h="
PLAYBOOK_GIT_URL="https://cgit-pro.houston.hp.com/gerrit/gitweb?p=casfw-infrastructure.git;a=commitdiff;h="
PLATFORM_GIT_REPOSITORY="cas-platform"
PLAYBOOK_GIT_REPOSITORY="."

shopt -s xpg_echo
TAB=$(echo "\t")

# Write the changes between versions begin..end to stdout. Fields are separated by tabs.
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

function htmlEscape # (string)
{
    echo "$1" | sed -e "s/</\&lt;/g" \
                    -e "s/>/\&gt;/g" \
                    -e "s/\&/\&amp;/g"
}

# Create the HTML table of Git changes
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

    echo "<table class=\"detail\"><caption>${caption}</caption>"
    echo "<thead><tr><th></th><th>Author</th><th>Subject</th></tr></thead><tbody>"
    echo "${changes}" | while IFS="${TAB}" read commit author subject
    do
        subject=$(htmlEscape "${subject}")
        echo "<tr><th><a href='${gitUrl}${commit}' target='_blank'>${commit}</a></th><td>${author}</td><td>${subject}</td></tr>"
    done
    echo "</tbody></table>"
}

# Create the HTML table of platform changes shown as a popup in the history table Git cells
function platformGitLogTable # (begin end)
{
    pushd "${PLATFORM_GIT_REPOSITORY}" > /dev/null
    gitLogTable "Platform" "${PLATFORM_GIT_URL}" "$1" "$2"
    popd > /dev/null
}

# Create the HTML table of playbook changes shown as a popup in the history table Git cells
function playbookGitLogTable # (begin end)
{
    pushd "${PLAYBOOK_GIT_REPOSITORY}" > /dev/null
    gitLogTable "Playbook" "${PLAYBOOK_GIT_URL}" "$1" "$2"
    popd > /dev/null
}

# Create the HTML table of host totals shown as a popup in the history table 'partial' cells
function hostDeploymentTable
{
    local buildIdentifier="$1"

    local counts="$(database.sh deploymentSummary ${buildIdentifier})"
    [[ -z "${counts}" ]] && return
    IFS="${TAB}" read inventoryTotal deploymentTotal deploymentSuccess deploymentFailure <<< "${counts}"
    (( deploymentTotal == 0 )) && return

    local previousDeploymentSuccess=$(( inventoryTotal - deploymentTotal ))

    echo "<table class='deploymentSummary detail'><caption>Summary</caption><thead><tr><th></th><th>Count</th></tr></thead><tbody>"
    echo "<tr><th><a href='${BUILD_URL}console'>Failure</a></th><td>${deploymentFailure}</td></tr>"
    echo "<tr><th>Success</th><td>${deploymentSuccess}</td></tr>"
    (( previousDeploymentSuccess > 0 )) && echo "<tr><th>Previous</th><td>${previousDeploymentSuccess}</td></tr>"
    echo "<tr><th>Total</th><td>${inventoryTotal}</td></tr>"
    echo "</tbody></table>"
}

# Create the HTML history table
function historyTable
{
    echo "<table id='history'><caption>Deployment History</caption><thead>"
    echo "<tr><th></th><th>Time</th><th>Company</th><th>Environment</th><th>Platform</th><th>Playbook</th><th>Status</th><th>User</th></tr></thead><tbody>"
    local buildIdentifier dateTime companyCode environmentCode platformVersion playbookVersion status userName

    database.sh deploymentHistory |
    while IFS="${TAB}" read buildIdentifier displayName time companyCode environmentCode playbookVersion platformVersion userName success
    do
        local dateTime=$(date --date="@${time}" --utc '+%F %T')    # convert to human form
        local status="success"
        (( success == 0 )) && status="partial"

        local displayNameData="<th>${displayName}</th>"
        local dateTimeData="<td>${dateTime}</td>"
        local companyCodeData="<td>${companyCode}</td>"
        local environmentCodeData="<td>${environmentCode}</td>"
        local platformVersionData="<td>${platformVersion}</td>"
        local playbookVersionData="<td>${playbookVersion}</td>"
        local statusData="<td>${status}</td>"
        local userNameData="<td>${userName}</td>"

        IFS="${TAB}" read previousPlatformVersion previousPlaybookVersion <<< "$(database.sh previousPlatformAndPlaybookVersions ${companyCode} ${environmentCode} ${time})"

        if [[ ${platformVersion} != ${previousPlatformVersion} ]]
        then
            local platformGitLogTable=$(platformGitLogTable "${previousPlatformVersion}" "${platformVersion}")
            platformVersionData="<td class='git master'>${platformVersion}${platformGitLogTable}</td>"
        fi

        if [[ ${playbookVersion} != ${previousPlaybookVersion} ]]
        then
            local playbookGitLogTable=$(playbookGitLogTable "${previousPlaybookVersion}" "${playbookVersion}")
            playbookVersionData="<td class='git master'>${playbookVersion}${playbookGitLogTable}</td>"
        fi

        if (( ! success ))
        then
            local hostDeploymentTable=$(hostDeploymentTable "${buildIdentifier}")
            [[ -n "${hostDeploymentTable}" ]] && statusData="<td class='master'>${status}${hostDeploymentTable}</td>"
        fi

        echo "<tr class='${status}'>${displayNameData}${dateTimeData}${companyCodeData}${environmentCodeData}${platformVersionData}${playbookVersionData}${statusData}${userNameData}</tr>"
    done
    echo "</tbody></table>"
}

# Create the HTML table with the host inventory status shown as a popup in the installation table 'partial' cells
function inventoryStatus {
    local companyCode="$1"
    local environmentCode="$2"
    local playbookVersion="$3"

    local rows="$(database.sh deploymentHostsSuccess ${companyCode} ${environmentCode} ${playbookVersion})"
    [[ -z "${rows}" ]] && return

    echo "${rows}" | awk '
    FILENAME == "-" {
        success[$1] = $2
        next
    }
    /^#/ {next}
    /^\s*$/ {next}
    /^\[/ {
        gsub(/[\[\]]/, "")
        if (index($0, ":") > 0) {
            skipGroup = 1
        } else {
            skipGroup = 0
            groups[++groupCount] = $1
        }
        serverCount = 0
        next
    }
    skipGroup == 1 {next}
    {
        servers[groupCount, ++serverCount] = tolower($1)
        next
    }
    END {
        printf "<div class=\"detail\">"
        for (g = 1; g <= groupCount; ++g) {
            if ( (g, 1) in servers ) {  # skip empty groups
                printf "<details class=\"%s\"><summary>%s</summary>", groupSuccess(g), groups[g]
                printf "<ul>"
                for (s = 1; (g, s) in servers; ++s) {
                    server = servers[g, s]
                    printf "<li class=\"%s\">%s</li>", success[server] ? "success" : "failure", server
                }
                printf "</ul></details>"
            }
        }
        printf "</div>"
    }
    function groupSuccess(groupNumber) {
        zeroes = 0
        ones = 0
        for (s = 1; (groupNumber, s) in servers; ++s) {
            server = servers[groupNumber, s]
            success[server] == 0 ? ++zeroes : ++ones
        }
        return zeroes > 0 && ones > 0 ? "partial" : zeroes > 0 ? "failure" : "success"
    }' - inventory/${companyCode}/${environmentCode}/hosts
}

export -f inventoryStatus

# Create the HTML table showing the latest deployments to the various environments
function installationTable
{
    database.sh currentInstallations | awk -F"${TAB}" '
    BEGIN {
        print "<table id=\"installation\"><caption>Platform Installations</caption><thead>"
        companyCount = 0
        environmentCount = 0
        hostCount = 0
    }
    {
        date = $1
        environment = $2
        company = $3
        playbook = $4
        platform = $5
        host = $6
        hostSuccess = $7
        hostSuccessDeployment = $8

        playbooks[company,environment] = playbook
        platforms[company,environment] = platform
        dates[company,environment] = formatDate(date)

        if (! (company in companies)) {
            companies[company] = company
            orderedCompanies[++companyCount] = company
        }
        if (! (environment in environments)) {
            environments[environment] = environment
            orderedEnvironments[++environmentCount] = environment
        }

        if (company != previousCompany || environment != previousEnvironment) {
            hostCount = 0
        }

        if (host != "") {
            hosts[company,environment,++hostCount] = host
            hostSuccesses[company,environment,hostCount] = hostSuccess
            hostSuccessDeployments[company,environment,hostCount] = hostSuccessDeployment
        }

        previousCompany = company
        previousEnvironment = environment
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
                if ((orderedCompanies[c],orderedEnvironments[e],1) in hosts) {
                    printf "<td class=\"master\"><span class=\"partial\">%s</span><time>%s</time>", platforms[orderedCompanies[c],orderedEnvironments[e]], dates[orderedCompanies[c],orderedEnvironments[e]]
                    command = sprintf("inventoryStatus %s %s %s", orderedCompanies[c], orderedEnvironments[e], playbooks[orderedCompanies[c],orderedEnvironments[e]])
                    command | getline hostSuccess
                    printf hostSuccess
                    printf "</td>"
                } else {
                    printf "<td>%s<time>%s</time></td>", platforms[orderedCompanies[c],orderedEnvironments[e]], dates[orderedCompanies[c],orderedEnvironments[e]]
                }
            }
            printf "</tr>\n"
        }

        print "</tbody></table>"
    }
    function formatDate(epoch) {
        command=sprintf("date --date=@%d --utc \"+%%F\"", epoch)
        command | getline formattedDate
        return formattedDate
    }'
}

# ================================================================================
# Generate the deployment history HTML report
# ================================================================================

cat > "${DEPLOY_HTML}" << END_HTML
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
#history .master:after {
    margin-left: .4em;
    content: '🔎';
}
#history .git.master:after {
    margin-left: .4em;
    content: url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAAXNSR0IArs4c6QAAAm1JREFUeJx0k19IU3EUx62opyCiskCXW7bpFkFQ1EMgjVnbXJsrKvQhQoqiHjR7Czf/QBBRPmRIkZbQP+aSHhI2fLDRJomWFohFbQ9hZb1kem5td/e33dP5rXvrbunDB3739zvf7++cc8+vCBGLlmAVcZE4QZQsFaf9WE4s03yvzLyb7GVvRttofZSo0JytWMzAQpQqaycbj90EtxHBbkIpEu5QTEzKeZVqojUwKgbbs7OfT7Ox6APBvYMt2EoQHGaUnoW4yRElbtdiBpxDbCL2BDwWWezrCmTeTw+lrvsmwV1OJhbVhGdSXlgCb9hh9io2ALWWLLhMCE4DZr7O9NJ+g3DKOQ92A+3lmZi0BkY2MTIAXi6muj1mGew6TN26/FH+MXeSjT6PCrU7caFa96ecSLidNMeIYi6+wKbGuwUvifjNnko5xwEDJlvOfBIHgw/FRz3hzLfZS2Lf1SlwlKLg2IZsZNhP2hpuEJIioWGw6v6JVQP/uZn0YOC2ULdXlDPZBjY9eQ9cWxD2FaN4vytK2qYipSHtYrA3Afv1CO4KxUCPyY7GL+nQ4x6wrsWfZw8mheNVItg2YLKz+YOcTvH5sKg92Ey0iv2KCe+BqwzZ6xdD8tz3FqF+zzw46GbrRhKfj8tMuqFo8n6jjvDnMqH0oUaPUjT8MpOY7oa63b/AtglT15oSJPZRnGOxSVxDmAmf2N8Th2pezlYEbyWCbT2J6WZJaqVzPbFOHXutAX8wq/+WE7xDJoZcw1KdzXFkOXGZElupvJ3/JlGFB7alnwZiqbtX3lLafo14yddYCC+nnmgseIl5/AYAAP//AwBFeO0rSJnXLgAAAABJRU5ErkJggg==);
}
.detail {
    display: none;
    color: black;
}
.master:hover .detail {
    display: block;
    padding: 6px;
    border: 1px solid #bbb;
    box-shadow: 1px 1px 5px rgba(0, 0, 0, 0.3);
    background-color: #fefefe;
    position: absolute;
    z-index: 100;
}
#installation td,
#installation thead th {
    text-align: center;
}
td time {
    display: block;
    font-size: smaller;
    color: #888;
}
#history .partial td:nth-child(7),
#installation .partial {
    color: orange;
}
table.deploymentSummary td:nth-child(2) {
    text-align: right;
}
#installation td div {
    text-align: left;
}
details summary,
details li {
    color: black;
}
details.success summary::-webkit-details-marker {
    color: green;
}
details.partial summary::-webkit-details-marker {
    color: orange;
}
details.failure summary::-webkit-details-marker {
    color: red;
}
details ul {
    list-style-type: none;
    padding-left: 1em;
    margin: .25em 0;
}
li.success:before {
    content: "✓";
    margin-right: .25em;
    color: green;
}
li.failure:before {
    content: "✗";
    margin-right: .25em;
    color: red;
}
</style>
</head><body>
$(historyTable)
$(installationTable)
</body></html>
END_HTML

