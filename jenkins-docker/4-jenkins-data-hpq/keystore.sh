#!/bin/sh

KEYSTORE=${HOME}/.pki/keystore.jks
KEYSTORE_PASSWORD=changeit

function certificate
{
	local aliasName=$1
	keytool -exportcert -alias ${aliasName} -keystore ${KEYSTORE} -storepass ${KEYSTORE_PASSWORD} | keytool -printcert
}

function hostAlias
{
	keytool -list -keystore ${KEYSTORE} -storepass ${KEYSTORE_PASSWORD} | awk -F', ' '/PrivateKeyEntry/ {print $1; exit}'
}

function issuer
{
	local aliasName=$1
	certificate ${aliasName} | awk -F': ' '/^Issuer/ {print $2; exit}'
}

function aliasNames
{
	keytool -list -keystore ${KEYSTORE} -storepass ${KEYSTORE_PASSWORD} | awk -F', *' '$4 ~ /Entry$/ {print $1; exit}'
}

function aliasOfOwner
{
	local owner="$1"
	for aliasName in $(aliasNames)
	do
		certificateOwner="$(certificate ${aliasName} | awk -F': ' '/^Owner/ {print $2; exit}')"
		[[ ${owner} == ${certificateOwner} ]] && echo ${aliasName} && break
	done
}

# ================================================================================
# Public
# ================================================================================

function hostName
{
	certificate $(hostAlias)  | awk -F': |, |=' '/^Owner/ {print $3; exit}'
}

function authorityCertificate
{
	local hostAlias=$(hostAlias)
	local issuer="$(issuer ${hostAlias})"
	local issuerAlias=$(aliasOfOwner "${issuer}")
	keytool -exportcert -rfc -alias ${issuerAlias} -keystore ${KEYSTORE} -storepass ${KEYSTORE_PASSWORD}
}

$@
