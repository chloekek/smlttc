#!/usr/bin/env bash
# shellcheck disable=SC2030,SC2031
set -efuo pipefail

stateDir=$PWD/state/sitrep/database

export PGHOST="$stateDir/sockets"

(
    export PGUSER=postgres
    export PGPASSWORD=$PGUSER
    while ! pg_isready; do
        sleep 0.1
    done
)

(
    export PGUSER=postgres
    export PGPASSWORD=$PGUSER
    mkdir --parents "$stateDir/tablespaces/sitrep_log_messages_in_need_of_extraction"
    mkdir --parents "$stateDir/tablespaces/sitrep_log_messages_extracted_from"
    psql --file=- <<SQL
        CREATE ROLE sitrep_migrate LOGIN BYPASSRLS PASSWORD 'sitrep_migrate';
        CREATE ROLE sitrep_receive LOGIN PASSWORD 'sitrep_receive';

        CREATE DATABASE sitrep OWNER sitrep_migrate;

        CREATE TABLESPACE sitrep_log_messages_in_need_of_extraction
            LOCATION '$stateDir/tablespaces/sitrep_log_messages_in_need_of_extraction';

        CREATE TABLESPACE sitrep_log_messages_extracted_from
            LOCATION '$stateDir/tablespaces/sitrep_log_messages_extracted_from';

        GRANT CREATE ON TABLESPACE sitrep_log_messages_in_need_of_extraction TO sitrep_migrate;
        GRANT CREATE ON TABLESPACE sitrep_log_messages_extracted_from TO sitrep_migrate;

        \\connect sitrep

        DROP SCHEMA public;
SQL
)

(
    export PGUSER=sitrep_migrate
    export PGPASSWORD=$PGUSER
    export PGDATABASE=sitrep
    cd @SCHEMA@
    sqitch deploy
)
