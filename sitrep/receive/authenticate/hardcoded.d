module sitrep.receive.authenticate.hardcoded;

import sitrep.receive.authenticate : Authenticate;
import sitrep.receive.protocol : AuthenticationToken;
import std.uuid : UUID;

import sodium = util.sodium;

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

    pure @safe
    bool opCall(AuthenticationToken token) const scope
    {
        const key = token.identity in keysByIdentity;
        return key !is null && sodium.memcmp(key.data, token.key.data);
    }
}
