module sitrep.receive.record.debug_;

import sitrep.receive.protocol : LogMessage;
import sitrep.receive.record : Record;
import std.format : format;
import std.range : isOutputRange, put;
import std.uuid : UUID;

/// Write log messages to an output range in a human-readable format.
/// This implementation is useful for testing and debugging.
/// This implementation does not perform authorization checks.
final
class DebugRecord(O)
    if (isOutputRange!(O, const(char)[]))
    : Record
{
    O o;

    this(O o)
    {
        this.o = o;
    }

    override
    void opCall(UUID identity, const(LogMessage) logMessage)
    {
        put(o, format!"%s %s\n"(identity, logMessage));
    }
}
