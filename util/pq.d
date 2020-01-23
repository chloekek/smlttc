module util.pq;

extern(C) nothrow private @nogc @system
{
    struct PGconn;
    struct PGresult;

    alias Oid = uint;

    enum ConnStatusType
    {
        CONNECTION_OK,
        CONNECTION_BAD,
        CONNECTION_STARTED,
        CONNECTION_MADE,
        CONNECTION_AWAITING_RESPONSE,
        CONNECTION_AUTH_OK,
        CONNECTION_SETENV,
        CONNECTION_SSL_STARTUP,
        CONNECTION_NEEDED,
        CONNECTION_CHECK_WRITABLE,
        CONNECTION_CONSUME,
        CONNECTION_GSS_STARTUP,
        CONNECTION_CHECK_TARGET,
    }

    enum ExecStatusType
    {
        PGRES_EMPTY_QUERY,
        PGRES_COMMAND_OK,
        PGRES_TUPLES_OK,
        PGRES_COPY_OUT,
        PGRES_COPY_IN,
        PGRES_BAD_RESPONSE,
        PGRES_NONFATAL_ERROR,
        PGRES_FATAL_ERROR,
        PGRES_COPY_BOTH,
        PGRES_SINGLE_TUPLE,
    }

    PGconn* PQconnectdb(scope const(char)* conninfo);
    void PQfinish(PGconn* conn);

    ConnStatusType PQstatus(scope const(PGconn)* conn);
    char* PQerrorMessage(scope const(PGconn)* conn);

    PGresult* PQexecParams(scope PGconn*       conn,
                           scope const(char)*  command,
                           int                 nParams,
                           scope const(Oid)*   paramTypes,
                           scope const(char*)* paramValues,
                           scope const(int)*   paramLengths,
                           scope const(int)*   paramFormats,
                           int                 resultFormat);

    ExecStatusType PQresultStatus(scope const(PGresult)* res);
    char* PQresultErrorMessage(const(PGresult)* res);
    int PQntuples(scope const(PGresult)* res);
    int PQnfields(scope const(PGresult)* res);
    char* PQgetvalue(scope const(PGresult)* res,
                     int row_number,
                     int column_number);
    void PQclear(PGresult* res);
}

struct Connection
{
private:
    PGconn* raw;

public:
    @disable this();
    @disable this(this);

    @trusted
    this(scope const(char)[] conninfo)
    {
        import std.exception : enforce;
        import std.string    : toStringz;
        auto conn = PQconnectdb(conninfo.toStringz);
        scope(failure) PQfinish(conn);
        enforce(PQstatus(conn) == ConnStatusType.CONNECTION_OK,
                new ConnectionException(conn));
        raw = conn;
    }

    nothrow @nogc @trusted
    ~this()
    {
        PQfinish(raw);
        raw = null;
    }

    @trusted
    Result execute(scope const(char)[] command, scope const(char[])[] params)
        scope
    {
        import std.algorithm : map;
        import std.array     : array;
        import std.exception : enforce;
        import std.string    : toStringz;

        enforce(params.length <= int.max,
                new ExecuteException("PQexecParams: Too many arguments"));

        const paramValues =
            params.map!(a => a is null ? null : a.toStringz)
                  .array;

        auto result = PQexecParams(
            /* conn */         raw,
            /* command */      command.toStringz,
            /* nParams */      cast(int) params.length,
            /* paramTypes */   null,
            /* paramValues */  paramValues.ptr,
            /* paramLengths */ null,
            /* paramFormats */ null,
            /* resultFormat */ 0,
        );

        scope(failure) PQclear(result);

        const status = PQresultStatus(result);
        enforce(status == ExecStatusType.PGRES_EMPTY_QUERY ||
                status == ExecStatusType.PGRES_COMMAND_OK  ||
                status == ExecStatusType.PGRES_TUPLES_OK   ||
                status == ExecStatusType.PGRES_SINGLE_TUPLE,
                new ExecuteException(result));

        return Result(result);
    }
}

struct Result
{
private:
    PGresult* raw;

public:
    @disable this();
    @disable this(this);

    nothrow private pure @nogc @system
    this(PGresult* raw)
    {
        this.raw = raw;
    }

    nothrow @nogc @trusted
    ~this()
    {
        PQclear(raw);
        raw = null;
    }

    @trusted
    const(char)[] opIndex(size_t row, size_t column) const return scope
    {
        import std.exception : enforce;
        import std.string    : fromStringz;
        enforce(row    < PQntuples(raw));
        enforce(column < PQnfields(raw));
        return PQgetvalue(raw, cast(int) row, cast(int) column).fromStringz;
    }
}

abstract
class PostgresqlException
    : Exception
{
    nothrow private pure @nogc @safe
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

final
class ConnectionException
    : PostgresqlException
{
    nothrow private @system
    this(scope const(PGconn)* conn,
         string file = __FILE__,
         size_t line = __LINE__)
    {
        import std.string : fromStringz;
        immutable msg = PQerrorMessage(conn).fromStringz.idup;
        super(msg, file, line);
    }
}

final
class ExecuteException
    : PostgresqlException
{
    nothrow private pure @nogc @safe
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }

    nothrow private @system
    this(scope const(PGresult)* result,
         string file = __FILE__,
         size_t line = __LINE__)
    {
        import std.string : fromStringz;
        immutable msg = PQresultErrorMessage(result).fromStringz.idup;
        super(msg, file, line);
    }
}
