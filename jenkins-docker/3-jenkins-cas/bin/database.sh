#!/bin/sh

DATABASE="/opt/casfw/jenkins-cas/deploy.sqlite"

function createDatabase
{
    [[ -f "${DATABASE}" ]] || sqlite3 "${DATABASE}" << END_SQL
    create table deployment (
        buildIdentifier integer,
        displayName     text,
        time            integer,
        companyCode     text,
        environmentCode text,
        playbookVersion text,
        platformVersion text,
        userName        text,
        success         integer,

        primary key (buildIdentifier)
    );

    create table deploymentHost (
        companyCode             text,
        environmentCode         text,
        playbookVersion         text,
        hostName                text,
        success                 integer,
        successBuildIdentifier  integer,

        primary key (companyCode, environmentCode, playbookVersion, hostName)
    );

    create table company (
        code         text,
        displayOrder integer,

        primary key (code)
    );

    create table environment (
        code         text,
        displayOrder integer,

        primary key (code)
    );

    insert into company values ('hpe', 1);
    insert into company values ('hpi', 2);
    insert into company values ('hpq', 3);
    insert into environment values ('dev',  1);
    insert into environment values ('diet', 2);
    insert into environment values ('itg',  3);
    insert into environment values ('pro',  4);
    insert into environment values ('prom', 5);
END_SQL
}

createDatabase  # Always make sure we have a database

# ================================================================================
# Private
# ================================================================================

function quotedItemList
{
    echo "'$(sed "s/ /','/g" <<< $@)'"
}

function isHostInInventory
{
    local companyCode="$1"
    local environmentCode="$2"
    local playbookVersion="$3"
    local hostName="$4"

    local count=$(sqlite3 "${DATABASE}" << END_SQL
        select count(1)
          from deploymentHost
         where companyCode = '${companyCode}'
           and environmentCode = '${environmentCode}'
           and playbookVersion = '${playbookVersion}'
           and hostName = '${hostName}';
END_SQL
)
    (( count > 0 ))
}

# ================================================================================
# Public
# ================================================================================

function initializeInventory
{
    local buildIdentifier="$1"
    local companyCode="$2"
    local environmentCode="$3"
    local playbookVersion="$4"
    shift 4
    local inventoryHosts="$@"

    [[ -z "${inventoryHosts}" ]] && return

    {
        echo "begin transaction;"

        # delete hosts removed from inventory
        cat << END_SQL
            delete from deploymentHost
             where companyCode = '${companyCode}'
               and environmentCode = '${environmentCode}'
               and playbookVersion = '${playbookVersion}'
               and hostName not in ($(quotedItemList ${inventoryHosts}));
END_SQL

        # insert hosts from inventory
        for hostName in ${inventoryHosts}
        do
            if ! isHostInInventory "${companyCode}" "${environmentCode}" "${playbookVersion}" "${hostName}"
            then
                cat << END_SQL
                    insert into deploymentHost (companyCode, environmentCode, playbookVersion, hostName, success, successBuildIdentifier)
                    values ('${companyCode}', '${environmentCode}', '${playbookVersion}', '${hostName}', null, ${buildIdentifier});
END_SQL
            fi
        done

        echo "commit;"
    } | sqlite3 "${DATABASE}"
}

function deploymentFailed
{
    local buildIdentifier="$1"
    local displayName="$2"
    local companyCode="$3"
    local environmentCode="$4"
    local playbookVersion="$5"
    local platformVersion="$6"
    local userName="$7"
    shift 7
    local successfulHosts="$@"

	successfulHosts="$(quotedItemList ${successfulHosts})"
    local now=$(date '+%s')

    sqlite3 "${DATABASE}" << END_SQL
        begin transaction;

        insert into deployment (buildIdentifier, displayName, time, companyCode, environmentCode, playbookVersion, platformVersion, userName, success)
        values ('${buildIdentifier}', '${displayName}', '${now}', '${companyCode}', '${environmentCode}', '${playbookVersion}', '${platformVersion}', '${userName}', 0);

        update deploymentHost
           set success = 1,
               successBuildIdentifier = ${buildIdentifier}
         where companyCode = '${companyCode}'
           and environmentCode = '${environmentCode}'
           and playbookVersion = '${playbookVersion}'
           and (success = 0 or success is null)
           and hostName in (${successfulHosts});

        update deploymentHost
           set success = 0,
               successBuildIdentifier = ${buildIdentifier}
         where companyCode = '${companyCode}'
           and environmentCode = '${environmentCode}'
           and playbookVersion = '${playbookVersion}'
           and (success = 0 or success is null)
           and hostName not in (${successfulHosts});

        commit;
END_SQL
}

