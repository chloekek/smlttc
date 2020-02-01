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

public import core.sys.linux.sched : CLONE_NEWNS, CLONE_NEWPID, CLONE_NEWUSER;
public import core.sys.posix.fcntl : O_RDONLY, O_WRONLY;
public import core.sys.posix.sys.types : gid_t, mode_t, uid_t;

import std.exception : errnoEnforce;
import std.string : fromStringz, toStringz;

import errno = core.stdc.errno;
import fcntl = core.sys.posix.fcntl;
import sched = core.sys.linux.sched;
import stdlib = core.stdc.stdlib;
import unistd = core.sys.posix.unistd;

extern(C) nothrow private @nogc @system
{
    int chroot(scope const(char)* path);

    int mount(scope const(char)* source,
              scope const(char)* target,
              scope const(char)* filesystemtype,
              ulong              mountflags,
              scope const(char)* data);
}

enum MS_BIND   = 4096;
enum MS_REC    = 16384;

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

/// chdir(2).
@trusted
void chdir(scope const(char)[] path)
{
    const pathZ = path.toStringz;
    syscall!(
        "chdir",
        () => unistd.chdir(pathZ),
        rv => rv != -1,
    );
}

/// chroot(2).
@trusted
void chroot(scope const(char)[] path)
{
    const pathZ = path.toStringz;
    syscall!(
        "chroot",
        () => chroot(pathZ),
        rv => rv != -1,
    );
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

/// execvp(3).
@trusted
void execvp(scope const(char)[] pathname, scope const(char[])[] arguments)
{
    import std.algorithm : map;
    import std.array     : array;
    import std.range     : chain, only;
    const pathnameZ   = pathname.toStringz;
    const argumentZsZ = chain(arguments.map!toStringz, only(null)).array;
    syscall!(
        "execvp",
        () => unistd.execvp(pathnameZ, argumentZsZ.ptr),
        rv => rv != -1,
    );
}

/// getenv(3).
nothrow @trusted
immutable(char)[] getenv(scope const(char)[] name)
{
    return stdlib.getenv(name.toStringz).fromStringz.idup;
}

/// getegid(2).
nothrow @nogc @safe
gid_t getegid()
{
    return unistd.getegid();
}

/// geteuid(2).
nothrow @nogc @safe
uid_t geteuid()
{
    return unistd.geteuid();
}

/// mount(2).
@trusted
void mount(scope const(char)[] source,
           scope const(char)[] target,
           scope const(char)[] filesystemtype,
           ulong               mountflags,
           scope const(char)[] data)
{
    const sourceZ         = source.toStringz;
    const targetZ         = target.toStringz;
    const filesystemtypeZ = filesystemtype.toStringz;
    const dataZ           = data.toStringz;
    syscall!(
        "mount",
        () => mount(sourceZ, targetZ, filesystemtypeZ, mountflags, dataZ),
        rv => rv != -1,
    );
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

/// unshare(2).
@safe
void unshare(int flags)
{
    syscall!(
        "unshare",
        () => sched.unshare(flags),
        rv => rv != -1,
    );
}
