#!/bin/sh

function error # (message...)
{
    local message
    for message
    do
        echo "$message"
    done >&2
    exit 1
}

function usage # (message...)
{
    error "$@" \
          "Usage: $0 OPTIONS [pom...]" \
          "OPTIONS"                    \
          "  -v version"               \
          "     Set the version of the POM hierarchy" \
          "  -p name=value"            \
          "     Set the value of a property. -p can be specified more than once." \
          "  -s"                       \
          "     Fail if there are SNAPSHOT dependencies"
}

# find all <module>s in a POM
function modules # (pom)
{
    local pom="$1"
    xmllint --stream --noblanks --debug --nonet "${pom}" | awk '
    /^[[:digit:]]+ [[:digit:]]+/ {
        startElement = ""; endElement = ""; textNode = 0
        if ($2 == 1) startElement = $3
        if ($2 == 15) endElement = $3
        if ($2 == 3) textNode = 1
    }
    startElement == "module" {inModule = 1; text = ""; next}
    inModule && textNode {text = text $0; next}
    endElement == "module" {
        count = split(text, words)
        print words[count]
        inModule = 0
    }'
}

# recursively find all POMs in a multi-module hierarchy
function modulePoms # (pom)
{
    local pom="$1"
    local modules="$(modules "${pom}")"
    local module
    for module in ${modules}
    do
        local modulePom="${pom%%/pom.xml}/${module}/pom.xml"
        echo "${modulePom}"
        modulePoms "${modulePom}"
    done
}

# find all POMs in a hierarchy
function poms # (pom...)
{
    local pom
    for pom
    do
        [[ -f "${pom}" ]] || error "${pom} cannot be read"
        echo "${pom}"
        modulePoms "${pom}"
    done
}

function setPomVersion # (version pom...)
{
    local version="$1"; shift
    local pom
    for pom
    do
        echo "Updating version of ${pom} hierarchy to ${version}."
        mvn -B -f "${pom}" versions:set -DnewVersion="${version}" > /dev/null
    done
}

declare -a propertyNames
declare -a propertyValues

function addProperty # (name=value)
{
    local property="$1"
    propertyNames+=("${property%%=*}")
    propertyValues+=("${property#*=}")
}

function setProperties # (pom...)
{
    local pom
    local index
    for pom
    do
        for index in ${!propertyNames[@]}
        do
            local name="${propertyNames[$index]}"
            local value="${propertyValues[$index]}"
            if grep -q "<${name}>.*</${name}>" "${pom}"
            then
                echo "Updating '${name}' in ${pom} to '${value}'"
                sed -Ei -e "s|<${name}>.*</${name}>|<${name}>${value}</${name}>|" "${pom}"
            fi
        done
    done
}

function verifyNoSnapshots # (pom...)
{
    local pomsWithSnapshots="$(poms "$@" | xargs grep -l SNAPSHOT)"
    [[ -z "${pomsWithSnapshots}" ]] || error "The following POMS have SNAPSHOT dependencies:" "${pomsWithSnapshots}"
}

while getopts ":v:p:s" option
do
    case "${option}" in
        v) _setPomVersion=1; version="${OPTARG}" ;;
        p) _setProperties=1; addProperty "${OPTARG}" ;;
        s) _verifyNoSnapshots=1 ;;
        :) usage "option requires an argument -- ${OPTARG}" ;;
       \?) usage "illegal option -- ${OPTARG}" ;;
    esac
done
shift $(( OPTIND - 1 ))
(( $# == 0 )) && set -- ./pom.xml	# default to ./pom.xml if no POMs specified on command line

[[ -z "${_setPomVersion}${_verifyNoSnapshots}${_setProperties}" ]] && usage
[[ -n "${_setPomVersion}" ]] && setPomVersion "${version}" "$@"
[[ -n "${_setProperties}" ]] && setProperties "$@"
[[ -n "${_verifyNoSnapshots}" ]] && verifyNoSnapshots "$@"

exit 0

