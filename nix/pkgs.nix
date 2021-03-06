let
    tarball = fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/7d90e34e9f15fc668eba35f7609f99b6e73b14cc.tar.gz";
        sha256 = "1jsvjqd3yp30y12wvkb6k42mpk8gfgnr8y9j995fpasjg1jymy9f";
    };
    config = {
        packageOverrides = pkgs: {
            docbook2html = pkgs.callPackage ./docbook2html.nix {};
            pkg-configWithPackages =
                pkgs.callPackage ./pkg-configWithPackages.nix {};
            snowflake = pkgs.callPackage ./snowflake.nix {};
            getLocaleArchive = pkgs.callPackage ./getLocaleArchive.nix {};
        };
    };
in
    {}: import tarball {inherit config;}
