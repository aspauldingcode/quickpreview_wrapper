# Windows MSVC Setup Guide

This guide explains how to set up and build the QuickPreview Wrapper project on Windows using the Microsoft Visual C++ (MSVC) toolchain.

## Prerequisites

- Windows 10 or Windows 11
- PowerShell or Command Prompt with Administrator privileges (recommended)
- Internet connection for downloading Visual Studio Build Tools

## Quick Setup

### Automated Setup

Run the provided batch script to automatically set up the MSVC environment:

```batch
# Run as Administrator (recommended)
setup-msvc.bat
```

This script will:
1. Install Visual Studio Build Tools 2022 via winget
2. Configure the MSVC environment
3. Set up Rust toolchain for MSVC targets
4. Create helper scripts for future use
5. Test the build to verify everything works

### Manual Setup (if automated setup fails)

1. **Install Visual Studio Build Tools**
   
   Download and install from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
   
   Required components:
   - MSVC v143 - VS 2022 C++ x64/x86 build tools
   - MSVC v143 - VS 2022 C++ ARM64 build tools
   - Windows 11 SDK (latest version)
   - CMake tools for Visual Studio

2. **Install Rust MSVC targets**
   ```batch
   rustup target add x86_64-pc-windows-msvc
   rustup target add aarch64-pc-windows-msvc
   rustup default stable-x86_64-pc-windows-msvc
   ```

3. **Set environment variables**
   ```batch
   setx CC_x86_64_pc_windows_msvc "cl.exe"
   setx CXX_x86_64_pc_windows_msvc "cl.exe"
   setx AR_x86_64_pc_windows_msvc "lib.exe" 
   setx LINKER_x86_64_pc_windows_msvc "link.exe"
   ```

## Building the Project

### Setting up MSVC environment

Before building, you need to set up the MSVC environment in your terminal session:

**Option 1: Use the generated helper script**
```batch
call msvc-env.bat
```

**Option 2: Manual setup**
```batch
# For Visual Studio 2022 Build Tools (adjust path if needed)
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64
```

**Option 3: PowerShell**
```powershell
.\msvc-env.ps1
```

### Building

**For x64 (most common):**
```batch
cargo build --target x86_64-pc-windows-msvc
cargo build --target x86_64-pc-windows-msvc --release
```

**For ARM64:**
```batch
cargo build --target aarch64-pc-windows-msvc
cargo build --target aarch64-pc-windows-msvc --release
```

### Running

After building, you can run the executable:

```batch
# Debug build
.\target\x86_64-pc-windows-msvc\debug\quickpreview_wrapper.exe [options] <file_path>

# Release build  
.\target\x86_64-pc-windows-msvc\release\quickpreview_wrapper.exe [options] <file_path>
```

## Usage

### Command Line Interface

```batch
quickpreview_wrapper.exe [-f] <file_path1> [file_path2] ...
```

**Options:**
- `-f`: Enable fullscreen mode
- `file_path`: Path to the file(s) you want to preview

**Examples:**
```batch
# Preview a single image
quickpreview_wrapper.exe "C:\Users\YourName\Pictures\photo.jpg"

# Preview multiple files
quickpreview_wrapper.exe "image1.png" "document.pdf" "video.mp4"

# Preview in fullscreen mode
quickpreview_wrapper.exe -f "presentation.pptx"
```

## Architecture Support

This project supports both x86_64 and ARM64 Windows architectures:

- **x86_64 (x64)**: Standard Intel/AMD 64-bit processors
- **ARM64**: ARM-based Windows devices (Surface Pro X, etc.)

The setup script automatically detects your host architecture and configures the appropriate cross-compilation setup.

## Troubleshooting

### Common Issues

**1. "cl.exe not found" error**
- Ensure Visual Studio Build Tools are installed
- Run the MSVC environment setup before building
- Check that the vcvarsall.bat path is correct

**2. Link errors**
- Verify Windows SDK is installed
- Make sure you're using the correct target (x86_64-pc-windows-msvc, not gnu)
- Check that all required system libraries are available

**3. Build Tools installation fails**
- Try running the setup script as Administrator
- Install manually from the Visual Studio website
- Check your internet connection

**4. Rust target not found**
- Ensure Rust is installed and up to date: `rustup update`
- Manually add targets: `rustup target add x86_64-pc-windows-msvc`

### Environment Reset

If you need to reset your environment:

```batch
# Remove old targets
rustup target remove x86_64-pc-windows-gnu
rustup target remove aarch64-pc-windows-gnu

# Add MSVC targets
rustup target add x86_64-pc-windows-msvc
rustup target add aarch64-pc-windows-msvc

# Set default
rustup default stable-x86_64-pc-windows-msvc
```

### Debugging Build Issues

Enable verbose output for more information:

```batch
cargo build --target x86_64-pc-windows-msvc --verbose
```

Check environment variables:
```batch
echo %CC_x86_64_pc_windows_msvc%
echo %CXX_x86_64_pc_windows_msvc%
where cl.exe
where link.exe
```

## Project Structure

```
quickpreview_wrapper/
├── setup-msvc.bat              # MSVC setup script
├── msvc-env.bat               # Generated MSVC environment script
├── msvc-env.ps1               # Generated PowerShell environment script
├── windows/
│   └── openfile_windows.c     # Windows-specific implementation
├── macos/
│   └── macos.m               # macOS-specific implementation
├── src/
│   ├── main.rs               # Rust main entry point
│   ├── windows.rs            # Windows Rust interface
│   ├── macos.rs              # macOS Rust interface
│   └── linux.rs              # Linux Rust interface
├── build.rs                   # Build script
├── Cargo.toml                # Project configuration
├── main.c                    # C main entry point
├── openfile.c                # Common C code
└── openfile.h                # C header file
```

## Advanced Configuration

### Custom Build Tools Paths

If you have Visual Studio installed in a non-standard location, update the paths in the setup script or manually set environment variables:

```batch
set "VS_PATH=C:\Custom\Path\To\Visual Studio\2022\Community"
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" x64
```

### Cross-compilation

To build for ARM64 from an x64 host:

```batch
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x64_arm64
cargo build --target aarch64-pc-windows-msvc
```

## Support

For issues specific to the MSVC setup:
1. Check that Visual Studio Build Tools 2019 or 2022 are properly installed
2. Verify the vcvarsall.bat path matches your installation
3. Ensure Windows SDK is installed and accessible
4. Try rebuilding after cleaning: `cargo clean`

For general project issues, refer to the main README.md file. 