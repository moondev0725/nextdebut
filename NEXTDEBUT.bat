@echo off
setlocal EnableExtensions
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Sta -WindowStyle Hidden -File "%~dp0tools\launch_nextdebut_gui.ps1"
exit /b %ERRORLEVEL%
