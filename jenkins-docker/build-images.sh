#!/bin/sh

set -e

#  jenkins-hpq
for image in jenkins jenkins-cd
do
	echo "================================================================================"
	echo "Building image ${image}"
	pushd "${image}" > /dev/null
	./build-image.sh
	popd > /dev/null
done
