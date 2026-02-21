#!/bin/sh

usage() {
    echo "Usage: $(basename $0) version"
    echo
    echo version example: 7.10.7
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

wget -O /tmp/releaseinfo.json https://api.github.com/repos/PelicanPlatform/pelican/releases/tags/v$1
cat /tmp/releaseinfo.json | jq -r '.assets[] | select(.name | test(".rpm")) | .browser_download_url' | xargs wget
cat /tmp/releaseinfo.json | jq -r '.assets[] | select(.name | test(".deb")) | .browser_download_url' | xargs wget

populate () {
    arch=$1
    ext=$2
    dir=$3
    mkdir -p $dir
    cp -p *$arch.$ext $dir
}

populate x86_64 rpm x86_64_AlmaLinux8
ln -s x86_64_AlmaLinux8 x86_64_AlmaLinux9
ln -s x86_64_AlmaLinux8 x86_64_AlmaLinux10
ln -s x86_64_AlmaLinux8 x86_64_v2_AlmaLinux10
ln -s x86_64_AlmaLinux8 x86_64_AmazonLinux2023
ln -s x86_64_AlmaLinux8 x86_64_Fedora43
ln -s x86_64_AlmaLinux8 x86_64_openSUSE15
ln -s x86_64_AlmaLinux8 x86_64_openSUSE16
ln -s x86_64_AlmaLinux8 x86_64_SLES15SP5
populate amd64 deb x86_64_Debian11
ln -s x86_64_Debian11 x86_64_Debian12
ln -s x86_64_Debian11 x86_64_Debian13
ln -s x86_64_Debian11 x86_64_Ubuntu20
ln -s x86_64_Debian11 x86_64_Ubuntu22
ln -s x86_64_Debian11 x86_64_Ubuntu24
populate aarch64 rpm aarch64_AlmaLinux8
ln -s aarch64_AlmaLinux8 aarch64_AlmaLinux9
ln -s aarch64_AlmaLinux8 aarch64_AlmaLinux10
populate arm64 deb aarch64_Ubuntu24
populate ppc64le rpm ppc64le_AlmaLinux8
#populate ppc64el deb ppc64le_Ubuntu20

rm *.deb *.rpm *.1
