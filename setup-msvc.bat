@echo off
setlocal enabledelayedexpansion

echo ============================================
echo Setting up MSVC for Rust on Windows
echo ============================================

:: Check if running as administrator
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Running with administrator privileges...
) else (
    echo Warning: Not running as administrator. Some operations may fail.
    echo Consider running as administrator for full functionality.
    echo.
)

:: Install Visual Studio Build Tools with winget
echo Installing Visual Studio Build Tools...
winget install --id Microsoft.VisualStudio.2022.BuildTools --silent --accept-package-agreements --accept-source-agreements --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Workload.MSBuildTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.VC.Tools.ARM64 --add Microsoft.VisualStudio.Component.Windows11SDK.22621 --add Microsoft.VisualStudio.Component.VC.CMake.Project"

if %errorLevel% neq 0 (
    echo Failed to install Visual Studio Build Tools with winget. Continuing with existing installation...
    echo Note: If you encounter issues, you may need to install Visual Studio Build Tools manually from:
    echo https://visualstudio.microsoft.com/downloads/#build-tools-for-visual-studio-2022
    echo.
    echo Required components:
    echo - MSVC v143 - VS 2022 C++ x64/x86 build tools
    echo - MSVC v143 - VS 2022 C++ ARM64 build tools  
    echo - Windows 11 SDK
    echo - CMake tools for Visual Studio
    echo.
)

:: Detect Visual Studio installation paths
set "VS_YEAR=2022"
set "VS_EDITION="

:: Try different VS editions and years in order of preference
for %%e in (BuildTools Enterprise Professional Community) do (
    for %%y in (2022 2019) do (
        if exist "C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VS_PATH=C:\Program Files (x86)\Microsoft Visual Studio\%%y\%%e"
            set "VS_YEAR=%%y"
            set "VS_EDITION=%%e"
            goto :found_vs
        )
        if exist "C:\Program Files\Microsoft Visual Studio\%%y\%%e\VC\Auxiliary\Build\vcvarsall.bat" (
            set "VS_PATH=C:\Program Files\Microsoft Visual Studio\%%y\%%e"  
            set "VS_YEAR=%%y"
            set "VS_EDITION=%%e"
            goto :found_vs
        )
    )
)

echo Error: Could not find Visual Studio installation!
echo Please ensure Visual Studio Build Tools 2019 or 2022 is installed.
echo Exiting with error code 1.
exit /b 1

:found_vs
echo Found Visual Studio %VS_YEAR% %VS_EDITION% at: %VS_PATH%

:: Detect processor architecture
if "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
    set "HOST_ARCH=x64"
) else if "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "HOST_ARCH=arm64"
) else (
    set "HOST_ARCH=x86"
)

echo Host architecture: %HOST_ARCH%

:: Set up environment for x64 target
echo.
echo Setting up MSVC environment for x64 target...

:: First, try to call vcvarsall.bat and capture its output
echo Calling vcvarsall.bat...
call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" %HOST_ARCH%_x64

:: Add a small delay to ensure environment variables are set
:: Using a simple loop instead of ping/timeout for maximum compatibility
for /l %%i in (1,1,1000000) do rem

:: Check if we have the required tools in common locations
set "FOUND_CL=0"
set "FOUND_LINK=0"

:: Check for cl.exe in PATH first
where cl.exe >nul 2>&1
if %errorLevel% equ 0 (
    set "FOUND_CL=1"
    echo Found cl.exe in PATH
) else (
    echo cl.exe not found in PATH, checking common locations...
    
    :: Check common MSVC installation paths
    for /d %%v in ("%VS_PATH%\VC\Tools\MSVC\*") do (
        if exist "%%v\bin\Hostx64\x64\cl.exe" (
            set "FOUND_CL=1"
            set "CL_PATH=%%v\bin\Hostx64\x64"
            echo Found cl.exe at: %%v\bin\Hostx64\x64\cl.exe
            goto :found_cl
        )
        if exist "%%v\bin\HostARM64\x64\cl.exe" (
            set "FOUND_CL=1"
            set "CL_PATH=%%v\bin\HostARM64\x64"
            echo Found cl.exe at: %%v\bin\HostARM64\x64\cl.exe
            goto :found_cl
        )
        if exist "%%v\bin\Hostx86\x64\cl.exe" (
            set "FOUND_CL=1"
            set "CL_PATH=%%v\bin\Hostx86\x64"
            echo Found cl.exe at: %%v\bin\Hostx86\x64\cl.exe
            goto :found_cl
        )
    )
)

