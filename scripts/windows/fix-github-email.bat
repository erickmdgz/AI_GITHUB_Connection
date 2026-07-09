@echo off
rem Double-click this file to fix the email in your configuration.
if not exist "%~dp0lib\fix-github-email.ps1" (
  echo.
  echo First extract the whole ZIP: right-click the .zip file,
  echo "Extract All...", then open this file from the extracted folder.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\fix-github-email.ps1"
if errorlevel 1 pause
