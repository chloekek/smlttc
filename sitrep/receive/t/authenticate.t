use v5.12;
use strict;

use IO::Socket::INET;
use Test::More;

use constant AuthenticationOk   => 0x0002;
use constant CannotAuthenticate => 0x0001;
use constant ProtocolVersionOk  => 0x0004;

################################################################################
# Test data

my @table = (
    [ 'Identity and token do not exist'
    , '0000000a-dbad-badb-adba-dbadbadbadba'
    , '0000000c-dbad-badb-adba-dbadbadbadba'
    , CannotAuthenticate ],

    [ 'Identity exists but token does not'
    , '0000000a-0000-0000-0000-000000000001'
    , '0000000c-dbad-badb-adba-dbadbadbadba'
    , CannotAuthenticate ],

    [ 'Identity does not exist but token does'
    , '0000000a-dbad-badb-adba-dbadbadbadba'
    , '0000000c-0000-0000-0001-000000000001'
    , CannotAuthenticate ],

    [ 'Identity and token exist and do not match'
    , '0000000a-0000-0000-0000-000000000002'
    , '0000000c-0000-0000-0001-000000000001'
    , CannotAuthenticate ],

    [ 'Identity and token exist and match'
    , '0000000a-0000-0000-0000-000000000001'
    , '0000000c-0000-0000-0001-000000000001'
    , AuthenticationOk ],

    [ 'Identity and token exist and match, but token has expired'
    , '0000000a-0000-0000-0000-000000000001'
    , '0000000c-0000-0000-0002-000000000001'
    , CannotAuthenticate ],
);

################################################################################
# Test logic

plan tests => scalar(@table);

for (@table) {
    my $description = $_->[0];
    my $identity    = $_->[1];
    my $key         = $_->[2];
    my $expected    = $_->[3];

    my $socket = IO::Socket::INET->new(PeerAddr => '127.0.0.1:1080');

    {
        print $socket pack('S<', 0);
        read  $socket, my $res, 2;
        if (unpack('S<', $res) != ProtocolVersionOk) {
            die('Unexpected version response');
        }
    }

    {
        print $socket encodeUuid($identity) . encodeUuid($key);
        read  $socket, my $res, 2;
        is(unpack('S<', $res), $expected, $description);
    }

    $socket->close;
}

################################################################################
# Utilities

sub encodeUuid
{
    my ($uuid) = @_;
    $uuid =~ s/-//g;
    $uuid =~ s/([0-9a-f]{2})/chr(hex($1))/eg;
    $uuid;
}
