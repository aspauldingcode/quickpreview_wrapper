# Windows Build Instructions

This project includes a custom build script that automatically detects and configures the MSVC toolchain and Windows SDK for compilation on Windows.

## Quick Fix for "link.exe not found" Error

If you encounter the error `linker 'link.exe' not found`, the fastest solution is to run the build from a **Developer Command Prompt**:

1. Open **Start Menu** and search for "Developer Command Prompt for VS"
2. Open the Developer Command Prompt (not regular Command Prompt)
3. Navigate to your project directory: `cd path\to\your\project`
4. Run: `cargo build --release`

This sets up all the necessary environment variables automatically.

## Alternative Solution: Set Environment Variables Globally

If you prefer to build from a regular terminal, you can set up the environment variables globally:

### Option 1: PowerShell Script (Recommended)
Create a PowerShell script to set up the environment:

```powershell
# setup-msvc.ps1
$vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
if ($vsPath) {
    $vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
    if (Test-Path $vcvarsPath) {
        cmd /c "`"$vcvarsPath`" && set" | ForEach-Object {
            if ($_ -match "^([^=]+)=(.*)$") {
                [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
            }
        }
        Write-Host "MSVC environment configured successfully"
    }
}
```

Run this script before building:
```powershell
.\setup-msvc.ps1
cargo build --release
```

### Option 2: Manual PATH Setup
Add the MSVC toolchain to your system PATH:
1. Find your Visual Studio installation (usually `C:\Program Files\Microsoft Visual Studio\2022\...`)
2. Add the toolchain path to your system PATH:
   - For x64: `VC\Tools\MSVC\14.xx.xxxxx\bin\Hostx64\x64\`
   - For ARM64: `VC\Tools\MSVC\14.xx.xxxxx\bin\Hostx64\arm64\`

## Automatic Detection Features

The build script automatically:
- Detects Visual Studio installations using `vswhere.exe`
- Locates MSVC toolchain for your target architecture
- Finds and configures Windows SDK paths
- Sets up proper library paths (`LIB` environment variable)
- Supports both x64 and ARM64 architectures

## Troubleshooting Common Issues

### Error: "windows_aarch64_msvc could not compile due to linker not found"

This error occurs when the MSVC linker (`link.exe`) cannot be found by dependency crates. The build script attempts to configure the environment, but dependencies compile in separate processes.

**Root Cause**: Cargo compiles dependencies in separate processes that don't inherit the environment variables set by our build script.

**Solutions (in order of preference)**:

1. **Use Developer Command Prompt** (Most Reliable)
   - Open "Developer Command Prompt for VS" from Start Menu
   - Navigate to project directory and run `cargo build --release`

2. **Set Environment Variables Before Running Cargo**
   ```powershell
   # PowerShell - run before cargo build
   $vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath
   $vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
   cmd /c "`"$vcvarsPath`" && set" | ForEach-Object {
       if ($_ -match "^([^=]+)=(.*)$") {
           [Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
       }
   }
   cargo build --release
   ```

3. **Manual PATH Configuration**
   - Add MSVC toolchain directory to your system's PATH environment variable
   - Restart your terminal/IDE after making PATH changes

### Error: "LNK1181: cannot open input file 'kernel32.lib'"

This error indicates that while `link.exe` is found, the Windows SDK libraries are not properly configured.

**Cause**: The Windows SDK provides essential system libraries like `kernel32.lib`, `user32.lib`, etc. The `LIB` environment variable must be set correctly.

**Solution**: Use the Developer Command Prompt or ensure the `LIB` environment variable includes:
- Windows SDK UM libraries: `C:\Program Files (x86)\Windows Kits\10\Lib\{version}\um\{arch}\`
- Windows SDK UCRT libraries: `C:\Program Files (x86)\Windows Kits\10\Lib\{version}\ucrt\{arch}\`
- MSVC runtime libraries: `{VS_PATH}\VC\Tools\MSVC\{version}\lib\{arch}\`

### Common Issues and Solutions

1. **"vswhere.exe not found"**
   - Install Visual Studio 2017 or later (Community edition is sufficient)
   - Ensure Visual Studio Installer includes the C++ build tools

2. **"Visual Studio found but VC directory missing"**
   - In Visual Studio Installer, modify your installation
   - Ensure "MSVC v143 - VS 2022 C++ x64/x86 build tools" is selected
   - For ARM64 development, also select "MSVC v143 - VS 2022 C++ ARM64 build tools"

3. **Build works in Developer Command Prompt but not regular terminal**
   - This is expected behavior due to how Cargo handles dependency compilation
   - The Developer Command Prompt is the recommended solution

4. **UTM/Virtual Machine Issues**
   - Ensure Visual Studio is properly installed in the VM
   - VM performance may be slower, but functionality should be the same
   - Consider using the Developer Command Prompt for most reliable results

## Requirements

- Visual Studio 2017 or later (Community edition works)
- Windows SDK (usually installed with Visual Studio)
- For ARM64 builds: ARM64 build tools component

## Architecture Support

The build script supports:
- x64 (Intel/AMD 64-bit)
- x86 (32-bit)
- ARM64 (Windows on ARM)

The correct toolchain and libraries are automatically selected based on your target architecture.

## Why cc-rs Detection Sometimes Fails

The `cc-rs` crate (used by many Rust dependencies) has known limitations:
- Relies on COM components that may not be properly registered on some systems
- Requires specific environment variables (`VCINSTALLDIR`) that aren't always set
- Has historical issues with standalone build tools vs. full Visual Studio installations
- Can have problems on ARM64 Windows systems

Using the Developer Command Prompt bypasses these issues by setting up the complete MSVC environment.