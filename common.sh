#!/bin/bash

suffix="-${area}"
if [ $area = 'public' ]; then
    suffix=""
fi

aversion=(${version//./ })
major_ver=${aversion[0]}
minor_ver=${aversion[1]}
patch_ver=${aversion[2]}

# 8.8 and before
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

# Stable series
if [ $repo_version = '9.0' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 9.0 Daily Key
        key=8A314675
    else
        # HTCondor 9.0 Key
        key=748E8328
    fi
fi

# Feature series
if [ $repo_version = '9.1' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 9.1 Daily Key
        key=EC836AA7
    else
        # HTCondor 9.1 Key
        key=6D4CA7CD
    fi
fi

# LTS series
if [ $repo_version = '10.0' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 10.0 Daily Key
        key=8CF6700A
    else
        # HTCondor 10.0 Key
        key=FEA0C7D0
    fi
fi

# Feature series
if [ $repo_version = '10.x' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 10.x Daily Key
        key=28D1E5B6
    else
        # HTCondor 10.x Key
        key=43CDEFE7
    fi
fi

repository="/p/condor/public/html/htcondor/repo${suffix}"

if [ -z "${GPG_AGENT_INFO}" ]; then
    killall gpg-agent
    eval $(gpg-agent --daemon --enable-ssh-support --write-env-file "${HOME}/.gpg-agent-info" --no-use-standard-socket)
fi

