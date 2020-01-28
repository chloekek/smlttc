package sitrep::doc::build;

use v5.12;
use strict;

use Snowflake::Rule;
use Snowflake::Rule::Util qw(bash_strict);

our $doc = Snowflake::Rule->new(
    name => 'sitrep » doc » doc',
    dependencies => [],
    sources => {
        'doc' => ['on_disk', 'sitrep/doc'],
        'snowflake-build' => bash_strict(<<'BASH'),
            docbook2html \
                --stringparam base.dir snowflake-output/ \
                --stringparam chunker.output.encoding UTF-8 \
                --stringparam html.stylesheet style.css \
                --stringparam use.id.as.filename 1 \
                --xinclude \
                -- doc/index.xml
            mv doc/style.css snowflake-output/style.css
BASH
    },
);

1;
