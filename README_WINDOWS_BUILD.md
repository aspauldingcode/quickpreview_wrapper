# Windows Build Instructions

This project now includes enhanced Windows build support that automatically detects the MSVC toolchain and Windows SDK.

## Prerequisites

You need to install Microsoft Visual Studio Build Tools or Visual Studio with C++ support:

### Option 1: Visual Studio Build Tools (Recommended)
1. Download from: https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
2. Run the installer and select:
   - **C++ build tools** workload
   - **MSVC v143 - VS 2022 C++ x64/x86 build tools**
   - **Windows 10/11 SDK** (latest version) - **CRITICAL for kernel32.lib**

### Option 2: Full Visual Studio
1. Install Visual Studio Community/Professional/Enterprise
2. Make sure to include the **Desktop development with C++** workload
3. Ensure **Windows 10/11 SDK** is selected

## Building

Once the build tools are installed, you can build the project normally:

```bash
cargo build --release
```

## Troubleshooting

### Error: "cannot open input file 'kernel32.lib'"

This error occurs when the Windows SDK is missing or not properly configured. The error message:
```
LINK : fatal error LNK1181: cannot open input file 'kernel32.lib'
```

**Solution**: The build script now automatically:
1. **Detects Windows SDK installation** and version
2. **Sets up LIB environment variable** with correct paths for your target architecture
3. **Configures both UM and UCRT library paths** needed for system libraries

### Error: "link.exe not found"

If you encounter this error, the build script will now:

1. **Automatically search for MSVC toolchain** using multiple methods:
   - Uses `vswhere.exe` to find Visual Studio installations
   - Checks `VCINSTALLDIR` environment variable
   - Searches for `link.exe` in PATH
   - **Now supports multiple host architectures** (x64, x86, arm64)

2. **Provide detailed warnings** about what was found or missing

3. **Set up the environment** automatically for the cc crate

### Error: "windows_aarch64_msvc could not compile due to linker not found"

This error occurs when Rust dependencies (like `winapi`, `libc`, `getrandom`) can't find the MSVC linker. The enhanced build script now:

- Sets up the MSVC environment **before** any compilation starts
- **Automatically detects your target architecture** (x64, x86, arm64)
- **Configures library paths for the correct architecture**
- Provides detailed diagnostics about what's missing
- Gives specific installation guidance

### Manual Environment Setup

If automatic detection fails, you can manually set up the environment:

1. Open "Developer Command Prompt for VS 2022" from Start Menu
2. Run your cargo build command from there

### Verbose Build Output

For debugging build issues, use:

```bash
set CARGO_BUILD_VERBOSE=1
cargo build --release
```

This will show detailed information about:
- MSVC toolchain detection
- Windows SDK detection and version
- Library paths being set for your architecture
- Compiler and linker paths
- Build flags being used

### Common Issues and Solutions

1. **"vswhere.exe not found"**
   - Visual Studio or Build Tools are not installed
   - Install from the official Microsoft website

2. **"Visual Studio found but VC directory missing"**
   - Visual Studio is installed but without C++ support
   - Run the Visual Studio Installer and add the "Desktop development with C++" workload

3. **"VC directory found, but MSVC tools may be missing"**
   - C++ workload is installed but specific build tools are missing
   - Ensure "MSVC v143 - VS 2022 C++ x64/x86 build tools" is selected in the installer

4. **"Windows SDK not found" or "kernel32.lib not found"**
   - Windows SDK is missing or incomplete
   - In Visual Studio Installer, ensure "Windows 10/11 SDK (latest version)" is selected
   - This is **required** for system libraries like kernel32.lib, user32.lib, etc.

5. **Architecture mismatch issues**
   - The script now automatically detects your target architecture
   - Supports x64, x86, and arm64 builds
   - Sets up the correct library paths for each architecture

6. **Multiple Visual Studio versions**: The script prioritizes the latest installation

### Quick Fix

As a workaround, you can always run cargo build from the "Developer Command Prompt for VS 2022" which automatically sets up the correct environment.

### Environment Variables

The build script may set these environment variables automatically:
- `PATH` - Updated to include MSVC tools directory
- `VCINSTALLDIR` - Set to Visual Studio installation directory
- `LIB` - Set to include Windows SDK library paths for your target architecture

## Build Script Details

The enhanced build script (`build.rs`) now includes:
- MSVC toolchain auto-detection (similar to cc-rs registry.rs)
- **Windows SDK detection and configuration**
- **Multi-architecture support** (x64, x86, arm64)
- **Automatic LIB path setup** for system libraries
- Proper environment setup for all dependencies
- Detailed error reporting and diagnostics
- Support for multiple Visual Studio versions
- Early environment setup to help dependency compilation

## Architecture Support

The build script automatically detects and configures for:
- **x86_64** → uses x64 libraries
- **x86** → uses x86 libraries  
- **aarch64** → uses arm64 libraries

Library paths are automatically set for both:
- **UM libraries** (user-mode libraries like kernel32.lib, user32.lib)
- **UCRT libraries** (Universal C Runtime)