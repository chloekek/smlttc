{stdenvNoCC, docbook-xsl-ns, libxslt, perl}:
stdenvNoCC.mkDerivation {
    name = "docbook2html";
    phases = ["installPhase"];
    installPhase = ''
        mkdir --parents $out/bin
        cat <<'EOF' > $out/bin/docbook2html
        #!${perl}/bin/perl
        use v5.12;
        use autodie;
        use warnings;

        my @xsltprocFlags;
        for (;;) {
            if (@ARGV == 0) { last }
            if ($ARGV[0] eq '--') { shift; last }
            push(@xsltprocFlags, shift(@ARGV));
        }

        exec(
            '${libxslt}/bin/xsltproc',
            @xsltprocFlags,
            '${docbook-xsl-ns}/xml/xsl/docbook/html/chunk.xsl',
            @ARGV,
        );
        EOF
        chmod +x $out/bin/docbook2html
    '';
}
