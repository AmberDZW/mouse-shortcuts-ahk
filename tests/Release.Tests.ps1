[CmdletBinding()]
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$BuildScript = Join-Path $ProjectRoot "build-release.ps1"
$ReleaseReadme = Join-Path $ProjectRoot "README.release.txt"
$VersionFile = Join-Path $ProjectRoot "VERSION"
$Failures = New-Object System.Collections.Generic.List[string]
$Checks = 0

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    $script:Checks += 1
    if (!$Condition) {
        $script:Failures.Add($Message)
    }
}

function Assert-Equal {
    param(
        $Actual,
        $Expected,
        [string]$Message
    )

    Assert-True ($Actual -eq $Expected) "$Message (expected='$Expected', actual='$Actual')"
}

function Assert-Contains {
    param(
        [string]$Actual,
        [string]$Expected,
        [string]$Message
    )

    Assert-True ($Actual.IndexOf($Expected, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) "$Message (missing='$Expected')"
}

function Start-TestProcess {
    param(
        [string]$FilePath,
        [string]$Arguments,
        [int]$TimeoutMilliseconds = 10000
    )

    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -PassThru
    $completed = $process.WaitForExit($TimeoutMilliseconds)
    if (!$completed) {
        Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
        $process.WaitForExit()
    }
    return [pscustomobject]@{ Process = $process; Completed = $completed }
}

function Test-MissingDependency {
    param(
        [string]$ParameterName,
        [string]$ExpectedError
    )

    $fixtureRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("MouseShortcuts-Release-Test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $fixtureRoot -Force | Out-Null

    try {
        $paths = @{
            SourcePath = Join-Path $fixtureRoot "MouseShortcuts.ahk"
            CompilerPath = Join-Path $fixtureRoot "Ahk2Exe.exe"
            BasePath = Join-Path $fixtureRoot "AutoHotkeySC.bin"
            RuntimePath = Join-Path $fixtureRoot "AutoHotkey64.exe"
            RuntimeLicensePath = Join-Path $fixtureRoot "AutoHotkey-LICENSE.txt"
            ArchiveDir = Join-Path $fixtureRoot "archives"
        }

        foreach ($path in @($paths.SourcePath, $paths.CompilerPath, $paths.BasePath, $paths.RuntimePath, $paths.RuntimeLicensePath)) {
            Set-Content -LiteralPath $path -Value "fixture" -Encoding Ascii
        }
        Remove-Item -LiteralPath $paths[$ParameterName] -Force

        $threw = $false
        $message = ""
        try {
            & $BuildScript @paths -Version "1.0.0-test" *> $null
        } catch {
            $threw = $true
            $message = $_.Exception.Message
        }

        Assert-True $threw "Build must fail when $ParameterName is missing"
        Assert-Contains $message $ExpectedError "Missing $ParameterName error must identify the dependency"
    } finally {
        Remove-Item -LiteralPath $fixtureRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Assert-True (Test-Path -LiteralPath $BuildScript -PathType Leaf) "build-release.ps1 must exist"
Assert-True (Test-Path -LiteralPath $ReleaseReadme -PathType Leaf) "README.release.txt must exist"

if (Test-Path -LiteralPath $ReleaseReadme -PathType Leaf) {
    $firstScreen = (Get-Content -LiteralPath $ReleaseReadme -Encoding UTF8 -TotalCount 20) -join "`n"
    $extractText = -join [char[]](0x5148, 0x89e3, 0x538b)
    $doubleClickText = (-join [char[]](0x53cc, 0x51fb)) + " MouseShortcuts.exe"
    $noInstallText = -join [char[]](0x4e0d, 0x9700, 0x8981, 0x5b89, 0x88c5)
    $zipWarningText = -join [char[]](0x4e0d, 0x8981, 0x76f4, 0x63a5, 0x5728, 0x538b, 0x7f29, 0x5305)
    Assert-Contains $firstScreen $extractText "Release README first screen must tell users to extract the zip"
    Assert-Contains $firstScreen $doubleClickText "Release README first screen must name the single entry point"
    Assert-Contains $firstScreen $noInstallText "Release README first screen must state that no extra installation is needed"
    Assert-Contains $firstScreen $zipWarningText "Release README first screen must warn against running inside the zip"
}

$version = if (Test-Path -LiteralPath $VersionFile) { (Get-Content -LiteralPath $VersionFile -Raw).Trim() } else { "" }
Assert-Equal $version "1.0.3" "VERSION must identify the 1.0.3 release"

Test-MissingDependency "SourcePath" "Source script not found"
Test-MissingDependency "CompilerPath" "Ahk2Exe compiler not found"
Test-MissingDependency "BasePath" "AutoHotkey base binary not found"
Test-MissingDependency "RuntimePath" "AutoHotkey runtime not found"
Test-MissingDependency "RuntimeLicensePath" "AutoHotkey license not found"

if (!$SkipBuild) {
    try {
        & $BuildScript *> $null
    } catch {
        $Failures.Add("Release build failed: $($_.Exception.Message)")
    }

    $repoRoot = Split-Path -Parent (Split-Path -Parent $ProjectRoot)
    $zipPath = Join-Path $repoRoot "archives\mouse-shortcuts\MouseShortcuts-$version.zip"
    Assert-True (Test-Path -LiteralPath $zipPath -PathType Leaf) "Release zip must be written to the established archive directory"

    if (Test-Path -LiteralPath $zipPath -PathType Leaf) {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
        try {
            $fileEntries = @($archive.Entries | Where-Object { $_.Name -ne "" } | ForEach-Object { $_.FullName.Replace("\", "/") })
            $expectedEntries = @(
                "MouseShortcuts-$version/MouseShortcuts.exe",
                "MouseShortcuts-$version/README.txt",
                "MouseShortcuts-$version/LICENSE.txt",
                "MouseShortcuts-$version/THIRD_PARTY_NOTICES.txt"
            )

            Assert-Equal $fileEntries.Count $expectedEntries.Count "Release zip must contain exactly four files"
            foreach ($entry in $expectedEntries) {
                Assert-True ($fileEntries -contains $entry) "Release zip is missing $entry"
            }
            foreach ($entry in $fileEntries) {
                Assert-True ($entry.StartsWith("MouseShortcuts-$version/", [System.StringComparison]::Ordinal)) "Every release file must be under one top-level folder: $entry"
                Assert-True ($entry -notmatch '\.(ahk|ps1|cmd|ini)$') "Release zip must not contain source, scripts, or config: $entry"
            }

            $exeEntry = $archive.GetEntry("MouseShortcuts-$version/MouseShortcuts.exe")
            if ($null -ne $exeEntry) {
                $stream = $exeEntry.Open()
                try {
                    $first = $stream.ReadByte()
                    $second = $stream.ReadByte()
                    Assert-True ($first -eq 0x4d -and $second -eq 0x5a) "MouseShortcuts.exe must be a Windows PE executable"
                } finally {
                    $stream.Dispose()
                }
            }
        } finally {
            $archive.Dispose()
        }

        $zhPath = -join [char[]](0x4e2d, 0x6587, 0x9a8c, 0x8bc1)
        $runtimeRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("Mouse Shortcuts $zhPath " + [guid]::NewGuid().ToString("N"))
        $trackedProcesses = New-Object System.Collections.Generic.List[System.Diagnostics.Process]
        try {
            Expand-Archive -LiteralPath $zipPath -DestinationPath $runtimeRoot -Force
            $executable = Join-Path $runtimeRoot "MouseShortcuts-$version\MouseShortcuts.exe"
            Assert-True (Test-Path -LiteralPath $executable -PathType Leaf) "Extracted MouseShortcuts.exe must exist"

            if (Test-Path -LiteralPath $executable -PathType Leaf) {
                $selfTest = Start-TestProcess $executable "--self-test"
                Assert-True $selfTest.Completed "Compiled EXE self-test must finish without hanging"
                Assert-Equal $selfTest.Process.ExitCode 0 "Compiled EXE self-test must pass"

                $uiSmoke = Start-TestProcess $executable "--ui-smoke"
                Assert-True $uiSmoke.Completed "Compiled EXE UI smoke must finish without hanging"
                Assert-Equal $uiSmoke.Process.ExitCode 0 "Compiled EXE UI smoke must pass"

                $versionInfo = (Get-Item -LiteralPath $executable).VersionInfo
                Assert-Equal $versionInfo.ProductName "Mouse Shortcuts" "Compiled EXE ProductName"
                Assert-Equal $versionInfo.FileDescription "Portable mouse button and text shortcut utility" "Compiled EXE FileDescription"
                Assert-Equal $versionInfo.FileVersion "${version}.0" "Compiled EXE FileVersion"
                Assert-Equal $versionInfo.ProductVersion "${version}.0" "Compiled EXE ProductVersion"
                Assert-Equal $versionInfo.OriginalFilename "MouseShortcuts.exe" "Compiled EXE OriginalFilename"

                $scope = [guid]::NewGuid().ToString("N")
                $instanceArguments = "--test-mode --background --test-instance $scope"
                $first = Start-Process -FilePath $executable -ArgumentList $instanceArguments -PassThru
                $trackedProcesses.Add($first)
                Start-Sleep -Milliseconds 800
                $first.Refresh()
                Assert-True (!$first.HasExited) "First isolated test instance must stay running"

                $samePath = Start-TestProcess $executable $instanceArguments 6000
                Assert-True $samePath.Completed "Second same-path launch must return promptly"
                Assert-Equal $samePath.Process.ExitCode 0 "Second same-path launch must signal Settings and exit"
                $first.Refresh()
                Assert-True (!$first.HasExited) "Same-path launch must preserve the existing instance"

                $secondDirectory = Join-Path $runtimeRoot "second version folder"
                New-Item -ItemType Directory -Path $secondDirectory -Force | Out-Null
                $secondExecutable = Join-Path $secondDirectory "MouseShortcuts.exe"
                Copy-Item -LiteralPath $executable -Destination $secondExecutable
                $replacement = Start-Process -FilePath $secondExecutable -ArgumentList $instanceArguments -PassThru
                $trackedProcesses.Add($replacement)

                $deadline = [DateTime]::UtcNow.AddSeconds(7)
                do {
                    Start-Sleep -Milliseconds 100
                    $first.Refresh()
                    $replacement.Refresh()
                } while (!$first.HasExited -and !$replacement.HasExited -and [DateTime]::UtcNow -lt $deadline)

                Assert-True $first.HasExited "Different-path launch must retire the older 1.x instance"
                Assert-True (!$replacement.HasExited) "Different-path launch must become the active instance"
            }
        } catch {
            $Failures.Add("Compiled release runtime verification failed: $($_.Exception.Message)")
        } finally {
            foreach ($process in $trackedProcesses) {
                if (!$process.HasExited) {
                    Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue
                }
                Remove-Item -LiteralPath (Join-Path $env:TEMP ("MouseShortcuts-TestMode-" + $process.Id)) -Recurse -Force -ErrorAction SilentlyContinue
            }
            Remove-Item -LiteralPath $runtimeRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

if ($Failures.Count -gt 0) {
    foreach ($failure in $Failures) {
        Write-Host "FAIL: $failure" -ForegroundColor Red
    }
    Write-Host "FAIL: Release.Tests ($($Failures.Count) failures, $Checks checks)" -ForegroundColor Red
    exit 1
}

Write-Host "PASS: Release.Tests ($Checks checks)" -ForegroundColor Green
exit 0
