package sitrep::build;

use v5.12;
use strict;

use sitrep::doc::build;
use sitrep::hivemind::build;
use sitrep::receive::build;

our %artifacts = (
    'sitrep-doc' => $sitrep::doc::build::doc,
    'sitrep-database-with.bash' => $sitrep::database::build::with_bash,
    'sitrep-hivemind.bash' => $sitrep::hivemind::build::hivemind_bash,
    'sitrep-sitrep-receive' => $sitrep::receive::build::sitrep_receive,
);

1;
