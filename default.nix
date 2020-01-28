{ pkgs ? import ./nix/pkgs.nix {} }:
let
    postgresql = pkgs.postgresql_12;

    perl = pkgs.perl.withPackages perlPackages;
    perlPackages = p: [ p.FileSlurp p.FileWhich p.IPCSystemSimple ];

    pkg-config = pkgs.pkg-configWithPackages pkg-configPackages;
    pkg-configPackages = [ pkgs.libsodium.dev postgresql ];
in
    [
        pkg-config
        pkgs.bash
        pkgs.cargo
        pkgs.coreutils
        pkgs.docbook2html
        pkgs.findutils
        pkgs.gcc
        pkgs.gnused
        pkgs.hivemind
        pkgs.ldc
        pkgs.shellcheck
        pkgs.snowflake
        pkgs.socat
        pkgs.sqitchPg
        pkgs.which
        postgresql
    ]
