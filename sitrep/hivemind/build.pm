package sitrep::hivemind::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

use sitrep::database::build;
use sitrep::integrationTest::build;
use sitrep::receive::build;

our $procfile = Snowflake::Rule->new(
    name => 'sitrep » hivemind » Procfile',
    dependencies => [
        $sitrep::integrationTest::build::integrationTest,
        $sitrep::database::build::postgresql_conf,
        $sitrep::database::build::setup_bash,
        $sitrep::receive::build::sitrep_receive,
    ],
    sources => {
        'Procfile.template' =>
            ['on_disk', 'sitrep/hivemind/Procfile'],
        'snowflake-build' => bash_strict(<<'BASH'),
            integration_test=${1#../../../}
            postgresql_conf=${2#../../../}
            setup_bash=${3#../../../}
            sitrep_receive=${4#../../../}
            sed --file=- Procfile.template > Procfile <<SED
                s:@INTEGRATION_TEST@:$integration_test:g
                s:@POSTGRESQL_CONF@:$postgresql_conf:g
                s:@SETUP_BASH@:$setup_bash:g
                s:@SITREP_RECEIVE@:$sitrep_receive:g
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
        'hivemind.bash.template' =>
            ['on_disk', 'sitrep/hivemind/hivemind.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            localeArchive=$(getLocaleArchive)
            procfile=${1#../../../}
            sed --file=- hivemind.bash.template > hivemind.bash <<SED
                s:@LOCALE_ARCHIVE@:$localeArchive:g
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
