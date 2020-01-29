module sitrep.receive.authenticate.database;

import sitrep.receive.authenticate : Authenticate;
import sitrep.receive.protocol : AuthenticationToken;
import std.uuid : UUID;

import pq = util.pq;

final
class DatabaseAuthenticate
    : Authenticate
{
private:
    pq.Connection* db;

public:
    nothrow pure @nogc @safe
    this(ref pq.Connection db)
    {
        this.db = &db;
    }

    override @safe
    bool opCall(AuthenticationToken token) scope
    {
        import pgdata = util.pgdata;

        db.execute(`START TRANSACTION READ ONLY`, []);
        scope(success) db.execute(`COMMIT WORK`, []);
        scope(failure) db.execute(`ROLLBACK WORK`, []);

        db.execute(`SELECT sitrep.set_identity_id($1)`,
                   [pgdata.encodeUuid(token.identity)]);

        return authenticate(token.key);
    }

    private @safe
    bool authenticate(UUID key) scope
    {
        import std.algorithm : any, map;
        import std.range     : iota;
        import util.pgdata   : decodeUuid;
        import sodium = util.sodium;
        enum  query  = `SELECT key FROM sitrep.authentication_tokens`;
        const result = db.execute(query, []);
        return iota(result.rows)
               .map!(row => result[row, 0].decodeUuid)
               .any!(candidate => sodium.memcmp(candidate.data, key.data));
    }
}
