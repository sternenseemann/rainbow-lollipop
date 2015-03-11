with import <nixpkgs/lib>;

let
  rainbowLollipop = pkgs: with pkgs; stdenv.mkDerivation rec {
    name = "rainbow-lollipop-${version}";
    version = "0.0.1";
    src = ./.;

    buildInputs = [
      cmake vala_0_26 zeromq2 pkgconfig glib gtk3 clutter_gtk webkitgtk
      gnome3.libgee sqlite
    ] ++ optionals (!(stdenv ? cross)) [
      udev xorg.libpthreadstubs xorg.libXdmcp xorg.libxshmfence libxkbcommon
    ];
  };

  supportedSystems = [
    "i686-linux" "x86_64-linux" "i686-w64-mingw32" "x86_64-w64-mingw32"
  ];

  getSysAttrs = system: if hasSuffix "-w64-mingw32" system then {
    crossSystem = let
      is64 = hasPrefix "x86_64" system;
    in {
      config = system;
      arch = if is64 then "x86_64" else "x86";
      libc = "msvcrt";
      platform = {};
      openssl.system = "mingw${optionalString is64 "64"}";
    };
  } else {
    inherit system;
  };

  withSystem = system: let
    sysAttrs = getSysAttrs system;
    pkgs = import <nixpkgs> sysAttrs;
    result = rainbowLollipop pkgs;
  in if sysAttrs ? crossSystem then result.crossDrv else result;

in {
  build = genAttrs supportedSystems withSystem;
}
