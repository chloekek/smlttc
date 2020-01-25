/// Encoding and decoding of PostgreSQL values.
module util.pgdata;

import std.uuid : UUID;

final
class DecodeException
    : Exception
{
    nothrow pure @nogc @safe
    this(string msg, string file = __FILE__, size_t line = __LINE__)
    {
        super(msg, file, line);
    }
}

pure @safe
bool decodeBoolean(const(char)[] encoding)
{
    switch (encoding) {
        case "f": return false;
        case "t": return true;
        default:  throw new DecodeException("boolean");
    }
}

nothrow pure @safe
immutable(char)[] encodeUuid(UUID value)
{
    return value.toString;
}

nothrow pure @safe
char[] encodeBytea(const(ubyte)[] value)
{
    enum hex = "0123456789ABCDEF";
    auto chars = new char[2 + 2 * value.length];
    chars[0] = '\\';
    chars[1] = 'x';
    foreach (i, b; value) {
        chars[2 + 2 * i + 0] = hex[b >>> 4];
        chars[2 + 2 * i + 1] = hex[b & 0xF];
    }
    return chars;
}

///
nothrow pure @safe
unittest
{
    assert(encodeBytea([])           == "\\x");
    assert(encodeBytea([0x01])       == "\\x01");
    assert(encodeBytea([0x00, 0xFF]) == "\\x00FF");
}
