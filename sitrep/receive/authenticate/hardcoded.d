module sitrep.receive.authenticate.hardcoded;

import sitrep.receive.authenticate : Authenticate;
import sitrep.receive.protocol : AuthenticationToken;
import std.uuid : UUID;

final
class HardcodedAuthenticate
    : Authenticate
{
    const(UUID[UUID]) keysByIdentity;

    nothrow pure @nogc @safe
    this(const(UUID[UUID]) keysByIdentity)
    {
        this.keysByIdentity = keysByIdentity;
    }

    nothrow pure @nogc @safe
    bool opCall(AuthenticationToken token) const scope
    {
        const key = token.identity in keysByIdentity;
        return key !is null && *key == token.key;
    }
}
