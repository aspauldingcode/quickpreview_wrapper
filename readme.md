# Quickpreview Wrapper

## Description
A universal CLI tool for quickpreview functionality on macOS, Linux, and Windows, implemented in Rust with Nix for dependency management.

## Key Features
- Cross-platform support (macOS, Linux, Windows)
- Fullscreen mode (with -f cli flag)
- Multi-file navigation with arrow keys (linux)

## Dependencies
- macOS: Native Quicklook
- Linux: Sushi (GNOME)
- Windows: QuickLook (install via `winget install --id=QL-Win.QuickLook --exact` or from https://github.com/QL-Win/QuickLook)

## Quick Start
1. Install Nix: https://nixos.org/download.html
2. Clone and build:
   ```sh
   git clone <repository-url>
   cd quickpreview_wrapper
   nix-shell
   cargo build --release
   ```
3. Run:
   ```sh
   ./target/release/quickpreview_wrapper [-f] <file_path1> [file_path2] ...
   ```

## Usage
- Right/Left arrows: Navigate files
- Esc: Exit preview

## Development
Enter dev environment: `nix-shell`

## Building with Nix
Run: `nix-build`

## License
GNU General Public License v3.0

Note: This license applies only to the Quickpreview Wrapper, not to the underlying preview tools it interacts with.
