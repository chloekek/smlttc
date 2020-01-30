{stdenvNoCC, coreutils, glibcLocales, makeWrapper}:
stdenvNoCC.mkDerivation {
    name = "getLocaleArchive";
    buildInputs = [makeWrapper];
    phases = ["installPhase"];
    installPhase = ''
        mkdir --parents $out/bin
        makeWrapper ${coreutils}/bin/echo $out/bin/getLocaleArchive \
            --add-flags ${glibcLocales}/lib/locale/locale-archive
    '';
}
