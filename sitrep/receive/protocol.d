module sitrep.receive.protocol;

import util.binary;

import std.range : ElementType, isInputRange, isOutputRange;
import std.uuid : UUID;

////////////////////////////////////////////////////////////////////////////////
// Protocol errors

enum ProtocolError : ushort
{
    BadProtocolVersion = 0x0000,
}

final
class ProtocolException
    : Exception
{
    const(ProtocolError) error;

    pure @safe
    this(ProtocolError error,
         string        file = __FILE__,
         size_t        line = __LINE__)
    {
        import std.conv : to;
        this.error = error;
        super(error.to!string, file, line);
    }
}

void writeProtocolError(O)(ref O o, ProtocolError error)
    if (isOutputRange!(O, ubyte))
{
    writeUshort(o, error);
}

////////////////////////////////////////////////////////////////////////////////
// Protocol version

enum ProtocolVersion : ushort
{
    V0,
}

ProtocolVersion readProtocolVersion(I)(ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    const raw = readUshort(i);
    switch (raw)
    {
        case 0:  return ProtocolVersion.V0;
        default: throw new ProtocolException(ProtocolError.BadProtocolVersion);
    }
}

////////////////////////////////////////////////////////////////////////////////
// Authentication token

struct AuthenticationToken
{
    UUID identity;
    UUID key;
}

AuthenticationToken readAuthenticationToken(I)(ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    auto identity = readUuid(i);
    auto key      = readUuid(i);
    return AuthenticationToken(identity, key);
}
