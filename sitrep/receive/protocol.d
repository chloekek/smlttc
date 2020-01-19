module sitrep.receive.protocol;

import util.binary;

import std.range : ElementType, isInputRange, isOutputRange;
import std.uuid : UUID;

////////////////////////////////////////////////////////////////////////////////
// Protocol status

enum ProtocolStatus : ushort
{
    BadProtocolVersion = 0x0000,
    CannotAuthenticate = 0x0001,
    AuthenticationOk   = 0x0002,
    LogMessageOk       = 0x0003,
}

final
class ProtocolException
    : Exception
{
    const(ProtocolStatus) status;

    pure @safe
    this(ProtocolStatus status,
         string         file = __FILE__,
         size_t         line = __LINE__)
    {
        import std.conv : to;
        this.status = status;
        super(status.to!string, file, line);
    }
}

void writeProtocolStatus(O)(ref O o, ProtocolStatus status)
    if (isOutputRange!(O, ubyte))
{
    writeUshort(o, status);
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
        default: throw new ProtocolException(ProtocolStatus.BadProtocolVersion);
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

////////////////////////////////////////////////////////////////////////////////
// Log message

struct LogMessage
{
    UUID    journal;
    ubyte[] message;
}

LogMessage readLogMessage(I)(ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    const journal = readUuid(i);
    auto  message = readDynamicArray!readUbyte(i);
    return LogMessage(journal, message);
}
