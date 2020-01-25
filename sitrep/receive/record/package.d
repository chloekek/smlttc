module sitrep.receive.record;

import sitrep.receive.protocol : LogMessage;
import std.uuid : UUID;

/// Record log messages to permanent storage (or elsewhere).
/// It is up to the implementation to perform authorization checks.
/// The authorization checks must verify that the client can access the journal.
/// Because of this, it receives the identity of the client.
/// If authorization fails, throw UnauthorizedRecordException.
interface Record
{
    @safe
    void opCall(UUID identity, const(LogMessage) logMessage);
}

final
class UnauthorizedRecordException
    : Exception
{
    const(UUID) identity;
    const(UUID) journal;

    nothrow pure @nogc @safe
    this(UUID identity,
         UUID journal,
         string file = __FILE__,
         size_t line = __LINE__)
    {
        this.identity = identity;
        this.journal  = journal;
        super("Unauthorized", file, line);
    }
}
