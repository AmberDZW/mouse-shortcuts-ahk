@echo off
set "AHK=%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe"
set "SCRIPT=%~dp0mouse-remap.ahk"

if not exist "%AHK%" (
  echo AutoHotkey v2 not found: %AHK%
  exit /b 1
)

start "" "%AHK%" /ErrorStdOut "%SCRIPT%"
