module util.io;

import util.os : read, write;

/// Input range that yields bytes read from a file descriptor.
/// Each time the range is advanced, read is called to fill an internal buffer.
/// The front of the internal buffer is always at the front of the range,
/// albeit with different data across front pops.
/// At the end of the file, the range is empty.
///
/// The buffer is filled by empty, not by popFront.
/// This prevents blocking reads when no more data is needed.
struct Reader
{
private:
    int     fd;
    ubyte[] buf;
    size_t  len;
    size_t  off;

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
        this.off = 0;
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

    @safe
    bool empty() scope
    {
        if (off == len) {
            len = read(fd, buf);
            off = 0;
        }
        return len == 0;
    }

    nothrow pure @nogc @safe
    ubyte front() const scope
    {
        return buf[off];
    }

    nothrow pure @nogc @safe
    void popFront() scope
    {
        ++off;
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
    assert(equal(&reader, "abcdefghijklmnopqrstuvwxyz\n"));
}

/// The write subroutine returns the number of bytes it wrote.
/// This may be less than the number of bytes it was asked to write,
/// in case the write was interrupted by a signal.
/// Most of the time, you want it to write all the given bytes.
/// This subroutine automatically retries the write with the remaining bytes.
@safe
void writeAll(int fd, scope const(void)[] b)
{
    import std.range : empty;
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
