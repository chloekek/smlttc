#!/usr/bin/env bash
set -efuo pipefail

# TODO: Clean up this folder if it already exists.
container=state/sitrep/container

# Create mount points.
mkdir --parents "$container"/{dev,proc,nix/store,build,state}

# Create /bin/sh and /usr/bin/env.
mkdir --parents "$container"/{bin,/usr/bin}
ln --symbolic "$(command which sh)"  "$container/bin/sh"
ln --symbolic "$(command which env)" "$container/usr/bin/env"

# initdb and postgres need some /etc files.
mkdir --parents "$container/etc"
cp /etc/{hosts,passwd} "$container/etc"

# Create runit configuration.
mkdir --parents "$container"/etc/runit
printf '#!/usr/bin/env bash\nexec runsvdir /etc/service\n' \
    > "$container/etc/runit/2"
chmod +x "$container/etc/runit/2"

# Install runit services.
mkdir --parents "$container"/etc/service
ln --symbolic /@SITREP_RECEIVE_SERVICE@ "$container/etc/service/sitrep-receive"
ln --symbolic /@SITREP_DATABASE_SERVICE@ "$container/etc/service/sitrep-database"

# Sqitch needs the time zone set in the TZ variable.
TZ=$(date +%Z)
export TZ

# Run runit and services in a container.
# Allow stopping the container with a signal.
trap 'pkill --exact --signal KILL runit' \
     SIGINT SIGTERM EXIT
@LITECONT@/litecont                                     \
    --bind-mount "/dev:$container/dev"                  \
    --bind-mount "/proc:$container/proc"                \
    --bind-mount "/nix/store:$container/nix/store"      \
    --bind-mount "/usr/bin:$container/usr/bin"          \
    --bind-mount "build:$container/build"               \
    --bind-mount "state:$container/state"               \
    --chroot     "$container"                           \
    -- bash -c "set -efuo pipefail && exec runit &"     \
    &
sleep infinity
