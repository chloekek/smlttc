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
        pkgs.coreutils
        pkgs.docbook2html
        pkgs.findutils
        pkgs.getLocaleArchive
        pkgs.gnused
        pkgs.ldc
        pkgs.perl
        pkgs.procps
        pkgs.runit
        pkgs.shellcheck
        pkgs.snowflake
        pkgs.socat
        pkgs.sqitchPg
        pkgs.which
        postgresql
    ]
