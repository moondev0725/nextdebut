@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PROJECT_ROOT=%~dp0"
if not exist "%PROJECT_ROOT%tools\create_launcher_shortcut.ps1" (
  echo Missing: %PROJECT_ROOT%tools\create_launcher_shortcut.ps1
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PROJECT_ROOT%tools\create_launcher_shortcut.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

if not "%EXIT_CODE%"=="0" (
  echo.
  echo Failed to create the NEXTDEBUT desktop shortcut.
  echo Please send the error message shown above.
  pause
  exit /b %EXIT_CODE%
)

echo.
echo Created or updated the NEXTDEBUT desktop shortcut.
echo You can launch the app from NEXTDEBUT.lnk on your Desktop.
pause
exit /b 0
