Ansible RPM Build
=================

This Docker image can be used build Ansible RPMs in case you need a version which
is not available anymore in the official repositories.

To build this image:

    docker build -t ansible-rpm-build .

To build Ansible 1.8.2 RPMs and copy them to your local directory:

    docker run -v $(pwd):/out --rm ansible-rpm-build v1.8.2

`$(pwd)` can be replaced with any location on the host. `v1.8.2` can be any Ansible
git tag or commit hash.
