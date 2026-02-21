#!/bin/bash
# Usage: debian-exterals.sh new-dir externals-dir

usage() {
    echo "Usage: $(basename $0) new-directory externals-directory"
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

if [ ! -d $1 ]; then
    echo ERROR: no directory: $1
    usage
    exit 1
fi

if [ ! -d $2 ]; then
    echo ERROR: no directory: $2
    usage
    exit 1
fi

new_dir=$(realpath $1)
externals_dir=$2

echo Removing old version...
find $externals_dir -name \*pelican\*.deb -print -exec rm {} +

echo Copying new version...
(cd $externals_dir; for i in *_[DU]*; do cp -av $new_dir/$i/*pelican* $i; done)
