/// Operating system facilities are comprehensive and well-documented.
/// On the other hand, the wrappers in Phobos are not, so we avoid it.
/// This module exports wrappers around operating system facilities,
/// with the following properties:
///
/// $(LIST
///     * System calls are automatically retried when they fail with EINTR.
///     * Subroutines are @safe and take slices instead of pointers.
///     * Errors are reported by throwing exceptions.
///     * Names of subroutines remain unaltered.
/// )
///
/// No other behavior is added to the system calls.
/// This makes it easy to find their documentation.
/// The documentation can be found in the man pages.
module util.os;

public import core.sys.posix.fcntl : O_RDONLY;
public import core.sys.posix.sys.types : mode_t;

import std.exception : errnoEnforce;
import std.string : fromStringz, toStringz;

import errno = core.stdc.errno;
import fcntl = core.sys.posix.fcntl;
import stdlib = core.stdc.stdlib;
import unistd = core.sys.posix.unistd;

private
auto syscall(string name, alias Syscall, alias IsOk)()
{
retry:
    auto rv = Syscall();
    if (!IsOk(rv))
        if (errno.errno == errno.EINTR)
            goto retry;
        else
            errnoEnforce(false, name);
    return rv;
}

/// close(2).
@trusted
int close(int fd)
{
    return syscall!(
        "close",
        () => unistd.close(fd),
        rv => rv != -1,
    );
}

/// getenv(3).
nothrow @trusted
immutable(char)[] getenv(scope const(char)[] name)
{
    return stdlib.getenv(name.toStringz).fromStringz.idup;
}

/// open(2).
@trusted
int open(scope const(char)[] pathname, int flags, mode_t mode)
{
    const pathnameZ = pathname.toStringz;
    return syscall!(
        "open",
        () => fcntl.open(pathnameZ, flags, mode),
        rv => rv != -1,
    );
}

/// read(2).
@trusted
size_t read(int fd, scope ubyte[] buf)
{
    return syscall!(
        "read",
        () => unistd.read(fd, buf.ptr, buf.length),
        rv => rv != -1,
    );
}

/// write(2).
@trusted
size_t write(int fd, scope const(void)[] buf)
{
    return syscall!(
        "write",
        () => unistd.write(fd, buf.ptr, buf.length),
        rv => rv != -1,
    );
}
