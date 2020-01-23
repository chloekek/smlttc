module main;

import sitrep.receive.authenticate.hardcoded : HardcodedAuthenticate;
import sitrep.receive.record.debug_ : DebugRecord;
import sitrep.receive.serve : serve;
import std.uuid : UUID;
import util.io : Reader, Writer;

import pq = util.pq;

@safe
void main()
{
    auto db = pq.Connection("");
    const result = db.execute("SELECT $1::text, $2, version()", [null, "a"]);
    Writer(2).put(result[0, 0] ~ "\n");
    Writer(2).put(result[0, 1] ~ "\n");
    Writer(2).put(result[0, 2] ~ "\n");
    auto i  = Reader(0, 512);
    auto o  = Writer(1);
    const keysByIdentity = [
        UUID("a37bbf27-2fb1-4436-a96a-44acb462bf4d"):
            UUID("09fbbd11-0f08-4ecd-8427-da8ce682d162"),
    ];
    auto authenticate = new HardcodedAuthenticate(keysByIdentity);
    auto record = new DebugRecord!Writer(Writer(2));
    serve(authenticate, record, i, o);
}
