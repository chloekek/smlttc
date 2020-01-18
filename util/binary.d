/// This module presents functions for working with binary data.
module util.binary;

import std.range : ElementType, isInputRange;

/// Thrown when reading binary data from an empty input range.
final
class EofException
    : Exception
{
    nothrow pure @nogc @safe
    this(immutable(char)[] file = __FILE__, size_t line = __LINE__)
    {
        super("Unexpected end of input", file, line);
    }
}

private
immutable(char)[] readInteger(string article, T)()
{
    import std.format : format;
    import std.string : capitalize;
    enum snippet = q{
        /// Read %s %s from an input range of bytes.
        /// The integer is read in little endian byte order.
        %s read%s(I)(ref I i)
            if (isInputRange!I
            &&  is(ElementType!I : ubyte))
        {
            import std.range : empty, front, iota, popFront;
            alias T = typeof(return);
            T r = 0;
            static foreach (n; iota(T.sizeof)) {{
                if (i.empty) throw new EofException();
                ubyte b = i.front;
                i.popFront;
                r |= cast(T) b << 8 * n;
            }}
            return r;
        }

        ///
        pure @safe
        unittest
        {
            ubyte[] bytes = [0xFF, 0xEE, 0xDD, 0xCC,
                             0xBB, 0xAA, 0x99, 0x88,
                             0x77];
            const   value = read%s(bytes);
            assert(value == cast(%s) 0x8899AABBCCDDEEFF);
            assert(bytes.length == 9 - value.sizeof);
        }
    };
    return format!snippet(article, T.stringof, T.stringof,
                          T.stringof.capitalize, T.stringof.capitalize,
                          T.stringof);
}

mixin(readInteger!("a",  ubyte ));
mixin(readInteger!("a",  ushort));
mixin(readInteger!("a",  uint  ));
mixin(readInteger!("a",  ulong ));

mixin(readInteger!("a",  byte  ));
mixin(readInteger!("a",  short ));
mixin(readInteger!("an", int   ));
mixin(readInteger!("a",  long  ));
