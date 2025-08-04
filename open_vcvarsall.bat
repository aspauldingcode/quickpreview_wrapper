@echo off
set "PROJECT_DIR=%CD%"
set "VCVARSALL=C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat"

start "MSVC Dev Shell" cmd /k ""%VCVARSALL%" x64 && cd /d "%PROJECT_DIR%" && echo Ready!"
