let 
    pkgs = import <nixpkgs> {};
    jobs = rec {
        tarball = 
            with pkgs;
            releaseTools.sourceTarball {
                name = "rl-tarball";
                version = "0.0.1";
                src = ./.;
                
                buildInputs = [cmake vala_0_26 zeromq2 pkgconfig glib gtk3 clutter_gtk webkitgtk
                               gnome3.libgee sqlite udev xorg.libpthreadstubs xorg.libXdmcp
                               xorg.libxshmfence libxkbcommon];
            };
    };
in jobs