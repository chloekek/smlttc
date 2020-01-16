{ pkgs ? import ./nix/pkgs.nix {} }:
let
    perl = pkgs.perl.withPackages perlPackages;
    perlPackages = p: [ p.FileSlurp p.FileWhich p.IPCSystemSimple ];
in
    [
        perl
        pkgs.bash
        pkgs.hivemind
        pkgs.ldc
        pkgs.socat
    ]
