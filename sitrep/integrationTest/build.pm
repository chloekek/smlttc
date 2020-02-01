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

our $integrationTest_bash = Snowflake::Rule->new(
    name => 'sitrep » integrationTest » integrationTest.bash',
    dependencies => [$integrationTest],
    sources => {
        'integrationTest.bash' =>
            ['on_disk', 'sitrep/integrationTest/integrationTest.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            integrationTest=${1#../../../}
            sed --file=- --in-place integrationTest.bash <<SED
                s:@INTEGRATION_TEST@:$integrationTest:g
SED

            chmod +x integrationTest.bash
            shellcheck integrationTest.bash

            mkdir snowflake-output
            mv integrationTest.bash snowflake-output
BASH
    },
);

1;
