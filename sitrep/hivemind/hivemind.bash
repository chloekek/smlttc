#!/usr/bin/env bash
set -efuo pipefail

LOCALE_ARCHIVE=$(getLocaleArchive)
export LOCALE_ARCHIVE

if (( $# != 0 )); then
    1>&2 echo "$0: This command takes no arguments"
    exit 1
fi

exec hivemind --root "$PWD" @PROCFILE@/Procfile
