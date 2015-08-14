#!/bin/bash

set -e

tag="$1"

git clone https://github.com/ansible/ansible.git --recursive
cd ansible

if [[ ! -z "${tag// }" ]]; then
    git checkout $tag
fi

make rpm

echo
if [[ -z "${tag// }" ]]; then
    echo "Build of Ansible latest git version complete:"
else
    echo "Build of Ansible $tag complete:"
fi
cp rpm-build/*.rpm /out
ls -la /out/*.rpm
