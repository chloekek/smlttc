#!/usr/bin/env bash
set -efuo pipefail

PGHOST=127.0.0.1 PGPORT=5432 \
    PGUSER=sitrep_migrate PGPASSWORD=sitrep_migrate \
    PGDATABASE=sitrep psql --file=@INTEGRATION_TEST@/seed.sql

exec prove --recurse --verbose @INTEGRATION_TEST@/t
