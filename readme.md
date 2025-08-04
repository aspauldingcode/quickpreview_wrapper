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
  - **Rust**: Install via `winget install --id Rustlang.Rustup -e`
  - **GNU Toolchain** (Recommended - easier setup than MSVC):
    
    **Step 1: Install MSYS2 (provides MinGW-w64/GCC)**
    ```powershell
    # Install MSYS2 silently using winget
    winget install MSYS2.MSYS2 --silent
    ```
    
    **Step 2: Install MinGW-w64 toolchain**
    Stay in your current PowerShell and run:
    ```powershell
    # Update package database
    C:\msys64\usr\bin\pacman.exe -Syu --noconfirm
    
    # Install MinGW-w64 toolchain (includes GCC, G++, etc.)
    C:\msys64\usr\bin\pacman.exe -S mingw-w64-ucrt-x86_64-toolchain --noconfirm
    ```
    
    **Step 3: Add to PATH**
    Add `C:\msys64\ucrt64\bin` to your Windows PATH environment variable
    
    **Step 4: Install Rust GNU toolchain**
    
    **For x64 Windows:**
    ```powershell
    # Install GNU toolchain for Windows x64
    rustup toolchain install stable-x86_64-pc-windows-gnu
    rustup default stable-x86_64-pc-windows-gnu
    ```
    
    **For ARM64 Windows:**
    ```powershell
    # Install GNU toolchain for Windows ARM64  
    rustup toolchain install stable-aarch64-pc-windows-gnu
    rustup default stable-aarch64-pc-windows-gnu
    
    # Note: You'll also need ARM64 MinGW-w64 toolchain
    # In MSYS2 UCRT64 terminal:
    # pacman -S mingw-w64-ucrt-aarch64-toolchain
    ```
    
  - **Check your architecture** (to choose the right toolchain):
    ```powershell
    echo $env:PROCESSOR_ARCHITECTURE
    ```

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
