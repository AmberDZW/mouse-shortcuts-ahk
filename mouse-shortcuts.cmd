@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0MouseShortcuts.ps1" %*
exit /b %ERRORLEVEL%
