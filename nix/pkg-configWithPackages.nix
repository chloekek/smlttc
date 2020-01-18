{ lib, stdenvNoCC, makeWrapper, pkg-config }:
packages:
stdenvNoCC.mkDerivation {
    name = "pkg-configWithPackages";
    buildInputs = [ makeWrapper ];
    phases = [ "installPhase" ];
    installPhase = ''
        makeWrapperFlags=()
        for pkg in ${lib.concatMapStringsSep " " (p: "${p}") packages}; do
            makeWrapperFlags+=(--prefix PKG_CONFIG_PATH : "$pkg"/lib/pkgconfig)
        done

        mkdir --parents "$out"/bin
        makeWrapper ${pkg-config}/bin/pkg-config "$out"/bin/pkg-config \
            "''${makeWrapperFlags[@]}"
    '';
}
