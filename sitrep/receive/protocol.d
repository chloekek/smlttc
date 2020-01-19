module sitrep.receive.protocol;

import util.binary;

import std.range : ElementType, isInputRange, isOutputRange;
import std.uuid : UUID;

////////////////////////////////////////////////////////////////////////////////
// Protocol status

enum ProtocolStatus : ushort
{
    /// Sent when the protocol version that the client wants to use is not
    /// supported by the server.
    BadProtocolVersion = 0x0000,

    /// Sent when the authentication token the client sent contains a
    /// non-existent identity or an invalid key.
    CannotAuthenticate = 0x0001,

    /// Sent when authentication succeeded after the client sent an
    /// authentication token.
    AuthenticationOk   = 0x0002,

    /// Sent when a log message was successfully recorded after the client sent
    /// a log message.
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
