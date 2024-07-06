{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    rustc
    cargo
    pkg-config
    xorg.libX11
    xorg.libXi
    xorg.libXtst
    xorg.libXfixes
    xorg.libXrandr
    xorg.xinput
    gnome.sushi
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath [
      pkgs.xorg.libX11
      pkgs.xorg.libXi
      pkgs.xorg.libXtst
      pkgs.xorg.libXfixes
      pkgs.xorg.libXrandr
      pkgs.gnome.sushi
    ]}:$LD_LIBRARY_PATH"
  '';
}
