module sitrep.receive.serve;

import sitrep.receive.protocol;

import sitrep.receive.authenticate : Authenticate;
import std.range : ElementType, isInputRange, isOutputRange;
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
                return serveV0(authenticate, i, o);
        }
    }
    catch (EofException      ex) { }
    catch (ProtocolException ex) writeProtocolError(o, ex.error);
}

private @safe
void serveV0(I, O)(Authenticate authenticate, ref I i, ref O o)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte)
    &&  isOutputRange!(O, ubyte))
{
    const authenticationToken = readAuthenticationToken(i);
    const authenticated = authenticate(authenticationToken);
    if (!authenticated)
        throw new ProtocolException(ProtocolError.CannotAuthenticate);
    const identity = authenticationToken.identity;
}
