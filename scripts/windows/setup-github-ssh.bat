@echo off
rem Double-click this file to set up your connection to GitHub.
rem If Windows shows "Windows protected your PC": click "More info"
rem and then "Run anyway".
if not exist "%~dp0lib\setup-github-ssh.ps1" (
  echo.
  echo First extract the whole ZIP: right-click the .zip file,
  echo "Extract All...", then open this file from the extracted folder.
  echo.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0lib\setup-github-ssh.ps1"
if errorlevel 1 pause
