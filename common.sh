#!/bin/bash

suffix="-${area}"
if [ $area = 'public' ]; then
    suffix=""
fi

aversion=(${version//./ })
major_ver=${aversion[0]}
minor_ver=${aversion[1]}
patch_ver=${aversion[2]}

repo_version="${major_ver}.1"
if [ $minor_ver = '0' ]; then
    repo_version="${major_ver}.0"
fi

# Old key, issued 2013, 2048 bits
key=670079F6

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

# Feature serires
if [ $repo_version = '9.1' ]; then
    if [ $repo = 'daily' ]; then
        # HTCondor 9.1 Daily Key
        key=EC836AA7
    else
        # HTCondor 9.1 Key
        key=6D4CA7CD
    fi
fi

repository="/p/condor/public/html/htcondor/repo${suffix}"

if [ -z "${GPG_AGENT_INFO}" ]; then
    killall gpg-agent
    eval $(gpg-agent --daemon --enable-ssh-support --write-env-file "${HOME}/.gpg-agent-info" --no-use-standard-socket)
fi

