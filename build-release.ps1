[CmdletBinding()]
param(
    [string]$Version = "",
    [string]$SourcePath = "",
    [string]$CompilerPath = "",
    [string]$BasePath = "",
    [string]$RuntimePath = "",
    [string]$RuntimeLicensePath = "",
    [string]$ArchiveDir = ""
)

$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$VersionFile = Join-Path $Root "VERSION"
$ReleaseReadme = Join-Path $Root "README.release.txt"
$ApplicationIcon = Join-Path $Root "assets\MouseShortcuts.ico"
$ApplicationSource = Join-Path $Root "src\App.ahk"
$ProductLicense = Join-Path $Root "LICENSE"
$ThirdPartyNotices = Join-Path $Root "THIRD_PARTY_NOTICES.md"

function Get-ConfiguredPath {
    param(
        [string]$ExplicitPath,
        [string[]]$Candidates
    )

    if (![string]::IsNullOrWhiteSpace($ExplicitPath)) {
        return [Environment]::ExpandEnvironmentVariables($ExplicitPath)
    }

    foreach ($candidate in $Candidates) {
        if (![string]::IsNullOrWhiteSpace($candidate) -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return $candidate
        }
    }

    foreach ($candidate in $Candidates) {
        if (![string]::IsNullOrWhiteSpace($candidate)) {
            return $candidate
        }
    }

    return ""
}

