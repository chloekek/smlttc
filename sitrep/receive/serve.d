module sitrep.receive.serve;

import sitrep.receive.protocol;

import sitrep.receive.authenticate : Authenticate;
import std.uuid : UUID;
import util.binary : EofException, isReader, isWriter;

@safe
void serve(I, O)(Authenticate authenticate, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    try {
        const protocolVersion = readProtocolVersion(i);
        final switch (protocolVersion) {
            case ProtocolVersion.V0:
                writeProtocolStatus(o, ProtocolStatus.ProtocolVersionOk);
                return serveV0(authenticate, i, o);
        }
    }
    catch (EofException      ex) { }
    catch (ProtocolException ex) writeProtocolStatus(o, ex.status);
}

private @safe
void serveV0(I, O)(Authenticate authenticate, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    const identity = serveV0Authentication(authenticate, i, o);
    for (;;)
        serveV0LogMessage(identity, i, o);
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
void serveV0LogMessage(I, O)(UUID identity, ref I i, ref O o)
    if (isReader!I
    &&  isWriter!O)
{
    const logMessage = readLogMessage(i);
    import std.format;import util.io;writeAll(2, format!"%s\n"(logMessage));
    // TODO: Store log message prior to sending status.
    writeProtocolStatus(o, ProtocolStatus.LogMessageOk);
}
