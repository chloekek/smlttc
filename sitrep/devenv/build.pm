package sitrep::devenv::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

use litecont::build;
use sitrep::database::build;
use sitrep::receive::build;

our $devenv_bash = Snowflake::Rule->new(
    name => 'sitrep » devenv » devenv.bash',
    dependencies => [
        $litecont::build::litecont,
        $sitrep::database::build::service,
        $sitrep::receive::build::service,
    ],
    sources => {
        'devenv.bash' => ['on_disk', 'sitrep/devenv/devenv.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            litecont=${1#../../../}
            sitrep_database_service=${2#../../../}
            sitrep_receive_service=${3#../../../}
            sed --file=- --in-place devenv.bash <<SED
                s:@LITECONT@:$litecont:g
                s:@SITREP_DATABASE_SERVICE@:$sitrep_database_service:g
                s:@SITREP_RECEIVE_SERVICE@:$sitrep_receive_service:g
SED

            chmod +x devenv.bash
            shellcheck devenv.bash

            mkdir snowflake-output
            mv devenv.bash snowflake-output
BASH
    },
);

1;
