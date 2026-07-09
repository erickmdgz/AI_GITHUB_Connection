@echo off
rem Double-click this file to check your connection to GitHub.
rem It changes nothing: it only inspects and reports.
if not exist "%~dp0lib\check-github-ssh.ps1" (
  echo.
  echo First extract the whole ZIP: right-click the .zip file,
  echo "Extract All...", then open this file from the extracted folder.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\check-github-ssh.ps1"
if errorlevel 1 pause
