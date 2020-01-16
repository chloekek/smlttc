module main;

import util.io : writeAll;

@safe
void main()
{
    writeAll(1, "stdout\n");
    writeAll(2, "stderr\n");
}
