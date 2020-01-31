package sitrep::integrationTest::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

our $integrationTest = Snowflake::Rule->new(
    name => 'sitrep » integrationTest » integrationTest',
    dependencies => [],
    sources => {
        'seed.sql' => ['on_disk', 'sitrep/integrationTest/seed.sql'],
        'receive' => ['on_disk', 'sitrep/receive/t'],
        'snowflake-build' => bash_strict(<<'BASH'),
            mkdir --parents snowflake-output/t
            mv seed.sql snowflake-output
            mv receive snowflake-output/t
BASH
    },
);

1;
