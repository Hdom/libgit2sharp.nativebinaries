#!/bin/bash

# Remove generated config file (if this exists, it will contain a Windows configuration,
# and we don't want to pass that into the linux docker containers)
rm -f libssh2/src/libssh2_config.h

dos2unix build.libgit2.sh

for RID in "alpine-x64" "debian.9-x64" "fedora-x64" "linux-x64" "rhel-x64" "ubuntu.18.04-x64"; do
    docker build -t $RID -f Dockerfile.$RID .
    winpty docker run -it -e RID=$RID --name=$RID $RID
    docker cp $RID:/nativebinaries/nuget.package/runtimes nuget.package
    docker rm $RID
done
