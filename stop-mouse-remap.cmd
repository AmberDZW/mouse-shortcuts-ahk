@echo off
set "SCRIPT=%~dp0mouse-remap.ahk"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$script = '%SCRIPT%'; $p = Get-CimInstance Win32_Process -Filter \"name = 'AutoHotkey64.exe'\" | Where-Object { $_.CommandLine -like ('*' + $script + '*') }; if ($p) { $p | ForEach-Object { Stop-Process -Id $_.ProcessId -Force }; 'mouse-remap stopped.' } else { 'mouse-remap was not running.' }"
