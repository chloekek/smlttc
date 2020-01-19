module sitrep.receive.serve;

import sitrep.receive.protocol;

import sitrep.receive.authenticate : Authenticate;
import sitrep.receive.record : Record, UnauthorizedRecordException;
import std.uuid : UUID;
import util.binary : EofException, isReader, isWriter;

@safe
void serve(I, O)(Authenticate authenticate, Record record, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    try {
        const protocolVersion = readProtocolVersion(i);
        final switch (protocolVersion) {
            case ProtocolVersion.V0:
                writeProtocolStatus(o, ProtocolStatus.ProtocolVersionOk);
                return serveV0(authenticate, record, i, o);
        }
    }
    catch (EofException      ex) { }
    catch (ProtocolException ex) writeProtocolStatus(o, ex.status);
}

private @safe
void serveV0(I, O)(Authenticate authenticate, Record record, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    const identity = serveV0Authentication(authenticate, i, o);
    for (;;)
        serveV0LogMessage(record, identity, i, o);
}

private @safe
UUID serveV0Authentication(I, O)(Authenticate authenticate, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    const authenticationToken = readAuthenticationToken(i);
    const authenticated = authenticate(authenticationToken);
    if (!authenticated)
        throw new ProtocolException(ProtocolStatus.CannotAuthenticate);
    writeProtocolStatus(o, ProtocolStatus.AuthenticationOk);
    return authenticationToken.identity;
}

private @safe
void serveV0LogMessage(I, O)(Record record, UUID identity, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    try {
        const logMessage = readLogMessage(i);
        record(identity, logMessage);
        writeProtocolStatus(o, ProtocolStatus.LogMessageOk);
    } catch (UnauthorizedRecordException) {
        writeProtocolStatus(o, ProtocolStatus.LogMessageUnauthorized);
    }
}
