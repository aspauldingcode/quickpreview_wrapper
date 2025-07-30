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
  - Rust: Install via `winget install --id Rustlang.Rustup -e`
  - **Visual Studio Build Tools** (Required for linking): 
    - Install via: `winget install --id Microsoft.VisualStudio.2022.BuildTools -e`
    - **Important**: During installation, make sure to select "C++ build tools" workload
    - Alternative: Install Visual Studio Community and select "Desktop development with C++" workload
  - After installing Rust and Build Tools, run:
    ```
    rustup toolchain install stable-msvc
    rustup default stable-msvc
    ```
  - **Troubleshooting**: If you still get "link.exe not found" error:
    - Restart your terminal/PowerShell after installing Build Tools
    - Run the build from "Developer Command Prompt for VS 2022" or "Developer PowerShell for VS 2022"
    - Verify installation: `where link.exe` should show the linker path

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
   cargo run -- [-f] <file_path1> [file_path2] ...
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
