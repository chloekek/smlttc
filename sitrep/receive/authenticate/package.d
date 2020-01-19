module sitrep.receive.authenticate;

import sitrep.receive.protocol : AuthenticationToken;

/// Return true iff authentication succeeds.
/// Do not throw an exception for unknown identities or invalid keys.
interface Authenticate
{
    @safe
    bool opCall(AuthenticationToken token);
}
