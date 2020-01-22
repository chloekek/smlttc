#!/usr/bin/env perl

use v5.12;
use autodie qw(:all);
use strict;

use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Which qw(which);

################################################################################
# Constants

my %path = map { $_ => which($_) // die("which: $_") }
               qw(bash hivemind initdb postgres socat);

my @ldFlags          = split(/\s+/, qx{pkg-config --libs libsodium});
my @ldcFlags         = (qw(-O3 -dip1000), map("-L$_", @ldFlags));
my @ldcUnittestFlags = qw(-main -unittest);

my @dLibrarySourceFiles = qw(
    sitrep/receive/authenticate/hardcoded.d
    sitrep/receive/authenticate/package.d
    sitrep/receive/protocol.d
    sitrep/receive/record/debug_.d
    sitrep/receive/record/package.d
    sitrep/receive/serve.d
    util/binary.d
    util/io.d
    util/os.d
    util/sodium.d
);

my $buildDir = 'build/sitrep';
my $stateDir = 'state/sitrep';

my $port = 1080;

################################################################################
# Steps

make_path($buildDir);

system('ldc2', @ldcFlags, @ldcUnittestFlags,
       @dLibrarySourceFiles,
       "-of=$buildDir/unittest");

system('ldc2', @ldcFlags,
       'sitrep/sitrep-receive.d', @dLibrarySourceFiles,
       "-of=$buildDir/sitrep-receive");

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
#       database   user       auth-method
local   all        postgres   md5
EOF

write_file("$buildDir/postgresql.ident", <<EOF);
EOF

write_file("$buildDir/Procfile", <<EOF);
sitrep-receive: $path{socat} -d TCP-LISTEN:$port,fork,reuseaddr EXEC:$buildDir/sitrep-receive
postgresql: $path{postgres} --config-file=$buildDir/postgresql.conf -k \$PWD/$stateDir/postgresql-sockets
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
    find $stateDir/postgresql-data -name '*.conf' -execdir rm {} +
fi

if ! [[ -e $stateDir/postgresql-sockets ]]; then
    mkdir $stateDir/postgresql-sockets
fi

exec $path{hivemind} --root "\$PWD" $buildDir/Procfile
EOF
system('shellcheck', "$buildDir/hivemind");
