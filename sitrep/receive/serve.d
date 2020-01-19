module sitrep.receive.serve;

import sitrep.receive.protocol;

import sitrep.receive.authenticate : Authenticate;
import std.range : ElementType, isInputRange, isOutputRange;
import std.uuid : UUID;
import util.binary : EofException;

@safe
void serve(I, O)(Authenticate authenticate, ref I i, ref O o)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte)
    &&  isOutputRange!(O, ubyte))
{
    try {
        const protocolVersion = readProtocolVersion(i);
        final switch (protocolVersion) {
            case ProtocolVersion.V0:
                return serveV0(authenticate, i);
        }
    }
    catch (EofException      ex) { }
    catch (ProtocolException ex) writeProtocolError(o, ex.error);
}

private @safe
void serveV0(I)(Authenticate authenticate, ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    const identity = serveV0Authentication(authenticate, i);
    for (;;)
        serveV0LogMessage(identity, i);
}

private @safe
UUID serveV0Authentication(I)(Authenticate authenticate, ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    const authenticationToken = readAuthenticationToken(i);
    const authenticated = authenticate(authenticationToken);
    if (!authenticated)
        throw new ProtocolException(ProtocolError.CannotAuthenticate);
    return authenticationToken.identity;
}

private @safe
void serveV0LogMessage(I)(UUID identity, ref I i)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte))
{
    const logMessage = readLogMessage(i);
    import std.format;import util.io;writeAll(2, format!"%s\n"(logMessage));
}
