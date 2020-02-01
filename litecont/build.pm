package litecont::build;

use v5.12;
use strict;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

my @ldcFlags = qw(-O3 -dip1000 -unittest);

my @dSourceFiles = qw(
    litecont/main.d
    util/io.d
    util/os.d
    util/unittest_.d
);

our $litecont = Snowflake::Rule->new(
    name => 'litecont » litecont',
    dependencies => [],
    sources => {
        do { map { $_ => ['on_disk', $_] } @dSourceFiles },
        'snowflake-build' => bash_strict(<<BASH),
            mkdir snowflake-output
            ldc2 @ldcFlags @dSourceFiles -of=snowflake-output/litecont
BASH
    },
);

our %artifacts = (
    'litecont' => $litecont,
);

1;
