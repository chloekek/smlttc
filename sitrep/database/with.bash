#!/usr/bin/env bash
set -efuo pipefail

trap 'kill -TERM $(jobs -pr)' SIGINT SIGTERM EXIT

LOCALE_ARCHIVE=$(getLocaleArchive)
export LOCALE_ARCHIVE

stateDir=$PWD/state/sitrep/database

if ! [[ -e $stateDir/data ]]; then
    initdb                          \
        --pgdata="$stateDir/data"   \
        --username=postgres         \
        --pwfile=<(echo postgres)   \
        --locale=en_US.UTF-8
    find "$stateDir/data" -name '*.conf' -delete
fi

mkdir --parents "$stateDir/sockets"

postgres \
    --config-file=@POSTGRESQL_CONF@/postgresql.conf \
    -k "$stateDir/sockets" \
    &

export PGHOST=$stateDir/sockets
export PGPORT=5432

(
    export PGUSER=postgres
    export PGPASSWORD=$PGUSER
    while ! pg_isready; do
        sleep 0.1
    done
)

@SETUP_BASH@/setup.bash

# Do not use exec; that would inhibit the trap.
"$@"
