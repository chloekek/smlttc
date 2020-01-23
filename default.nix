{ pkgs ? import ./nix/pkgs.nix {} }:
let
    postgresql = pkgs.postgresql_12;

    perl = pkgs.perl.withPackages perlPackages;
    perlPackages = p: [ p.FileSlurp p.FileWhich p.IPCSystemSimple ];

    pkg-config = pkgs.pkg-configWithPackages pkg-configPackages;
    pkg-configPackages = [ pkgs.libsodium.dev postgresql ];
in
    [
        perl
        pkg-config
        pkgs.bash
        pkgs.cargo
        pkgs.gcc
        pkgs.hivemind
        pkgs.ldc
        pkgs.shellcheck
        pkgs.socat
        postgresql
    ]
