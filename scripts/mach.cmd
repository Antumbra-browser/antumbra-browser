@echo off
:: Antumbra: run mach inside the MozillaBuild shell from an ordinary terminal.
::
:: Usage:   scripts\mach.cmd build
::          scripts\mach.cmd build faster
::          scripts\mach.cmd run
::
:: mach must run inside MozillaBuild's MSYS2 environment, not PowerShell or cmd.
:: This wrapper hides that so Claude Code and normal terminals can drive builds.

setlocal

if "%MOZILLABUILD%"=="" set "MOZILLABUILD=C:\mozilla-build"
if "%ANTUMBRA_ROOT%"=="" set "ANTUMBRA_ROOT=D:\dev\antumbra"

if not exist "%MOZILLABUILD%\start-shell.bat" (
  echo [mach.cmd] MozillaBuild not found at %MOZILLABUILD%
  echo [mach.cmd] Install it, or set MOZILLABUILD to its location.
  exit /b 1
)

if not exist "%ANTUMBRA_ROOT%\firefox\mach" (
  echo [mach.cmd] No Firefox source tree at %ANTUMBRA_ROOT%\firefox
  echo [mach.cmd] Run scripts\setup-windows.ps1 and then the bootstrap step first.
  exit /b 1
)

:: Toolchains live on D:, not C:. Must be set before mach starts.
if "%MOZBUILD_STATE_PATH%"=="" set "MOZBUILD_STATE_PATH=%ANTUMBRA_ROOT%\.mozbuild"

:: D:\dev\antumbra -> /d/dev/antumbra for the MSYS2 shell.
set "MSYS_ROOT=%ANTUMBRA_ROOT::=%"
set "MSYS_ROOT=/%MSYS_ROOT:\=/%"

call "%MOZILLABUILD%\start-shell.bat" -c "cd %MSYS_ROOT%/firefox && ./mach %*"
exit /b %ERRORLEVEL%
