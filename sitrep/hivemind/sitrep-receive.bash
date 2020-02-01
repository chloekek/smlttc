#!/usr/bin/env bash
set -efuo pipefail

export PGUSER=sitrep_receive
export PGPASSWORD=$PGUSER
export PGDATABASE=sitrep

exec socat -d TCP-LISTEN:1080,fork,reuseaddr EXEC:@SITREP_RECEIVE@/sitrep-receive
