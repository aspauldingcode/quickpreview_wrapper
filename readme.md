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
  - **Visual Studio Build Tools** (Required for linking): 
    ```bash
    winget install Microsoft.VisualStudio.2022.BuildTools --override "--add Microsoft.VisualStudio.Workload.VCTools --includeRecommended --quiet"
    ```
  - **Configure Rust toolchain** (choose based on your Windows architecture):
    
    **For x64 Windows:**
    ```bash
    rustup toolchain install stable-x86_64-pc-windows-msvc
    rustup default stable-x86_64-pc-windows-msvc
    ```
    
    **For ARM64 Windows:**
    ```bash
    rustup toolchain install stable-aarch64-pc-windows-msvc
    rustup default stable-aarch64-pc-windows-msvc
    ```
    
    **Check your architecture:**
    ```powershell
    echo $env:PROCESSOR_ARCHITECTURE
    ```
    
  - **If you get "link.exe not found" error**:
    1. **Find your link.exe path** (architecture-specific):
       ```bash
       where.exe link
       ```
       Common paths:
       - **x64**: `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\<version>\bin\Hostx64\x64\`
       - **ARM64**: `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\<version>\bin\Hostarm64\arm64\`
    
    2. **Add to PATH** (choose one method):
       
       **Method 1 - GUI (Recommended):**
       - Press `Win + R`, type `sysdm.cpl`, press Enter
       - Click "Environment Variables"
       - Under "System Variables", select "Path" and click "Edit"
       - Click "New" and add your linker path (e.g., `C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.38.33135\bin\Hostarm64\arm64\`)
       - Click OK on all dialogs
       
       **Method 2 - PowerShell (Run as Administrator):**
       ```powershell
       # Get current PATH
       $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
       
       # Add your linker path (replace with your actual path)
       $newPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.38.33135\bin\Hostarm64\arm64"
       
       # Set new PATH
       [Environment]::SetEnvironmentVariable("PATH", $newPath + ";" + $currentPath, "Machine")
       ```
       
       **Method 3 - Command Prompt (Run as Administrator):**
       ```cmd
       setx PATH "%PATH%;C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.38.33135\bin\Hostarm64\arm64" /M
       ```
    
    3. **Restart your terminal completely** and verify:
       ```bash
       link /?
       ```
    
    4. **Alternative**: Use "Developer Command Prompt for VS 2022" or "Developer PowerShell for VS 2022" which have the PATH pre-configured
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
