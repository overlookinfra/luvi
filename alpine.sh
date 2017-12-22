#!/bin/sh -e
#
# Expected layout:
#   src/luvi/...
#   build/luvi/alpine/...

pwd="$(cd $(dirname $0) && pwd)"
wsroot="$(cd $(dirname $0)/../.. && pwd)"

if ! [ "$wsroot/src/luvi" -ef "$pwd" ]; then
    echo "Directory layout MUST have $pwd be in $wsroot/src/luvi" 1>&2
fi
mkdir -p "$wsroot/build/luvi/alpine"

docker run --rm -it \
       -v "$pwd:/src" alpine "$@"
