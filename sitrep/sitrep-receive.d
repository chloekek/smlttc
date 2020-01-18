module main;

import sitrep.receive.authenticate.hardcoded : HardcodedAuthenticate;
import sitrep.receive.serve : serve;
import std.uuid : UUID;
import util.io : Reader, Writer;

@safe
void main()
{
    auto i = Reader(0, 512);
    auto o = Writer(1);
    auto e = Writer(2);
    const keysByIdentity = [
        UUID("a37bbf27-2fb1-4436-a96a-44acb462bf4d"):
            UUID("09fbbd11-0f08-4ecd-8427-da8ce682d162"),
    ];
    auto authenticate = new HardcodedAuthenticate(keysByIdentity);
    serve(authenticate, i, o);
}
