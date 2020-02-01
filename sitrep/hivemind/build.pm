package sitrep::hivemind::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

use sitrep::database::build;
use sitrep::integrationTest::build;
use sitrep::receive::build;

our $integration_test_bash = Snowflake::Rule->new(
    name => 'sitrep » hivemind » integration_test.bash',
    dependencies => [
        $sitrep::integrationTest::build::integrationTest,
    ],
    sources => {
        'integration-test.bash' =>
            ['on_disk', 'sitrep/hivemind/integration-test.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            integration_test=${1#../../../}
            sed --file=- --in-place integration-test.bash <<SED
                s:@INTEGRATION_TEST@:$integration_test:g
SED

            chmod +x integration-test.bash
            shellcheck integration-test.bash

            mkdir snowflake-output
            mv integration-test.bash snowflake-output
BASH
    },
);

our $sitrep_receive_bash = Snowflake::Rule->new(
    name => 'sitrep » hivemind » sitrep-receive.bash',
    dependencies => [
        $sitrep::receive::build::sitrep_receive,
    ],
    sources => {
        'sitrep-receive.bash' =>
            ['on_disk', 'sitrep/hivemind/sitrep-receive.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            sitrep_receive=${1#../../../}
            sed --file=- --in-place sitrep-receive.bash <<SED
                s:@SITREP_RECEIVE@:$sitrep_receive:g
SED

            chmod +x sitrep-receive.bash
            shellcheck sitrep-receive.bash

            mkdir snowflake-output
            mv sitrep-receive.bash snowflake-output
BASH
    },
);

our $procfile = Snowflake::Rule->new(
    name => 'sitrep » hivemind » Procfile',
    dependencies => [
        $integration_test_bash,
        $sitrep_receive_bash,
    ],
    sources => {
        'Procfile' => ['on_disk', 'sitrep/hivemind/Procfile'],
        'snowflake-build' => bash_strict(<<'BASH'),
            integration_test_bash=${1#../../../}
            sitrep_receive_bash=${2#../../../}
            sed --file=- --in-place Procfile <<SED
                s:@INTEGRATION_TEST_BASH@:$integration_test_bash:g
                s:@SITREP_RECEIVE_BASH@:$sitrep_receive_bash:g
SED

            mkdir snowflake-output
            mv Procfile snowflake-output
BASH
    },
);

our $hivemind_bash = Snowflake::Rule->new(
    name => 'sitrep » hivemind » hivemind.bash',
    dependencies => [$procfile],
    sources => {
        'hivemind.bash' => ['on_disk', 'sitrep/hivemind/hivemind.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            procfile=${1#../../../}
            sed --file=- --in-place hivemind.bash <<SED
                s:@PROCFILE@:$procfile:g
SED

            chmod +x hivemind.bash
            shellcheck hivemind.bash

            mkdir snowflake-output
            mv hivemind.bash snowflake-output
BASH
    },
);

1;
