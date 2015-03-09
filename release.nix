let 
    pkgs_linux = import <nixpkgs> {};
    pkgs_windows = import <nixpkgs> {
        crossSystem = {
            config = "x86_64-w64-mingw32";
            arch = "x86_64";
            libc = "msvcrt";
            platform = {};
            openssl.system = "mingw64";
        };

    };
    system = "x86_64-linux";
    jobs = rec {
        linux_amd64 = 
            with pkgs_linux;
            stdenv.mkDerivation {
                name = "rainbow-lollipop-tarball";
                version = "0.0.1";
                src = ./.;
                
                buildInputs = [cmake vala_0_26 zeromq2 pkgconfig glib gtk3 clutter_gtk webkitgtk
                               gnome3.libgee sqlite udev xorg.libpthreadstubs xorg.libXdmcp
                               xorg.libxshmfence libxkbcommon];
            };
        windows_64bit =
            with pkgs_windows;
            (stdenv.mkDerivation {
                name = "rainbow-lollipop-windows";
                version = "0.0.1";
                src = ./.;
                
                buildInputs = [cmake vala_0_26 zeromq2 pkgconfig glib gtk3 clutter_gtk webkitgtk
                               gnome3.libgee sqlite udev xorg.libpthreadstubs xorg.libXdmcp
                               xorg.libxshmfence libxkbcommon];
            }).crossDrv;
    };
in jobs
