package sitrep::database::build;

use v5.12;
use warnings;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

our $pg_hba_conf = Snowflake::Rule->new(
    name => 'sitrep » database » pg_hba.conf',
    dependencies => [],
    sources => {
        'pg_hba.conf.template' =>
            ['on_disk', 'sitrep/database/pg_hba.conf'],
        'snowflake-build' => bash_strict(<<'BASH'),
            mkdir snowflake-output
            mv pg_hba.conf.template pg_hba.conf
            mv pg_hba.conf snowflake-output
BASH
    },
);

our $pg_ident_conf = Snowflake::Rule->new(
    name => 'sitrep » database » pg_ident.conf',
    dependencies => [],
    sources => {
        'pg_ident.conf.template' =>
            ['on_disk', 'sitrep/database/pg_ident.conf'],
        'snowflake-build' => bash_strict(<<'BASH'),
            mkdir snowflake-output
            mv pg_ident.conf.template pg_ident.conf
            mv pg_ident.conf snowflake-output
BASH
    },
);

our $postgresql_conf = Snowflake::Rule->new(
    name => 'sitrep » database » postgresql.conf',
    dependencies => [$pg_hba_conf, $pg_ident_conf],
    sources => {
        'postgresql.conf.template' =>
            ['on_disk', 'sitrep/database/postgresql.conf'],
        'snowflake-build' => bash_strict(<<'BASH'),
            pg_hba=${1#../../../}
            pg_ident=${2#../../../}
            sed --file=- postgresql.conf.template > postgresql.conf <<SED
                s:@PG_HBA@:$pg_hba:g
                s:@PG_IDENT@:$pg_ident:g
SED

            mkdir snowflake-output
            mv postgresql.conf snowflake-output
BASH
    },
);

our $schema = Snowflake::Rule->new(
    name => 'sitrep » database » schema',
    dependencies => [],
    sources => {
        'schema' => ['on_disk', 'sitrep/database/schema'],
        'snowflake-build' => bash_strict(<<'BASH'),
            mv schema snowflake-output
BASH
    },
);

our $setup_bash = Snowflake::Rule->new(
    name => 'sitrep » database » setup.bash',
    dependencies => [$schema],
    sources => {
        'setup.bash.template' =>
            ['on_disk', 'sitrep/database/setup.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            schema=${1#../../../}
            sed --file=- setup.bash.template > setup.bash <<SED
                s:@SCHEMA@:$schema:g
SED

            chmod +x setup.bash
            shellcheck setup.bash

            mkdir snowflake-output
            mv setup.bash snowflake-output
BASH
    },
);

our $with_bash = Snowflake::Rule->new(
    name => 'sitrep » database » with.bash',
    dependencies => [
        $postgresql_conf,
        $setup_bash,
    ],
    sources => {
        'with.bash.template' =>
            ['on_disk', 'sitrep/database/with.bash'],
        'snowflake-build' => bash_strict(<<'BASH'),
            postgresql_conf=${1#../../../}
            setup_bash=${2#../../../}
            sed --file=- with.bash.template > with.bash <<SED
                s:@POSTGRESQL_CONF@:$postgresql_conf:g
                s:@SETUP_BASH@:$setup_bash:g
SED

            chmod +x with.bash
            shellcheck with.bash

            mkdir snowflake-output
            mv with.bash snowflake-output
BASH
    },
);

1;
