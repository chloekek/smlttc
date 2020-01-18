module main;

import sitrep.receive.serve : serve;
import util.io : Reader, Writer;

@safe
void main()
{
    auto i = Reader(0, 512);
    auto o = Writer(1);
    auto e = Writer(2);
    serve(i, o);
}
