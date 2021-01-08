#!/bin/bash

# Append a dot and a suffix to the name of some files and directories.
# Equivalent to 'mv xxx xxx.suffix'.

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "ERROR: Too few arguments." >&2
    exit 1
fi

suffix=${1}
shift 1

for f; do # bash 'for' iterate "$@" by default
    if ! [ -e "${f}" ]; then
        echo "WARNING: File '${f}' doesn't exist. Skipped." >&2
        continue
    fi
    if [ -e "${f}.${suffix}" ]; then
        echo "WARNING: File '${f}.${suffix}' exists. Skipped." >&2
        continue
    fi
    mv "${f}" "${f}.${suffix}"
done

