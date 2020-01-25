module sitrep.receive.record.database;

import sitrep.receive.protocol : LogMessage;
import sitrep.receive.record : Record, UnauthorizedRecordException;
import std.uuid : UUID;

import pgdata = util.pgdata;
import pq = util.pq;

final
class DatabaseRecord
    : Record
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
    void opCall(UUID identity, scope const(LogMessage) logMessage) scope
    {
        db.execute(`START TRANSACTION`, []);
        scope(success) db.execute(`COMMIT WORK`, []);
        scope(failure) db.execute(`ROLLBACK WORK`, []);

        db.execute(`SELECT sitrep.set_identity_id($1)`,
                   [pgdata.encodeUuid(identity)]);

        try
            insertLogMessage(logMessage);
        catch (pq.ExecuteException ex)
            if (ex.sqlstate == "42501")
                throw new UnauthorizedRecordException(identity, logMessage.journal);
            else
                throw ex;
    }

    private @safe
    void insertLogMessage(scope const(LogMessage) logMessage) scope
    {
        db.execute(
            `
                INSERT INTO sitrep.log_messages (journal_id, message)
                VALUES ($1, $2)
            `,
            [
                pgdata.encodeUuid(logMessage.journal),
                pgdata.encodeBytea(logMessage.message),
            ],
        );
    }
}
