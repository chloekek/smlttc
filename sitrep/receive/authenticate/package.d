module sitrep.receive.authenticate;

import sitrep.receive.protocol : AuthenticationToken;

interface Authenticate
{
    @safe
    bool opCall(AuthenticationToken token);
}
