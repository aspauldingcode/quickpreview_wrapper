{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "quickpreview_wrapper";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = with pkgs; [ pkg-config ];
  buildInputs = with pkgs; [ xorg.libX11 ];

  meta = with pkgs.lib; {
    description = "A wrapper for quickpreview tools";
    homepage = "https://github.com/yourusername/quickpreview_wrapper";
    license = licenses.mit;
    maintainers = [ maintainers.yourgithubusername ];
  };
}
