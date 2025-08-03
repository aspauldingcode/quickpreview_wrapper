# PowerShell script to set up MSVC environment
# Run this before cargo build to ensure all dependencies can find the MSVC toolchain

Write-Host "Setting up MSVC environment..." -ForegroundColor Green

# Find Visual Studio installation
$vsPath = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath 2>$null

if (-not $vsPath) {
    $vsPath = & "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -property installationPath 2>$null
}

if ($vsPath) {
    Write-Host "Found Visual Studio at: $vsPath" -ForegroundColor Yellow
    
    # Set up environment using vcvars64.bat
    # Detect architecture from environment
$target_arch = $env:PROCESSOR_ARCHITECTURE

if ($target_arch -eq "AMD64") {
    $vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvars64.bat"
} elseif ($target_arch -eq "x86") {
    $vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvars32.bat"
} else {
    Write-Host "Unsupported architecture: $target_arch"
    exit 1
}
    
    if (Test-Path $vcvarsPath) {
        Write-Host "Setting up environment variables..." -ForegroundColor Yellow
        
        # Run vcvars64.bat and capture environment variables
        cmd /c "`"$vcvarsPath`" -arch=$target_arch && set" | ForEach-Object {
            if ($_ -match "^([^=]+)=(.*)$") {
                $name = $matches[1]
                $value = $matches[2]
                
                # Set the environment variable for this PowerShell session
                [Environment]::SetEnvironmentVariable($name, $value, "Process")
                
                # Also set for any child processes
                $env:$name = $value
            }
        }
        
        Write-Host "MSVC environment configured successfully!" -ForegroundColor Green
        Write-Host "You can now run: cargo build --release" -ForegroundColor Cyan
    } else {
        Write-Host "Error: vcvars64.bat not found at $vcvarsPath" -ForegroundColor Red
        Write-Host "Please ensure Visual Studio C++ build tools are installed." -ForegroundColor Red
    }
} else {
    Write-Host "Error: Visual Studio not found!" -ForegroundColor Red
    Write-Host "Please install Visual Studio 2017 or later with C++ build tools." -ForegroundColor Red
    Write-Host "Download from: https://visualstudio.microsoft.com/downloads/" -ForegroundColor Yellow
}