#!/bin/sh

set -e

#  jenkins-hpq
for image in 1-jenkins \
             2-jenkins-cd \
             3-jenkins-cas \
             4-jenkins-data-hpq
do
	echo "================================================================================"
	echo "Building image ${image}"
	pushd "${image}" > /dev/null
	./build-image.sh
	popd > /dev/null
done
