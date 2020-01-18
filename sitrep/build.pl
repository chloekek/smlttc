#!/usr/bin/env perl

use v5.12;
use autodie qw(:all);
use strict;

use File::Find qw(find);
use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Which qw(which);

################################################################################
# Constants

my %path = map { $_ => which($_) // die("which: $_") }
               qw(bash hivemind socat);

my @ldcFlags         = qw(-O3 -dip1000);
my @ldcUnittestFlags = qw(-main -unittest);

my @dLibrarySourceDirs  = qw(sitrep/sitrep);
my @dLibrarySourceFiles = qw(util/binary.d util/io.d util/os.d);
find(sub { push(@dLibrarySourceFiles, $File::Find::name) if /\.d$/ },
     @dLibrarySourceDirs);

my $buildDir = 'build/sitrep';

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

write_file("$buildDir/Procfile", <<EOF);
sitrep-receive: $path{socat} -d TCP-LISTEN:$port,fork,reuseaddr EXEC:$buildDir/sitrep-receive
EOF

write_file("$buildDir/hivemind", { perms => 0755 }, <<EOF);
#!$path{bash}
set -euo pipefail
exec $path{hivemind} --root \$PWD $buildDir/Procfile
EOF
