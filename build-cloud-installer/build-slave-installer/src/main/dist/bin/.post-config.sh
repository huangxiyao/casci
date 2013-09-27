#!/bin/bash
CASFW_HOME="$(cd "$(dirname "$0")/.." && pwd -P)"

cygwin=false
if [[ "$(uname)" =~ "CYGWIN" ]]; then
    cygwin=true
fi

echo "Setting up Maven"
if ${cygwin}; then
    echo "Please update your $HOME/.m2/settings.xml"
    echo "file so it contains all the settings present in"
    echo "${CASFW_HOME}/etc/maven/settings.xml"
elif [[ ! -e $HOME/.m2/settings.xml && ! -L $HOME/.m2/settings.xml ]]; then
    if [[ ! -d $HOME/.m2 ]]; then
        mkdir $HOME/.m2
    fi
    
    echo "Copying ${CASFW_HOME}/etc/maven/settings.xml to $HOME/.m2"
    cp ${CASFW_HOME}/etc/maven/settings.xml $HOME/.m2/.
else
    echo "WARNING:"
    echo " replace existed $HOME/.m2/settings.xml with new settings.xml."
    mv "$HOME/.m2/settings.xml" "$HOME/.m2/settings.xml.$(date '+%Y%m%d_%H%M%S')"
    cp ${CASFW_HOME}/etc/maven/settings.xml $HOME/.m2/.
fi