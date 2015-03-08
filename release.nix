let 
    pkgs = import <nixpkgs> {};
    jobs = rec {
        tarball = 
            with pkgs;
            releaseTools.sourceTarball {
                name = "rl-tarball";
                version = "0.0.1";
                src = ./.;
                
                buildInputs = [cmake vala_0_26 pkgconfig];
            };
    };
in jobs
