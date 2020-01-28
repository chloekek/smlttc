let
    tarball = fetchTarball {
        url = "https://github.com/chloekek/snowflake/archive/6d6bcf380f863386062ff18ae0112bc3885b404e.tar.gz";
        sha256 = "1m4p791k1j5lhpkh9vl3yaksiyhb903r8ykb2a8g7abpczj5f7s4";
    };
in 
    import (tarball + "/snowflake.nix")