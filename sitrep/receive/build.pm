package sitrep::receive::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

my @ldFlags  = split(/\s+/, qx{pkg-config --libs libpq libsodium});
my @ldcFlags = (qw(-O3 -dip1000 -unittest), do { map { "-L$_" } @ldFlags });

my @dSourceFiles = qw(
    sitrep/receive/authenticate/hardcoded.d
    sitrep/receive/authenticate/package.d
    sitrep/receive/main.d
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
    util/unittest_.d
);

our $sitrep_receive = Snowflake::Rule->new(
    name => 'sitrep » receive » sitrep-receive',
    dependencies => [],
    sources => {
        do { map { $_ => ['on_disk', $_] } @dSourceFiles },
        'snowflake-build' => bash_strict(<<BASH),
            mkdir snowflake-output
            ldc2 @ldcFlags @dSourceFiles -of=snowflake-output/sitrep-receive
BASH
    },
);

1;
