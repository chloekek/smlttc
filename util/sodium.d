module util.sodium;

import std.exception : enforce;

extern(C) nothrow private @nogc @system
{
    int sodium_init();

    pure
    int sodium_memcmp(const(void)* b1_, const(void)* b2_, size_t len);
}

@trusted
shared static this()
{
    const ok = sodium_init();
    enforce(ok != -1);
}

pure @trusted
bool memcmp(const(void)[] a, const(void)[] b)
{
    enforce(a.length == b.length);
    return sodium_memcmp(a.ptr, b.ptr, a.length) == 0;
}

///
pure @safe
unittest
{
    assert( memcmp("", ""));
    assert( memcmp("abc", "abc"));
    assert(!memcmp("abc", "def"));
}
