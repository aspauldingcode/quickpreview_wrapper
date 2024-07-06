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
  ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
    gnome.sushi
  ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
    darwin.apple_sdk.frameworks.Cocoa
    darwin.apple_sdk.frameworks.Quartz
    darwin.libiconv
  ];

  RUST_SRC_PATH = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

  shellHook = ''
    echo -e "\n\033[1;35m 🧹 Cleaning up previous build artifacts...\033[0m"
    cargo clean
    echo -e "\033[1;32m ✨ Workspace cleaned successfully!\033[0m\n"
    export LD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath ([
      pkgs.xorg.libX11
      pkgs.xorg.libXi
      pkgs.xorg.libXtst
      pkgs.xorg.libXfixes
      pkgs.xorg.libXrandr
    ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
      pkgs.gnome.sushi
    ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.libiconv
    ])}:$LD_LIBRARY_PATH"
    export DYLD_LIBRARY_PATH="${pkgs.lib.makeLibraryPath ([
      pkgs.darwin.libiconv
    ])}:$DYLD_LIBRARY_PATH"
    echo -e "\n\033[1;36m╔════════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║\033[0m       \033[1;33m🚀 Quick Start Guide 🚀\033[0m          \033[1;36m║\033[0m"
    echo -e "\033[1;36m╚════════════════════════════════════════╝\033[0m\n"
    echo -e "\033[1;32m 📦 To compile:\033[0m"
    echo -e "   \033[1;37mcargo build --release\033[0m\n"
    echo -e "\033[1;32m 🎬 To run:\033[0m"
    echo -e "   \033[1;37m./target/release/quickpreview_wrapper [-f] <file_path1> [file_path2] ...\033[0m\n"
    echo -e "\033[1;35m 💡 Tip:\033[0m Use \033[1;37m-f\033[0m flag for fullscreen mode!\n"
  '';
}
