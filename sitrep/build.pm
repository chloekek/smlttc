package sitrep::build;

use v5.12;
use strict;

use sitrep::devenv::build;
use sitrep::doc::build;
use sitrep::integrationTest::build;

our %artifacts = (
    'sitrep-database-setup' => $sitrep::database::build::setup_bash,
    'sitrep-devenv' => $sitrep::devenv::build::devenv_bash,
    'sitrep-doc' => $sitrep::doc::build::doc,
    'sitrep-integration-test' => $sitrep::integrationTest::build::integrationTest_bash,
);

1;
