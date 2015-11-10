#!/bin/sh

if [ "${USER}" == 'casfw' ]
then
    shift
    sh "$@"
elif [ -x /opt/pb/bin/pbrun ]
then
    /opt/pb/bin/pbrun su "$@"
else
    sudo -n su "$@"
fi