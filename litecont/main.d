module main;

import std.typecons : Tuple;

import io = util.io;
import os = util.os;

/// Overwrite the contents of a file with a string.
/// The string is written all at once; with a single system call.
/// This ensures that files in /proc are written atomically.
void spurt(string fmt, FmtArgs...)(const(char)[] pathname, FmtArgs fmtArgs)
{
    import std.string : format;
    const data = format!(fmt, FmtArgs)(fmtArgs);
    const file = os.open(pathname, os.O_WRONLY, 0);
    scope(exit) os.close(file);
    os.write(file, data);
}

struct Options
{
    bool                     help;
    Tuple!(string, string)[] bindMounts;
    string                   chroot;
    string[]                 command;

    @trusted
    this(string[] argv)
    {
        import std.algorithm : map;
        import std.array     : array;
        import std.getopt    : GetOptException, getopt;

        bool     optHelp = false;
        string[] optBindMount;
        string   optChroot;

        try {
            const getoptResult = getopt(
                argv,
                "bind-mount", &optBindMount,
                "chroot",     &optChroot,
            );
            if (getoptResult.helpWanted || argv.length <= 1)
                optHelp = true;
        } catch (GetOptException) {
            optHelp = true;
        }

        help       = optHelp;
        bindMounts = optBindMount.map!parseBindMount.array;
        chroot     = optChroot;
        command    = argv[1 .. $];
    }

    nothrow private pure static @safe
    Tuple!(string, string) parseBindMount(string input)
    {
        import std.algorithm : countUntil;
        import std.typecons  : tuple;
        const index = (cast(immutable(ubyte)[]) input).countUntil(':');
        if (index == -1)
            return tuple(input, input);
        else
            return tuple(input[0 .. index], input[index + 1 .. $]);
    }
}

@safe
int main(string[] argv)
{
    const options = Options(argv);

    if (options.help) {
        enum help = "Usage: litecont [OPTIONS ...] -- COMMAND [ARGUMENTS ...]\n"
                  ~ "\n"
                  ~ "Options:\n"
                  ~ "\n"
                  ~ "  --bind-mount source          Establish a recursive bind mount\n"
                  ~ "  --bind-mount source:target   Establish a recursive bind mount\n"
                  ~ "  --chroot     directory       Establish a chroot\n";
        io.writeAll(2, help);
        return 1;
    }

    try {
        const uid = os.geteuid();
        const gid = os.getegid();

        // Create a new user namespace and map root to our user.
        // This allows us to invoke system calls that require root privileges.
        // Those privileges will not go beyond the namespace, obviously.
        os.unshare(os.CLONE_NEWUSER);
        spurt!"deny"("/proc/self/setgroups");
        spurt!"0 %d 1"("/proc/self/uid_map", uid);
        spurt!"0 %d 1"("/proc/self/gid_map", gid);

        // Create a new mount namespace, and apply the requested mounts.
        os.unshare(os.CLONE_NEWNS);
        foreach (bindMount; options.bindMounts)
            os.mount(bindMount[0], bindMount[1], null,
                     os.MS_BIND | os.MS_REC, null);

        // Create a new pid namespace for the command to use.
        // The first process spawned by the command will have pid 1.
        os.unshare(os.CLONE_NEWPID);

        // Restore the user map so that whoami reports the correct user.
        // This is important for paranoid programs like postgres,
        // that refuse to run if the user looks like root.
        os.unshare(os.CLONE_NEWUSER);
        spurt!"%d 0 1"("/proc/self/uid_map", uid);
        spurt!"%d 0 1"("/proc/self/gid_map", gid);

        // Entering the chroot must be done after creating the user namespace,
        // because you cannot enter a user namespace from a chroot.
        if (options.chroot != "") {
            os.chroot(options.chroot);
            os.chdir("/");
        }

        // Execute the command and do not return.
        os.execvp(options.command[0], options.command);
        return 1;
    } catch (Exception ex) {
        io.writeAll(2, ex.msg ~ "\n");
        return 1;
    }
}
