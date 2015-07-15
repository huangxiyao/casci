#!/bin/sh

# VAULT_PASSWORD_FILE must be set
# 'sshpass' will be used for credential handling if SSHPASS is set.

buildIdentifier="$1"
displayName="$2"
companyCode="$3"
environmentCode="$4"
playbookVersion="$5"
userName="$6"

inventoryFile="inventory/${companyCode}/${environmentCode}/hosts"
inventoryHosts=$(ansible all --inventory-file "${inventoryFile}" --list-hosts | tr '[[:upper:]]' '[[:lower:]]')

database.sh initializeInventory "${buildIdentifier}" "${companyCode}" "${environmentCode}" "${playbookVersion}" ${inventoryHosts}

deploymentHosts="$(database.sh deploymentInventory ${companyCode} ${environmentCode} ${playbookVersion})"

# parse the PLAY RECAP from the Ansible messages in the deployment log. hosts that are not unreachable or failed are successful.
function successfulHosts
{
    awk '
        /^PLAY RECAP/ {inPlayRecap = 1; next}
        !inPlayRecap {next}
        /to retry/ {getline; next}
        /^\s*$/ {inPlayRecap = 0; next}
        /unreachable=[^0]/ {next}
        /failed=[^0]/ {next}
        {print tolower($1)}
    ' ../builds/${buildIdentifier}/log | sort
}

FAILURE=1
SUCCESS=0

if [[ -n "${deploymentHosts}" ]]
then
    limitFile="deployment.hosts"
    echo "${deploymentHosts}" > "${limitFile}"
    ansibleOptions="-i ${inventoryFile} --limit @${limitFile} --vault-password-file=${VAULT_PASSWORD_FILE} --user ${userName}"

    status=${FAILURE}
    if [[ -n "${SSHPASS}" ]]
    then
        sshpass -e ansible-playbook ${ansibleOptions} --ask-pass site.yml && status=${SUCCESS}
    else
        ansible-playbook ${ansibleOptions} --private-key ~/.ssh/casfw-dev site.yml && status=${SUCCESS}
    fi

    # platform version from inventory
    platformVersion=$(grep "casfw_release_version" "inventory/${companyCode}/${environmentCode}/group_vars/all" | cut -d: -f2- | tr -d " '\"")

    if (( status == SUCCESS ))
    then
        database.sh deploymentSucceeded ${buildIdentifier} "${displayName}" ${companyCode} ${environmentCode} ${playbookVersion} ${platformVersion} ${userName}
    else
        database.sh deploymentFailed ${buildIdentifier} "${displayName}" ${companyCode} ${environmentCode} ${playbookVersion} ${platformVersion} ${userName} $(successfulHosts)
    fi
fi

exit ${status}