function deploymentSucceeded
{
    local buildIdentifier="$1"
    local displayName="$2"
    local companyCode="$3"
    local environmentCode="$4"
    local playbookVersion="$5"
    local platformVersion="$6"
    local userName="$7"

    local now=$(date '+%s')

    sqlite3 "${DATABASE}" << END_SQL
        begin transaction;

        insert into deployment (buildIdentifier, displayName, time, companyCode, environmentCode, playbookVersion, platformVersion, userName, success)
        values ('${buildIdentifier}', '${displayName}', '${now}', '${companyCode}', '${environmentCode}', '${playbookVersion}', '${platformVersion}', '${userName}', 1);

        delete from deploymentHost
         where companyCode = '${companyCode}'
           and environmentCode = '${environmentCode}'
           and playbookVersion = '${playbookVersion}';

        commit;
END_SQL
}

function deploymentInventory
{
    local companyCode="$1"
    local environmentCode="$2"
    local playbookVersion="$3"

    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
        select hostName
          from deploymentHost
         where companyCode = '${companyCode}'
           and environmentCode = '${environmentCode}'
           and playbookVersion = '${playbookVersion}'
           and success = 0
            or success is null;
END_SQL
}

function deploymentHistory
{
    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
        select buildIdentifier, displayName, time, companyCode, environmentCode, playbookVersion, platformVersion, userName, success
          from deployment order by time desc;
END_SQL
}

function previousPlatformAndPlaybookVersions
{
    local companyCode="$1"
    local environmentCode="$2"
    local referenceTime="$3"

    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
        select platformVersion, playbookVersion
          from deployment
          join (select companyCode as cc, environmentCode as ec, max(time) as previousTime
                from deployment
                where companyCode = '${companyCode}'
                  and environmentCode = '${environmentCode}'
                  and time < ${referenceTime}
               ) on deployment.time = previousTime;
END_SQL
}

function currentInstallations
{
    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
        select deployment.time, deployment.environmentCode, deployment.companyCode, deployment.playbookVersion, deployment.platformVersion, hostName, deploymentHost.success, hostDeployment.displayName
          from deployment
          join company on company.code = deployment.companyCode
          join environment on environment.code = deployment.environmentCode
          join (select companyCode as cc, environmentCode as ec, max(time) as latestTime
                from deployment
                group by companyCode, environmentCode
               ) on deployment.time = latestTime
          left outer join deploymentHost on
            deployment.companyCode = deploymentHost.companyCode
            and deployment.environmentCode = deploymentHost.environmentCode
            and deployment.playbookVersion = deploymentHost.playbookVersion
          left outer join deployment as hostDeployment on hostDeployment.buildIdentifier = deploymentHost.successBuildIdentifier
          order by environment.displayOrder, company.displayOrder, hostName;
END_SQL
}

function deployment
{
    local buildIdentifier="$1"

    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
        select buildIdentifier, displayName, time, companyCode, environmentCode, playbookVersion, platformVersion, userName, success
          from deployment
         where buildIdentifier = '${buildIdentifier}';
END_SQL
}

function deploymentSummary
{
    local buildIdentifier="$1"

    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
       select inventoryTotal, deploymentTotal, deploymentSuccess, deploymentFailure
       from (select count(1) as inventoryTotal
             from deploymentHost as h
             join deployment as d
                  on h.companyCode = d.companyCode
                 and h.environmentCode = d.environmentCode
                 and h.playbookVersion = d.playbookVersion
             where buildIdentifier = ${buildIdentifier}),
            (select count(1) as deploymentTotal
             from deploymentHost as h
             join deployment as d
                  on h.companyCode = d.companyCode
                 and h.environmentCode = d.environmentCode
                 and h.playbookVersion = d.playbookVersion
             where buildIdentifier = ${buildIdentifier}
               and successBuildIdentifier >= ${buildIdentifier}),
            (select count(1) as deploymentSuccess
               from deploymentHost
              where successBuildIdentifier = ${buildIdentifier}
                and success = 1),
            (select count(1) as deploymentFailure
             from deploymentHost as h
             join deployment as d
                  on h.companyCode = d.companyCode
                 and h.environmentCode = d.environmentCode
                 and h.playbookVersion = d.playbookVersion
             where buildIdentifier = ${buildIdentifier}
               and ((successBuildIdentifier = ${buildIdentifier} and h.success = 0)
                or  successBuildIdentifier > ${buildIdentifier}));
END_SQL
}

function deploymentHostsSuccess
{
    local companyCode="$1"
    local environmentCode="$2"
    local playbookVersion="$3"

    sqlite3 "${DATABASE}" << END_SQL
.mode tabs
    select hostName, success
      from deploymentHost
     where companyCode = '${companyCode}'
       and environmentCode = '${environmentCode}'
       and playbookVersion = '${playbookVersion}';
END_SQL
}

"$@"

