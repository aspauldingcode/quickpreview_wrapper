@echo off
setlocal enabledelayedexpansion

echo Installing MSVC Build Tools...
winget install --id Microsoft.VisualStudio.2022.BuildTools ^
  --silent --accept-package-agreements --accept-source-agreements ^
  --override "--wait --quiet ^
  --add Microsoft.VisualStudio.Workload.VCTools ^
  --add Microsoft.VisualStudio.Workload.MSBuildTools ^
  --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 ^
  --add Microsoft.VisualStudio.Component.Windows11SDK.22621 ^
  --add Microsoft.VisualStudio.Component.VC.CMake.Project"

echo.

echo Installing QuickLook from GitHub...
winget install --id QL-Win.QuickLook --exact --source winget --accept-package-agreements

echo.

echo Checking for Rust...
where rustc >nul 2>nul
if %errorlevel% neq 0 (
    echo Rust not found. Installing Rust via rustup...
    curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs -o rustup-init.exe
    rustup-init.exe -y
    del rustup-init.exe
    echo Rust installed.
) else (
    echo Rust is already installed. Skipping.
)

echo.

echo All dependencies installed successfully!
pause
