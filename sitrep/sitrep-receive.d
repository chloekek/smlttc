module main;

import std.range : put;
import std.string : format;
import util.binary : readUshort;
import util.io : Reader, Writer;

@safe
void main()
{
    auto stdin  = Reader(0, 512);
    auto stdout = Writer(1);
    auto stderr = Writer(2);

    const protocolVersion = readUshort(stdin);

    put(stdout, format!"%d\n"(protocolVersion));
    put(stderr, format!"%d\n"(protocolVersion));
}
