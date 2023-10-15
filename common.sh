#!/bin/bash

# Make sure we have an AFS tokens
if ! tokens | grep -q AFS; then
    echo No AFS token
    exit 1
fi

# Ensure things are group writable
umask 0002

suffix="-${area}"
if [ $area = 'public' ]; then
    suffix=""
fi

aversion=(${version//./ })
major_ver=${aversion[0]}
minor_ver=${aversion[1]}
patch_ver=${aversion[2]}

repo_version="${major_ver}.${minor_ver}"
if [ $major_ver -eq 9 ]; then
    if [ $minor_ver -ne 0 ]; then
        repo_version="${major_ver}.1"
    fi
fi
if [ $major_ver -ge 10 ]; then
    if [ $minor_ver -ne 0 ]; then
        repo_version="${major_ver}.x"
    fi
fi

# 9.0 LTS series
if [ $repo_version = '9.0' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 9.0 Daily Key
        key=8A314675
    else
        # HTCondor 9.0 Key
        key=748E8328
    fi
fi

# 9.x Feature series
if [ $repo_version = '9.1' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 9.1 Daily Key
        key=EC836AA7
    else
        # HTCondor 9.1 Key
        key=6D4CA7CD
    fi
fi

# 10.0 LTS series
if [ $repo_version = '10.0' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 10.0 Daily Key
        key=8CF6700A
    else
        # HTCondor 10.0 Key
        key=FEA0C7D0
    fi
fi

# 10.x Feature series
if [ $repo_version = '10.x' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 10.x Daily Key
        key=28D1E5B6
    else
        # HTCondor 10.x Key
        key=43CDEFE7
    fi
fi

# 23 versions
if [ $major_ver = '23' ]; then
    if [ $repo = 'daily' ]; then
        # OSG 23 auto signing key
        key=1760EDF64D4384D0
    else
        # OSG 23 developer signing key
        key=BDEEE24C92897C00
    fi
fi

repository="/p/condor/public/html/htcondor/repo${suffix}"

# Make sure we can sign something
echo $key > /tmp/$area$suffix-$repo_version
if ! gpg --detach-sign -u 0x$key --digest-algo=sha256 --yes --armor /tmp/$area$suffix-$repo_version; then
    echo Cannot sign
    rm /tmp/$area$suffix-$repo_version*
    exit 1
fi
rm /tmp/$area$suffix-$repo_version*

