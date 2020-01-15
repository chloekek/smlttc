module util.io;

import util.os : read, write;
import std.range : empty;

/// Input range that yields chunks read from a file descriptor.
/// Each time the range is advanced, read is called to fill an internal buffer.
/// The internal buffer is always at the front of the range,
/// albeit with different data across front pops.
/// At the end of the file, the range is empty.
struct Reader
{
private:
    int     fd;
    ubyte[] buf;
    size_t  len;

public:
    @disable this();
    @disable this(this);

    /// Initialize the reader with a file descriptor and a buffer.
    /// The buffer may be of any positive size.
    nothrow pure @nogc @safe
    this(int fd, ubyte[] buf)
    in
    {
        assert(buf.length > 0);
    }
    do
    {
        this.fd  = fd;
        this.buf = buf;
        this.len = 0;
    }

    /// ditto
    nothrow pure @safe
    this(int fd, size_t bufSize)
    in
    {
        assert(bufSize > 0);
    }
    do
    {
        this(fd, new ubyte[bufSize]);
    }

    private @safe
    void ensureFilled()
    {
        if (len == 0)
            len = read(fd, buf);
    }

    @safe
    bool empty()
    {
        ensureFilled();
        return len == 0;
    }

    nothrow pure @nogc @safe
    inout(ubyte)[] front() inout
    {
        return buf[0 .. len];
    }

    nothrow pure @nogc @safe
    void popFront()
    {
        len = 0;
    }
}

///
@safe
unittest
{
    import std.algorithm : equal, joiner;
    import util.os : O_RDONLY, close, open;

    const fd = open("util/testdata/alphabet", O_RDONLY, 0);
    scope(exit) close(fd);

    auto reader = Reader(fd, 8);
    auto bytes  = joiner(&reader);
    assert(equal(bytes, "abcdefghijklmnopqrstuvwxyz\n"));
}

/// The write subroutine returns the number of bytes it wrote.
/// This may be less than the number of bytes it was asked to write,
/// in case the write was interrupted by a signal.
/// Most of the time, you want it to write all the given bytes.
/// This subroutine automatically retries the write with the remaining bytes.
@safe
void writeAll(int fd, scope const(void)[] b)
{
    while (!b.empty) {
        const n = write(fd, b);
        b = b[n .. $];
    }
}

/// Output range that calls writeAll each time a byte slice is put into it.
/// The output range stores (but does not own) a file descriptor.
/// No buffering is performed; that would the job of
/// a more general buffering output range decorator.
struct Writer
{
private:
    int fd;

public:
    @disable this();

    nothrow pure @nogc @safe
    this(int fd)
    {
        this.fd = fd;
    }

    @safe
    void put(scope const(void)[] b) const scope
    {
        writeAll(fd, b);
    }
}