function Assert-RequiredFile {
    param(
        [string]$Path,
        [string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Path) -or !(Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label`: $Path"
    }
}

function Assert-ExactFiles {
    param(
        [string]$Directory,
        [string[]]$ExpectedNames
    )

    $actualNames = @(Get-ChildItem -LiteralPath $Directory -File -Recurse | ForEach-Object {
        $_.FullName.Substring($Directory.Length).TrimStart("\", "/").Replace("\", "/")
    })

    if ($actualNames.Count -ne $ExpectedNames.Count) {
        throw "Release staging directory must contain exactly $($ExpectedNames.Count) files; found $($actualNames.Count)."
    }

    foreach ($expectedName in $ExpectedNames) {
        if ($actualNames -notcontains $expectedName) {
            throw "Release staging directory is missing: $expectedName"
        }
    }
}

function Assert-ZipLayout {
    param(
        [string]$Path,
        [string]$TopLevelFolder,
        [string[]]$ExpectedNames
    )

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $actualEntries = @($archive.Entries | Where-Object { $_.Name -ne "" } | ForEach-Object {
            $_.FullName.Replace("\", "/")
        })
        $expectedEntries = @($ExpectedNames | ForEach-Object { "$TopLevelFolder/$_" })

        if ($actualEntries.Count -ne $expectedEntries.Count) {
            throw "Release zip must contain exactly $($expectedEntries.Count) files; found $($actualEntries.Count)."
        }

        foreach ($expectedEntry in $expectedEntries) {
            if ($actualEntries -notcontains $expectedEntry) {
                throw "Release zip is missing: $expectedEntry"
            }
        }
    } finally {
        $archive.Dispose()
    }
}

if ([string]::IsNullOrWhiteSpace($Version)) {
    Assert-RequiredFile $VersionFile "Version file not found"
    $Version = (Get-Content -LiteralPath $VersionFile -Raw).Trim()
}
if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+(?:-[0-9A-Za-z.-]+)?$') {
    throw "Invalid release version: $Version"
}

$defaultRuntime = Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\v2\AutoHotkey64.exe"
$SourcePath = Get-ConfiguredPath $SourcePath @((Join-Path $Root "src\MouseShortcuts.ahk"))
$RuntimePath = Get-ConfiguredPath $RuntimePath @($env:AHK_EXE, $defaultRuntime)
$CompilerPath = Get-ConfiguredPath $CompilerPath @(
    $env:AHK2EXE,
    (Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\Compiler\Ahk2Exe.exe"),
    (Join-Path $env:ProgramFiles "AutoHotkey\Compiler\Ahk2Exe.exe"),
    (Join-Path ${env:ProgramFiles(x86)} "AutoHotkey\Compiler\Ahk2Exe.exe")
)
$BasePath = Get-ConfiguredPath $BasePath @($env:AHK_BASE, $RuntimePath)
$RuntimeLicensePath = Get-ConfiguredPath $RuntimeLicensePath @(
    $env:AHK_LICENSE,
    (Join-Path $env:LOCALAPPDATA "Programs\AutoHotkey\license.txt"),
    (Join-Path $env:ProgramFiles "AutoHotkey\license.txt"),
    (Join-Path ${env:ProgramFiles(x86)} "AutoHotkey\license.txt")
)

Assert-RequiredFile $SourcePath "Source script not found"
Assert-RequiredFile $CompilerPath "Ahk2Exe compiler not found"
Assert-RequiredFile $BasePath "AutoHotkey base binary not found"
Assert-RequiredFile $RuntimePath "AutoHotkey runtime not found"
Assert-RequiredFile $RuntimeLicensePath "AutoHotkey license not found"
Assert-RequiredFile $ReleaseReadme "Release README template not found"
Assert-RequiredFile $ApplicationIcon "Application icon not found"
Assert-RequiredFile $ApplicationSource "Application source not found"
Assert-RequiredFile $ProductLicense "Product license not found"
Assert-RequiredFile $ThirdPartyNotices "Third-party notices not found"

$sourceText = Get-Content -LiteralPath $SourcePath -Raw
$applicationSourceText = Get-Content -LiteralPath $ApplicationSource -Raw
$escapedVersion = [regex]::Escape($Version)
if ($applicationSourceText -notmatch ('global\s+gVersion\s*:=\s*"{0}"' -f $escapedVersion)) {
    throw "Source UI version does not match release version $Version."
}
$numericVersion = (($Version -split '-', 2)[0]) + ".0"
if ($sourceText -notmatch (';@Ahk2Exe-SetVersion\s+{0}(?:\r?\n|$)' -f [regex]::Escape($numericVersion))) {
    throw "Source PE version does not match release version $Version ($numericVersion)."
}

if ([string]::IsNullOrWhiteSpace($ArchiveDir)) {
    $RepoRoot = Split-Path -Parent (Split-Path -Parent $Root)
    $ArchiveDir = Join-Path $RepoRoot "archives\mouse-shortcuts"
}

$PackageName = "MouseShortcuts-$Version"
$StageRoot = Join-Path $env:TEMP ("mouse-shortcuts-release-" + [guid]::NewGuid().ToString("N"))
$StageDir = Join-Path $StageRoot $PackageName
$ZipPath = Join-Path $ArchiveDir "$PackageName.zip"
$TemporaryZipPath = Join-Path $ArchiveDir "$PackageName.tmp.zip"
$ExpectedFiles = @("MouseShortcuts.exe", "README.txt", "LICENSE.txt", "THIRD_PARTY_NOTICES.txt")

New-Item -ItemType Directory -Path $StageDir -Force | Out-Null
New-Item -ItemType Directory -Path $ArchiveDir -Force | Out-Null

try {
    $ExecutablePath = Join-Path $StageDir "MouseShortcuts.exe"
    $compilerArguments = @(
        "/in", ('"' + $SourcePath + '"'),
        "/out", ('"' + $ExecutablePath + '"'),
        "/base", ('"' + $BasePath + '"'),
        "/icon", ('"' + $ApplicationIcon + '"'),
        "/silent", "verbose"
    )
    $compilerProcess = Start-Process -FilePath $CompilerPath -ArgumentList $compilerArguments -Wait -PassThru
    if ($compilerProcess.ExitCode -ne 0) {
        throw "Ahk2Exe failed with exit code $($compilerProcess.ExitCode)."
    }
    if (!(Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        throw "Ahk2Exe completed without creating MouseShortcuts.exe."
    }

    $header = [System.IO.File]::ReadAllBytes($ExecutablePath)
    if ($header.Length -lt 2 -or $header[0] -ne 0x4d -or $header[1] -ne 0x5a) {
        throw "Ahk2Exe output is not a Windows PE executable."
    }

    Copy-Item -LiteralPath $ReleaseReadme -Destination (Join-Path $StageDir "README.txt")
    Copy-Item -LiteralPath $ProductLicense -Destination (Join-Path $StageDir "LICENSE.txt")

    $noticeText = (Get-Content -LiteralPath $ThirdPartyNotices -Raw).TrimEnd()
    $runtimeLicenseText = (Get-Content -LiteralPath $RuntimeLicensePath -Raw).Trim()
    $combinedNotices = $noticeText + "`r`n`r`n" + ("=" * 72) + "`r`nAUTOHOTKEY LICENSE TEXT`r`n" + ("=" * 72) + "`r`n`r`n" + $runtimeLicenseText + "`r`n"
    [System.IO.File]::WriteAllText(
        (Join-Path $StageDir "THIRD_PARTY_NOTICES.txt"),
        $combinedNotices,
        (New-Object System.Text.UTF8Encoding($true))
    )

    Assert-ExactFiles $StageDir $ExpectedFiles

    Remove-Item -LiteralPath $TemporaryZipPath -Force -ErrorAction SilentlyContinue
    Compress-Archive -LiteralPath $StageDir -DestinationPath $TemporaryZipPath -CompressionLevel Optimal -Force
    Assert-ZipLayout $TemporaryZipPath $PackageName $ExpectedFiles

    Remove-Item -LiteralPath $ZipPath -Force -ErrorAction SilentlyContinue
    Move-Item -LiteralPath $TemporaryZipPath -Destination $ZipPath
    Write-Host "Built release package: $ZipPath"
    Write-Output $ZipPath
} finally {
    Remove-Item -LiteralPath $TemporaryZipPath -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $StageRoot -Recurse -Force -ErrorAction SilentlyContinue
}
