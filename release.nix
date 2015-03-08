let 
    pkgs = import <nixpkgs> {};
    jobs = rec {
        tarball = 
            with pkgs;
            releaseTools.sourceTarball {
                name = "rl-tarball";
                version = "0.0.1";
                src = rainbow-lollipop;
                
                buildInputs = [cmake vala_0_26 pkgconfig]
                
            }
    }
in jobs
