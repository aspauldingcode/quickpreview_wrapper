@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Setting up MSVC for Rust on Windows
echo ============================================

:: Save current working directory
set "PROJECT_DIR=%CD%"

:: Install Visual Studio Build Tools via winget (optional step)
echo Installing Visual Studio Build Tools with required components...
winget install --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project"

if %errorLevel% neq 0 (
    echo Warning: Build Tools installation may have failed or already exists.
    echo Please ensure required components are installed manually if needed.
)

:: Detect Visual Studio Build Tools path
set "VS_PATH="
for %%e in (BuildTools Enterprise Professional Community) do (
    for %%y in (2022 2019) do (
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e"
            goto :found_vs
        )
        if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VS_PATH=C:\Program Files\Microsoft Visual Studio\%%y\%%e"
            goto :found_vs
        )
    )
)

echo Error: Visual Studio Build Tools not found.
echo Install Build Tools 2022 from:
echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
exit /b 1

:found_vs
echo Found MSVC tools at: %VS_PATH%

:: Detect host architecture
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "HOST_ARCH=x64"
) else if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "HOST_ARCH=arm64"
) else (
    set "HOST_ARCH=x86"
)
echo Host architecture: %HOST_ARCH%

:: Build path to vcvarsall.bat
set "VCVARSALL=%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat"

:: Confirm existence of vcvarsall.bat
if not exist "%VCVARSALL%" (
    echo Error: Could not find vcvarsall.bat at expected location:
    echo   %VCVARSALL%
    exit /b 1
)

:: Open new Developer Command Prompt window with environment initialized
echo.
echo ============================================
echo Launching MSVC Developer Shell
echo ============================================
echo Project directory: %PROJECT_DIR%
echo Using vcvarsall.bat: %VCVARSALL%
echo.

start "MSVC Dev Shell" cmd /k ""%VCVARSALL%" %HOST_ARCH% && cd /d "%PROJECT_DIR%" && echo Ready! && prompt MSVC$G"

echo.
echo ✅ Done! A new terminal has opened with MSVC environment configured.
echo You can now build C++ or Rust projects using MSVC.
