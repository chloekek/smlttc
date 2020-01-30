#!/usr/bin/env bash
set -efuo pipefail

export LOCALE_ARCHIVE=@LOCALE_ARCHIVE@

if (( $# != 0 )); then
    1>&2 echo "$0: This command takes no arguments"
    exit 1
fi

if ! [[ -e state/sitrep/database/data ]]; then
    initdb                                  \
        --pgdata=state/sitrep/database/data \
        --username=postgres                 \
        --pwfile=<(echo postgres)           \
        --locale=en_US.UTF-8
    find state/sitrep/database/data -name '*.conf' -delete
fi

if ! [[ -e state/sitrep/database/sockets ]]; then
    mkdir state/sitrep/database/sockets
fi

exec hivemind --root "$PWD" @PROCFILE@/Procfile
