use v5.12;
use strict;

use IO::Socket::INET;
use Test::More tests => 101;

use constant BadProtocolVersion => 0x0000;
use constant ProtocolVersionOk  => 0x0004;

sub sendRequest
{
    my $req = pack('S<', shift);
    my $res;
    my $socket = IO::Socket::INET->new(PeerAddr => '127.0.0.1:1080');
    $socket->print($req);
    $socket->read($res, 2);
    $socket->close;
    unpack('S<', $res);
}

my @okVersions  = (0);
my @badVersions = map { int(1 + rand(2 ** 16 - 1)) } 1 .. 100;

is(sendRequest($_), ProtocolVersionOk,  "OK version $_" ) for @okVersions;
is(sendRequest($_), BadProtocolVersion, "Bad version $_") for @badVersions;
