{ pkgs ? import ./nix/pkgs.nix {} }:
let
    perl = pkgs.perl.withPackages perlPackages;
    perlPackages = p: [ p.FileSlurp p.FileWhich p.IPCSystemSimple ];

    pkg-config = pkgs.pkg-configWithPackages pkg-configPackages;
    pkg-configPackages = [ pkgs.libsodium.dev ];
in
    [
        perl
        pkgs.bash
        pkgs.hivemind
        pkgs.ldc
        pkgs.socat
        pkg-config
    ]
