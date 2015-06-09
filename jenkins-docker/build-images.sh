#!/bin/sh

for image in jenkins jenkins-cd jenkins-hpq
do
	echo "================================================================================"
	echo "Building image ${image}"
	pushd "${image}" > /dev/null
	./build-image.sh
	popd > /dev/null
done
