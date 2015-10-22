#!/bin/sh
if [ -x /opt/pb/bin/pbrun ]; then
    /opt/pb/bin/pbrun -n su "$@"
else
    sudo su "$@"
fi