:found_cl
:: Check for link.exe
where link.exe >nul 2>&1
if %errorLevel% equ 0 (
    set "FOUND_LINK=1"
    echo Found link.exe in PATH
) else (
    echo link.exe not found in PATH, checking common locations...
    
    :: Check common MSVC installation paths for link.exe
    for /d %%v in ("%VS_PATH%\VC\Tools\MSVC\*") do (
        if exist "%%v\bin\Hostx64\x64\link.exe" (
            set "FOUND_LINK=1"
            set "LINK_PATH=%%v\bin\Hostx64\x64"
            echo Found link.exe at: %%v\bin\Hostx64\x64\link.exe
            goto :found_link
        )
        if exist "%%v\bin\HostARM64\x64\link.exe" (
            set "FOUND_LINK=1"
            set "LINK_PATH=%%v\bin\HostARM64\x64"
            echo Found link.exe at: %%v\bin\HostARM64\x64\link.exe
            goto :found_link
        )
        if exist "%%v\bin\Hostx86\x64\link.exe" (
            set "FOUND_LINK=1"
            set "LINK_PATH=%%v\bin\Hostx86\x64"
            echo Found link.exe at: %%v\bin\Hostx86\x64\link.exe
            goto :found_link
        )
    )
)

:found_link

:: Verify MSVC tools are available and add to PATH if needed
if %FOUND_CL% equ 0 (
    echo Error: cl.exe not found in PATH or common MSVC locations
    echo This usually means the MSVC compiler tools are not properly installed.
    echo.
    echo Debugging information:
    echo VS_PATH: %VS_PATH%
    echo HOST_ARCH: %HOST_ARCH%
    echo.
    echo Checking if MSVC directories exist:
    if exist "%VS_PATH%\VC\Tools\MSVC\" (
        echo MSVC Tools directory exists, listing versions:
        dir "%VS_PATH%\VC\Tools\MSVC\" /b
        echo.
        echo Checking for cl.exe in latest version:
        for /f %%i in ('dir "%VS_PATH%\VC\Tools\MSVC\" /b /o-n') do (
            echo Checking: %VS_PATH%\VC\Tools\MSVC\%%i\bin\HostARM64\x64\cl.exe
            if exist "%VS_PATH%\VC\Tools\MSVC\%%i\bin\HostARM64\x64\cl.exe" (
                echo Found cl.exe in %%i version!
            )
            goto :break_loop
        )
        :break_loop
    ) else (
        echo MSVC Tools directory does not exist at: %VS_PATH%\VC\Tools\MSVC\
    )
    echo.
    echo Please install Visual Studio Build Tools with C++ development tools.
    echo Exiting with error code 1.
    exit /b 1
) else (
    echo SUCCESS: cl.exe found and available
    :: Add MSVC tools to PATH if we found them in non-standard locations
    if defined CL_PATH (
        echo Adding MSVC tools to PATH: %CL_PATH%
        set "PATH=%CL_PATH%;%PATH%"
        :: Also set persistent PATH for future sessions
        for /f "tokens=2*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "CURRENT_USER_PATH=%%b"
        if not defined CURRENT_USER_PATH set "CURRENT_USER_PATH="
        echo %CURRENT_USER_PATH% | findstr /C:"%CL_PATH%" >nul
        if %errorLevel% neq 0 (
            echo Adding to user PATH permanently...
            setx PATH "%CL_PATH%;%CURRENT_USER_PATH%" >nul
        )
    )
)

if %FOUND_LINK% equ 0 (
    echo Error: link.exe not found in PATH or common MSVC locations  
    echo This usually means the MSVC linker tools are not properly installed.
    echo Please install Visual Studio Build Tools with C++ development tools.
    echo Exiting with error code 1.
    exit /b 1
) else (
    echo SUCCESS: link.exe found and available
)

echo MSVC compiler (cl.exe): 
if defined CL_PATH (
    echo Using cl.exe from: %CL_PATH%
    echo Compiler version check...
    "%CL_PATH%\cl.exe" >nul 2>&1 && echo Compiler is working || echo Compiler test failed
) else (
    echo Using cl.exe from PATH
    echo Compiler version check...
    cl.exe >nul 2>&1 && echo Compiler is working || echo Compiler test failed
)

echo.
echo MSVC linker (link.exe):
if defined LINK_PATH (
    echo Using link.exe from: %LINK_PATH%
    echo Linker version check...
    "%LINK_PATH%\link.exe" >nul 2>&1 && echo Linker is working || echo Linker test failed
) else (
    echo Using link.exe from PATH
    echo Linker version check...
    link.exe >nul 2>&1 && echo Linker is working || echo Linker test failed
)

:: Set up Rust toolchain for MSVC
echo.
echo Setting up Rust toolchain for MSVC...

:: Install Rust MSVC targets
rustup target add x86_64-pc-windows-msvc
if %errorLevel% neq 0 (
    echo Warning: Failed to add x86_64-pc-windows-msvc target. Make sure Rust is installed.
)

rustup target add aarch64-pc-windows-msvc  
if %errorLevel% neq 0 (
    echo Warning: Failed to add aarch64-pc-windows-msvc target. This is optional.
)

:: Set default target to MSVC
rustup default stable-x86_64-pc-windows-msvc
if %errorLevel% neq 0 (
    echo Warning: Failed to set default target to MSVC.
)

