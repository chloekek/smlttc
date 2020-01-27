#!/usr/bin/env perl

use v5.12;
use autodie qw(:all);
use strict;

use File::Copy qw(copy);
use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Which qw(which);

################################################################################
# Constants

my %path = map { $_ => which($_) // die("which: $_") }
               qw(bash hivemind initdb pg_isready postgres psql socat sqitch);

my @ldFlags          = split(/\s+/, qx{pkg-config --libs libpq libsodium});
my @ldcFlags         = (qw(-O3 -dip1000), map("-L$_", @ldFlags));
my @ldcUnittestFlags = qw(-main -unittest);

my @dLibrarySourceFiles = qw(
    sitrep/receive/authenticate/hardcoded.d
    sitrep/receive/authenticate/package.d
    sitrep/receive/protocol.d
    sitrep/receive/record/database.d
    sitrep/receive/record/debug_.d
    sitrep/receive/record/package.d
    sitrep/receive/serve.d
    util/binary.d
    util/io.d
    util/os.d
    util/pgdata.d
    util/pq.d
    util/sodium.d
);

my $buildDir = 'build/sitrep';
my $stateDir = 'state/sitrep';

my $port = 1080;

################################################################################
# Steps

make_path($buildDir);

system('docbook2html',
       '--stringparam', 'base.dir', "$buildDir/doc/",
       '--stringparam', 'chunker.output.encoding', 'UTF-8',
       '--stringparam', 'html.stylesheet', 'style.css',
       '--stringparam', 'use.id.as.filename', '1',
       '--xinclude',
       '--', 'sitrep/doc/index.xml');
copy('sitrep/doc/style.css', "$buildDir/doc/style.css")
    or die("copy: $!");

system('ldc2', @ldcFlags, @ldcUnittestFlags,
       @dLibrarySourceFiles,
       "-of=$buildDir/unittest");

system('ldc2', @ldcFlags,
       'sitrep/sitrep-receive.d', @dLibrarySourceFiles,
       "-of=$buildDir/sitrep-receive");

system('rsync', '--archive', '--delete',
       'sitrep/database/',
       "$buildDir/database/");

write_file("$buildDir/postgresql.conf", <<EOF);
# Paths to files used by the DBMS.
data_directory=$stateDir/postgresql-data
hba_file=$buildDir/postgresql.hba
ident_file=$buildDir/postgresql.ident

# Normalize settings for client connections.
DateStyle=ISO
IntervalStyle=sql_standard
TimeZone=UTC
client_encoding=UTF8
EOF

write_file("$buildDir/postgresql.hba", <<EOF);
#       database   user             auth-method
local   all        postgres         md5
local   sitrep     sitrep_migrate   md5
local   sitrep     sitrep_receive   md5
EOF

write_file("$buildDir/postgresql.ident", <<EOF);
EOF

write_file("$buildDir/postgresql.setup", { perms => 0755 }, <<EOF);
#!$path{bash}
# shellcheck disable=SC2030,SC2031
set -efuo pipefail

export PGHOST=\$PWD/$stateDir/postgresql-sockets

(
    export PGUSER=postgres
    export PGPASSWORD=\$PGUSER
    while ! $path{pg_isready}; do
        sleep 0.1
    done
)

(
    export PGUSER=postgres
    export PGPASSWORD=\$PGUSER
    mkdir --parents $stateDir/postgresql-tablespaces/sitrep_log_messages_in_need_of_extraction
    mkdir --parents $stateDir/postgresql-tablespaces/sitrep_log_messages_extracted_from
    $path{psql} --file=- <<SQL
CREATE ROLE sitrep_migrate LOGIN BYPASSRLS PASSWORD 'sitrep_migrate';
CREATE ROLE sitrep_receive LOGIN PASSWORD 'sitrep_receive';
CREATE DATABASE sitrep OWNER sitrep_migrate;
CREATE TABLESPACE sitrep_log_messages_in_need_of_extraction
    LOCATION '\$PWD/$stateDir/postgresql-tablespaces/sitrep_log_messages_in_need_of_extraction';
GRANT CREATE ON TABLESPACE sitrep_log_messages_in_need_of_extraction TO sitrep_migrate;
CREATE TABLESPACE sitrep_log_messages_extracted_from
    LOCATION '\$PWD/$stateDir/postgresql-tablespaces/sitrep_log_messages_extracted_from';
GRANT CREATE ON TABLESPACE sitrep_log_messages_extracted_from TO sitrep_migrate;
\\connect sitrep
DROP SCHEMA public;
SQL
)

(
    export PGUSER=sitrep_migrate
    export PGPASSWORD=\$PGUSER
    export PGDATABASE=sitrep
    cd $buildDir/database
    PATH=\$(dirname $path{psql}):\$PATH $path{sqitch} deploy
)
EOF
system('shellcheck', "$buildDir/postgresql.setup");

write_file("$buildDir/Procfile", <<EOF);
sitrep-receive: PGHOST=\$PWD/$stateDir/postgresql-sockets PGUSER=sitrep_receive PGPASSWORD=\$PGUSER PGDATABASE=sitrep $path{socat} -d TCP-LISTEN:$port,fork,reuseaddr EXEC:$buildDir/sitrep-receive
postgresql: $path{postgres} --config-file=$buildDir/postgresql.conf -k \$PWD/$stateDir/postgresql-sockets
postgresql-setup: $buildDir/postgresql.setup && sleep infinity
EOF

write_file("$buildDir/hivemind", { perms => 0755 }, <<EOF);
#!$path{bash}
set -efuo pipefail

if (( \$# != 0 )); then
    1>&2 echo "\$0: Too many arguments"
    exit 1
fi

if ! [[ -e $stateDir/postgresql-data ]]; then
    $path{initdb}                           \\
        --pgdata=$stateDir/postgresql-data  \\
        --username=postgres                 \\
        --pwfile=<(echo postgres)           \\
        --locale=en_US.UTF-8
    find $stateDir/postgresql-data -name '*.conf' -delete
fi

if ! [[ -e $stateDir/postgresql-sockets ]]; then
    mkdir $stateDir/postgresql-sockets
fi

exec $path{hivemind} --root "\$PWD" $buildDir/Procfile
EOF
system('shellcheck', "$buildDir/hivemind");
