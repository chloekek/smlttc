module sitrep.receive.serve;

import sitrep.receive.protocol;

import std.range : ElementType, isInputRange, isOutputRange;
import util.binary : EofException;

@safe
void serve(I, O)(ref I i, ref O o)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte)
    &&  isOutputRange!(O, ubyte))
{
    try {
        const protocolVersion = readProtocolVersion(i);
        final switch (protocolVersion) {
            case ProtocolVersion.V0: return serveV0(i, o);
        }
    }
    catch (EofException      ex) { }
    catch (ProtocolException ex) writeProtocolError(o, ex.error);
}

private @safe
void serveV0(I, O)(ref I i, ref O o)
    if (isInputRange!I
    &&  is(ElementType!I : ubyte)
    &&  isOutputRange!(O, ubyte))
{
    const authenticationToken = readAuthenticationToken(i);
}
