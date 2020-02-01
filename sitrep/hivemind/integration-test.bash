#!/usr/bin/env bash
set -efuo pipefail

if [[ ${INTEGRATIONTEST:-} != Y ]]; then
    exec sleep infinity
fi

export PGUSER=sitrep_migrate
export PGPASSWORD=$PGUSER
export PGDATABASE=sitrep

psql --file=@INTEGRATION_TEST@/seed.sql

exec prove --recurse --verbose @INTEGRATION_TEST@/t
