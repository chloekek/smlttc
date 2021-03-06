use v5.12;
use lib '.';
use warnings;

my $suite = shift(@ARGV) // '';

if ($suite eq 'sitrep') {
    require sitrep::build;
    return %sitrep::build::artifacts;
}

die "Unknown suite: ‘$suite’";