:: Create environment setup script for future use
echo.
echo Creating msvc-env.bat for future use...
(
echo @echo off
echo :: Auto-generated MSVC environment setup
echo call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" %HOST_ARCH%_x64
echo echo MSVC environment configured for x64 target
) > msvc-env.bat

:: Create PowerShell version as well
(
echo # Auto-generated MSVC environment setup for PowerShell
echo $vsPath = "%VS_PATH%"
echo $vcvarsPath = "$vsPath\VC\Auxiliary\Build\vcvarsall.bat"
echo if ^(Test-Path $vcvarsPath^) {
echo     cmd /c "`"$vcvarsPath`" %HOST_ARCH%_x64 && set" ^| ForEach-Object {
echo         if ^($_ -match "^(.+?)=(.*)$"^) {
echo             [Environment]::SetEnvironmentVariable^($matches[1], $matches[2]^)
echo         }
echo     }
echo     Write-Host "MSVC environment configured for x64 target"
echo } else {
echo     Write-Error "MSVC vcvarsall.bat not found at $vcvarsPath"
echo }
) > msvc-env.ps1

:: Set environment variables for cc-rs and other build tools
echo.
echo Setting environment variables for cc-rs...

:: Set MSVC-specific environment variables
if defined CL_PATH (
    set CC_x86_64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set CXX_x86_64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set AR_x86_64_pc_windows_msvc="%CL_PATH%\lib.exe"
    set LINKER_x86_64_pc_windows_msvc="%LINK_PATH%\link.exe"
    
    set CC_aarch64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set CXX_aarch64_pc_windows_msvc="%CL_PATH%\cl.exe"  
    set AR_aarch64_pc_windows_msvc="%CL_PATH%\lib.exe"
    set LINKER_aarch64_pc_windows_msvc="%LINK_PATH%\link.exe"
) else (
    set CC_x86_64_pc_windows_msvc=cl.exe
    set CXX_x86_64_pc_windows_msvc=cl.exe
    set AR_x86_64_pc_windows_msvc=lib.exe
    set LINKER_x86_64_pc_windows_msvc=link.exe

    set CC_aarch64_pc_windows_msvc=cl.exe
    set CXX_aarch64_pc_windows_msvc=cl.exe  
    set AR_aarch64_pc_windows_msvc=lib.exe
    set LINKER_aarch64_pc_windows_msvc=link.exe
)

:: Export environment variables to user environment (persistent)
echo Setting persistent environment variables...
if defined CL_PATH (
    setx CC_x86_64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul
    setx CXX_x86_64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul
    setx AR_x86_64_pc_windows_msvc "%CL_PATH%\lib.exe" >nul
    setx LINKER_x86_64_pc_windows_msvc "%LINK_PATH%\link.exe" >nul

    setx CC_aarch64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul
    setx CXX_aarch64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul
    setx AR_aarch64_pc_windows_msvc "%CL_PATH%\lib.exe" >nul  
    setx LINKER_aarch64_pc_windows_msvc "%LINK_PATH%\link.exe" >nul
) else (
    setx CC_x86_64_pc_windows_msvc "cl.exe" >nul
    setx CXX_x86_64_pc_windows_msvc "cl.exe" >nul
    setx AR_x86_64_pc_windows_msvc "lib.exe" >nul
    setx LINKER_x86_64_pc_windows_msvc "link.exe" >nul

    setx CC_aarch64_pc_windows_msvc "cl.exe" >nul
    setx CXX_aarch64_pc_windows_msvc "cl.exe" >nul
    setx AR_aarch64_pc_windows_msvc "lib.exe" >nul  
    setx LINKER_aarch64_pc_windows_msvc "link.exe" >nul
)

:: Test the setup by building the project
echo.
echo ============================================
echo Testing MSVC setup by building the project
echo ============================================

if exist "Cargo.toml" (
    echo Building project with MSVC...
    cargo build --target x86_64-pc-windows-msvc
    if %errorLevel% equ 0 (
        echo SUCCESS: Project built successfully with MSVC!
        echo.
        echo You can now build with: cargo build --target x86_64-pc-windows-msvc
        echo For ARM64: cargo build --target aarch64-pc-windows-msvc
    ) else (
        echo Build failed. Check the error messages above.
    )
) else (
    echo No Cargo.toml found in current directory.
    echo Navigate to your Rust project directory and run this script.
)

echo.
echo ============================================
echo MSVC Setup Complete!
echo ============================================
echo.
echo Environment files created:
echo - msvc-env.bat (for Command Prompt)
echo - msvc-env.ps1 (for PowerShell)
echo.
echo To use MSVC environment in new sessions:
echo - Command Prompt: call msvc-env.bat
echo - PowerShell: .\msvc-env.ps1
echo.
echo Rust targets configured:
echo - x86_64-pc-windows-msvc (primary)
echo - aarch64-pc-windows-msvc (ARM64)
echo.
echo Setup completed successfully!