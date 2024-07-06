{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "quickpreview_wrapper";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = with pkgs; [ pkg-config ]
    ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
      pkgs.darwin.apple_sdk.frameworks.Cocoa
      pkgs.darwin.apple_sdk.frameworks.Quartz
    ];

  buildInputs = with pkgs; [ ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ xorg.libX11 ];

  NIX_LDFLAGS = pkgs.lib.optionalString pkgs.stdenv.isDarwin
    "-framework Cocoa -framework Quartz";

  meta = with pkgs.lib; {
    description = "A wrapper for quickpreview tools";
    homepage = "https://github.com/yourusername/quickpreview_wrapper";
    license = licenses.mit;
    maintainers = [ maintainers.yourgithubusername ];
  };
}
