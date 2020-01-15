#!/usr/bin/env perl

use v5.12;
use strict;

use File::Find qw(find);
use File::Path qw(make_path);

my @ldcFlags = qw(-O3 -dip1000);

my @dLibrarySourceFiles = qw(util/io.d util/os.d);
my @dLibrarySourceDirs  = qw(sitrep/sitrep);
find(sub { push(@dLibrarySourceFiles, $File::Find::name) if /\.d$/ },
     @dLibrarySourceDirs);

my $outDir = 'build/sitrep';

make_path($outDir);

system('ldc2', @ldcFlags, '-main', '-unittest',
       @dLibrarySourceFiles,
       "-of=$outDir/unittest");

system('ldc2', @ldcFlags,
       'sitrep/sitrep.d', @dLibrarySourceFiles,
       "-of=$outDir/sitrep");

system('ldc2', @ldcFlags,
       'sitrep/sitrepd.d', @dLibrarySourceFiles,
       "-of=$outDir/sitrepd");
