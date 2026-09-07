param(
    [ValidateSet("start", "stop", "restart", "status", "check", "panel", "settings", "install", "uninstall", "package", "help")]
    [string]$Command = "help"
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BundledAhkExe = Join-Path $Root "runtime\AutoHotkey64.exe"
$InstalledAhkExe = Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\v2\AutoHotkey64.exe"
$AhkExe = if ($env:AHK_EXE) {
    $env:AHK_EXE
} elseif (Test-Path -LiteralPath $BundledAhkExe) {
    $BundledAhkExe
} else {
    $InstalledAhkExe
}
$ScriptPath = Join-Path $Root "mouse-remap.ahk"
$CheckPath = Join-Path $Root "validate-config.ahk"
$PanelPath = Join-Path $Root "mouse-shortcuts-panel.ahk"
$CmdPath = Join-Path $Root "mouse-shortcuts.cmd"
$StartupShortcut = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup\Mouse Shortcuts.lnk"

function Write-Section([string]$Message) {
    Write-Host "[Mouse Shortcuts] $Message"
}

function Assert-AutoHotkey {
    if (!(Test-Path -LiteralPath $AhkExe)) {
        throw "AutoHotkey runtime not found.`nPortable releases should include runtime\AutoHotkey64.exe.`nSource users can install AutoHotkey v2 or set AHK_EXE."
    }
}

function Get-ManagedProcess {
    Get-CimInstance Win32_Process -Filter "name = 'AutoHotkey64.exe' or name = 'AutoHotkey.exe'" |
        Where-Object {
            $_.CommandLine -and
            $_.CommandLine.IndexOf($ScriptPath, [System.StringComparison]::OrdinalIgnoreCase) -ge 0
        }
}

function Invoke-ConfigCheck {
    Assert-AutoHotkey
    if (!(Test-Path -LiteralPath $CheckPath)) {
        throw "Config validator not found: $CheckPath"
    }
    & $AhkExe /ErrorStdOut $CheckPath
    $exitCode = if ([string]::IsNullOrWhiteSpace([string]$LASTEXITCODE)) { 0 } else { [int]$LASTEXITCODE }
    if ($exitCode -ne 0) {
        throw "Config check failed with exit code $exitCode."
    }
    Write-Section "Config OK."
}

function Start-MouseShortcuts {
    Assert-AutoHotkey
    Invoke-ConfigCheck

    $running = @(Get-ManagedProcess)
    if ($running.Count -gt 0) {
        Write-Section "Already running. PID: $($running.ProcessId -join ', ')"
        return
    }

    Start-Process -FilePath $AhkExe -ArgumentList @("/ErrorStdOut", $ScriptPath) -WorkingDirectory $Root -WindowStyle Hidden
    Start-Sleep -Milliseconds 500

    $started = @(Get-ManagedProcess)
    if ($started.Count -eq 0) {
        throw "Start command returned, but the AutoHotkey process was not found."
    }

    Write-Section "Started. PID: $($started.ProcessId -join ', ')"
}

function Stop-MouseShortcuts {
    $running = @(Get-ManagedProcess)
    if ($running.Count -eq 0) {
        Write-Section "Not running."
        return
    }

    foreach ($process in $running) {
        Stop-Process -Id $process.ProcessId -Force
    }
    Write-Section "Stopped. PID: $($running.ProcessId -join ', ')"
}

function Show-Status {
    if (Test-Path -LiteralPath $AhkExe) {
        Write-Section "Runtime: $AhkExe"
    } else {
        Write-Section "Runtime missing: $AhkExe"
    }

    $running = @(Get-ManagedProcess)
    if ($running.Count -eq 0) {
        Write-Section "Status: stopped"
    } else {
        Write-Section "Status: running"
        $running | Select-Object ProcessId, CommandLine | Format-Table -AutoSize
    }

    if (Test-Path -LiteralPath $StartupShortcut) {
        Write-Section "Autostart: enabled"
    } else {
        Write-Section "Autostart: disabled"
    }
}

function Open-ControlPanel {
    Assert-AutoHotkey
    if (!(Test-Path -LiteralPath $PanelPath)) {
        throw "Control panel not found: $PanelPath"
    }

    Start-Process -FilePath $AhkExe -ArgumentList @($PanelPath) -WorkingDirectory $Root
    Write-Section "Control panel opened."
}

function Install-Autostart {
    if (!(Test-Path -LiteralPath $CmdPath)) {
        throw "Command wrapper not found: $CmdPath"
    }

    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($StartupShortcut)
    $shortcut.TargetPath = $CmdPath
    $shortcut.Arguments = "start"
    $shortcut.WorkingDirectory = $Root
    $shortcut.IconLocation = $AhkExe
    $shortcut.Save()

    Write-Section "Autostart enabled: $StartupShortcut"
}

function Uninstall-Autostart {
    if (Test-Path -LiteralPath $StartupShortcut) {
        Remove-Item -LiteralPath $StartupShortcut -Force
        Write-Section "Autostart disabled."
    } else {
        Write-Section "Autostart was not enabled."
    }
}

function Build-Package {
    $builder = Join-Path $Root "build-release.ps1"
    if (!(Test-Path -LiteralPath $builder)) {
        throw "Release builder not found: $builder"
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File $builder
    $exitCode = if ([string]::IsNullOrWhiteSpace([string]$LASTEXITCODE)) { 0 } else { [int]$LASTEXITCODE }
    if ($exitCode -ne 0) {
        throw "Release builder failed with exit code $exitCode."
    }
}

function Show-Help {
    @"
Mouse Shortcuts

Runtime:
  Portable runtime: runtime\AutoHotkey64.exe
  Installed fallback: %LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe

Usage:
  mouse-shortcuts.cmd start      Start the mouse remapper
  mouse-shortcuts.cmd stop       Stop the mouse remapper
  mouse-shortcuts.cmd restart    Reload mappings
  mouse-shortcuts.cmd status     Show process and autostart status
  mouse-shortcuts.cmd check      Validate mouse-remap.ini
  mouse-shortcuts.cmd panel      Open the visual control panel
  mouse-shortcuts.cmd install    Enable Windows startup
  mouse-shortcuts.cmd uninstall  Disable Windows startup
  mouse-shortcuts.cmd package    Build a release zip

Tip: edit mouse-remap.ini, then run mouse-shortcuts.cmd restart.
"@
}

switch ($Command) {
    "start" { Start-MouseShortcuts }
    "stop" { Stop-MouseShortcuts }
    "restart" { Stop-MouseShortcuts; Start-MouseShortcuts }
    "status" { Show-Status }
    "check" { Invoke-ConfigCheck }
    "panel" { Open-ControlPanel }
    "settings" { Open-ControlPanel }
    "install" { Install-Autostart }
    "uninstall" { Uninstall-Autostart }
    "package" { Build-Package }
    "help" { Show-Help }
}
