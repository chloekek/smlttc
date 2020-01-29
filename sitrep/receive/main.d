module sitrep.receive.main;

@safe
void main()
{
    import sitrep.receive.authenticate.database : DatabaseAuthenticate;
    import sitrep.receive.record.database       : DatabaseRecord;
    import sitrep.receive.serve                 : serve;
    import util.io                              : Reader, Writer;
    import util.pq                              : Connection;
    auto db           = Connection("");
    auto authenticate = new DatabaseAuthenticate(db);
    auto record       = new DatabaseRecord(db);
    auto stdin        = Reader(0, 512);
    auto stdout       = Writer(1);
    serve(authenticate, record, stdin, stdout);
}
