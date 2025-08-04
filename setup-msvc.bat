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
        :: Also add LINK_PATH if it's different from CL_PATH
        if defined LINK_PATH (
            if not "%LINK_PATH%"=="%CL_PATH%" (
                echo Adding MSVC linker tools to PATH: %LINK_PATH%
                set "PATH=%LINK_PATH%;%PATH%"
            )
        )
        :: Set persistent PATH for future sessions (simplified approach)
        echo Adding to user PATH permanently...
        setx PATH "%CL_PATH%;%PATH%" >nul 2>&1
        if defined LINK_PATH (
            if not "%LINK_PATH%"=="%CL_PATH%" (
                setx PATH "%LINK_PATH%;%PATH%" >nul 2>&1
            )
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
    :: Add LINK_PATH to PATH if it's defined and not already added
    if defined LINK_PATH (
        if not defined CL_PATH (
            echo Adding MSVC linker tools to PATH: %LINK_PATH%
            set "PATH=%LINK_PATH%;%PATH%"
            :: Set persistent PATH for future sessions
            echo Adding linker to user PATH permanently...
            setx PATH "%LINK_PATH%;%PATH%" >nul 2>&1
        )
    )
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

:: Initialize MSVC environment using vcvarsall.bat
echo.
echo Initializing MSVC environment...
if defined VS_PATH (
    echo Calling vcvarsall.bat to set up MSVC environment...
    call "%VS_PATH%\VC\Auxiliary\Build\vcvarsall.bat" %HOST_ARCH%_x64
    if %errorLevel% equ 0 (
        echo MSVC environment initialized successfully
    ) else (
        echo Warning: Failed to initialize MSVC environment
    )
) else (
    echo Warning: VS_PATH not defined, skipping vcvarsall.bat initialization
)

:: Set environment variables for cc-rs and other build tools
echo.
echo Setting environment variables for cc-rs...

:: Set MSVC-specific environment variables for Rust/Cargo
set CC=cl.exe
set CXX=cl.exe
set AR=lib.exe
set LINKER=link.exe

:: Set target-specific environment variables for cc-rs
if defined CL_PATH (
    set CC_x86_64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set CXX_x86_64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set AR_x86_64_pc_windows_msvc="%CL_PATH%\lib.exe"
    if defined LINK_PATH (
        set LINKER_x86_64_pc_windows_msvc="%LINK_PATH%\link.exe"
    ) else (
        set LINKER_x86_64_pc_windows_msvc="%CL_PATH%\link.exe"
    )
    
    set CC_aarch64_pc_windows_msvc="%CL_PATH%\cl.exe"
    set CXX_aarch64_pc_windows_msvc="%CL_PATH%\cl.exe"  
    set AR_aarch64_pc_windows_msvc="%CL_PATH%\lib.exe"
    if defined LINK_PATH (
        set LINKER_aarch64_pc_windows_msvc="%LINK_PATH%\link.exe"
    ) else (
        set LINKER_aarch64_pc_windows_msvc="%CL_PATH%\link.exe"
    )
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

:: Set general compiler environment variables
setx CC "cl.exe" >nul 2>&1
setx CXX "cl.exe" >nul 2>&1
setx AR "lib.exe" >nul 2>&1
setx LINKER "link.exe" >nul 2>&1

:: Set target-specific environment variables
if defined CL_PATH (
    setx CC_x86_64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul 2>&1
    setx CXX_x86_64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul 2>&1
    setx AR_x86_64_pc_windows_msvc "%CL_PATH%\lib.exe" >nul 2>&1
    if defined LINK_PATH (
        setx LINKER_x86_64_pc_windows_msvc "%LINK_PATH%\link.exe" >nul 2>&1
    ) else (
        setx LINKER_x86_64_pc_windows_msvc "%CL_PATH%\link.exe" >nul 2>&1
    )

    setx CC_aarch64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul 2>&1
    setx CXX_aarch64_pc_windows_msvc "%CL_PATH%\cl.exe" >nul 2>&1
    setx AR_aarch64_pc_windows_msvc "%CL_PATH%\lib.exe" >nul 2>&1
    if defined LINK_PATH (
        setx LINKER_aarch64_pc_windows_msvc "%LINK_PATH%\link.exe" >nul 2>&1
    ) else (
        setx LINKER_aarch64_pc_windows_msvc "%CL_PATH%\link.exe" >nul 2>&1
    )
) else (
    setx CC_x86_64_pc_windows_msvc "cl.exe" >nul 2>&1
    setx CXX_x86_64_pc_windows_msvc "cl.exe" >nul 2>&1
    setx AR_x86_64_pc_windows_msvc "lib.exe" >nul 2>&1
    setx LINKER_x86_64_pc_windows_msvc "link.exe" >nul 2>&1

    setx CC_aarch64_pc_windows_msvc "cl.exe" >nul 2>&1
    setx CXX_aarch64_pc_windows_msvc "cl.exe" >nul 2>&1
    setx AR_aarch64_pc_windows_msvc "lib.exe" >nul 2>&1
    setx LINKER_aarch64_pc_windows_msvc "link.exe" >nul 2>&1
)

:: Create a batch file to open Native Tools Command Prompt in project directory
echo.
echo Creating build helper script...
set "PROJECT_DIR=%CD%"
set "PROJECT_DIR_CMD=%PROJECT_DIR:\=\%"

:: Create a batch file that opens Native Tools Command Prompt in the project directory
(
echo @echo off
echo echo Opening Native Tools Command Prompt for VS in project directory...
echo echo Project directory: %PROJECT_DIR%
echo echo.
echo echo Available commands:
echo echo   cargo build --release          ^(Release build^)
echo echo   cargo build                    ^(Debug build^)
echo echo   cargo run                      ^(Build and run^)
echo echo   cl /? ^| more                   ^(MSVC compiler help^)
echo echo   link /?                        ^(MSVC linker help^)
echo echo.
echo cd /d "%PROJECT_DIR%"
echo cmd /k
) > open-native-tools.bat

:: Test if we can find the Native Tools Command Prompt
set "NATIVE_TOOLS_CMD="
if defined VS_PATH (
    if exist "%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat" (
        set "NATIVE_TOOLS_CMD=%VS_PATH%\VC\Auxiliary\Build\vcvars64.bat"
    )
)

if defined NATIVE_TOOLS_CMD (
    echo.
    echo ============================================
    echo Opening Native Tools Command Prompt
    echo ============================================
    echo.
    echo This will open a new cmd window with MSVC tools available.
    echo The window will automatically navigate to your project directory:
    echo %PROJECT_DIR%
    echo.
    echo In the new cmd window, you can run:
    echo   cargo build --release
    echo   cargo build
    echo   cargo run
    echo.
    echo Opening Native Tools Command Prompt now...
    
    :: Open Native Tools Command Prompt and navigate to project directory
    start "Native Tools Command Prompt" cmd /k ""%NATIVE_TOOLS_CMD%" && cd /d "%PROJECT_DIR%" && echo Ready to build! Try: cargo build --release"
    
    echo.
    echo Native Tools Command Prompt opened in a new window.
    echo You can now build your Rust project with MSVC tools!
) else (
    echo Warning: Could not find Native Tools Command Prompt.
    echo You can manually open it from Start Menu and navigate to:
    echo %PROJECT_DIR%
    echo.
    echo Then run: cargo build --release
)

echo.
echo ============================================
echo MSVC Setup Complete!
echo ============================================
echo.
echo ✅ What was configured:
echo - Found and verified MSVC tools (cl.exe, link.exe)
echo - Added MSVC tools to PATH
echo - Set environment variables for Rust/Cargo
echo.
echo 🚀 How to build your project:
echo.
echo METHOD 1 (Recommended): Use Native Tools Command Prompt
echo   1. Open "Native Tools Command Prompt for VS" from Start Menu
echo   2. Navigate to: %CD%
echo   3. Run: cargo build --release
echo.
echo METHOD 2: Use the helper script created
echo   - Run: open-native-tools.bat
echo   - This opens Native Tools Command Prompt in your project directory
echo.
echo 📁 Project directory (for cmd navigation):
echo   %CD%
echo   (In cmd: cd /d "%CD%")
echo.
echo 🔧 Available commands in Native Tools Command Prompt:
echo   cargo build --release    (Release build)
echo   cargo build              (Debug build) 
echo   cargo run                (Build and run)
echo   cl /?                    (MSVC compiler help)
echo   link /?                  (MSVC linker help)
echo.
echo 💡 Why Native Tools Command Prompt?
echo   - It's the proper cmd.exe environment with MSVC tools
echo   - PowerShell syntax (cd ~, ls, cat) won't work there
echo   - Use cmd syntax (cd %USERPROFILE%, dir, type) instead
echo.
echo Setup completed successfully!