#!/bin/bash

#report release repository disk usage
for d in $(find /casfw/var/data/nexus/sonatype-work/storage/releases -not -path "*/.*" -name "*.pom" | xargs -n1 dirname | sort | uniq); do du -m $d | tr '\n' '\t'; stat -c "%y" $d; done | sort -nr > /opt/casfw/nexus-usage-releases.txt

#report snapshot repository disk usage
for d in $(find /casfw/var/data/nexus/sonatype-work/storage/snapshots -not -path "*/.*" -name "*.pom" | xargs -n1 dirname | sort | uniq); do du -m $d | tr '\n' '\t'; stat -c "%y" $d; done | sort -nr > /opt/casfw/nexus-usage-snapshots.txt