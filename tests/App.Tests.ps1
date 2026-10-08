param(
    [string]$AhkExe = "$env:LOCALAPPDATA\Programs\AutoHotkey\v2\AutoHotkey64.exe"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Main = Join-Path $Root "src\MouseShortcuts.ahk"
$LegacyTests = Join-Path $Root "tests\Legacy.Tests.ahk"
$TempRoot = Join-Path $env:TEMP ("MouseShortcuts-App-Tests-" + [guid]::NewGuid().ToString("N"))
$script:Checks = 0

function Assert-True([bool]$Condition, [string]$Message) {
    $script:Checks++
    if (!$Condition) {
        throw "FAIL: $Message"
    }
}

function Invoke-Ahk([string]$Arguments, [string]$ScriptPath = $Main) {
    $stdout = Join-Path $TempRoot "stdout.txt"
    $stderr = Join-Path $TempRoot "stderr.txt"
    Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
    $process = Start-Process -FilePath $AhkExe `
        -ArgumentList ('/ErrorStdOut "{0}" {1}' -f $ScriptPath, $Arguments) `
        -Wait -PassThru -WindowStyle Hidden `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    return [pscustomobject]@{
        ExitCode = $process.ExitCode
        StdOut = if (Test-Path $stdout) { Get-Content $stdout -Raw } else { "" }
        StdErr = if (Test-Path $stderr) { Get-Content $stderr -Raw } else { "" }
    }
}

try {
    New-Item -ItemType Directory -Path $TempRoot -Force | Out-Null
    Assert-True (Test-Path $AhkExe) "AutoHotkey test runtime exists"
    Assert-True (Test-Path $Main) "Application entry script exists"

    $selfTest = Invoke-Ahk "--self-test"
    Assert-True ($selfTest.ExitCode -eq 0) "Application self-test exits successfully: $($selfTest.StdErr)"
    Assert-True ($selfTest.StdOut -match "PASS: MouseShortcuts self-test") "Self-test reports success"

    $exportPath = Join-Path $TempRoot "默认 配置.msconfig"
    $export = Invoke-Ahk ('--export-default "{0}" --language zh-CN' -f $exportPath)
    Assert-True ($export.ExitCode -eq 0) "Default export exits successfully: $($export.StdErr)"
    Assert-True (Test-Path $exportPath) "Default export creates a config file"
    $exportedText = Get-Content $exportPath -Raw
    Assert-True ($exportedText -match "language=zh-CN") "Export remembers Chinese language"
    Assert-True ($exportedText -match "right=RButton\|disabled") "Export preserves native right clicks"
    Assert-True ($exportedText -match "right=voice\|2000") "Export defaults right-button holds to two-second voice typing"
    Assert-True ($exportedText -match "middle=MButton\|voice") "Export contains the requested middle-button default"
    Assert-True ($exportedText -match "side_up=XButton2\|enter") "Export contains the requested upper-side default"
    Assert-True ($exportedText -match "side_down=XButton1\|backspace") "Export contains the requested lower-side default"

    $uiSmoke = Invoke-Ahk "--ui-smoke"
    Assert-True ($uiSmoke.ExitCode -eq 0) "Hidden GUI smoke test exits successfully: $($uiSmoke.StdErr)"
    Assert-True ($uiSmoke.StdOut -match "PASS: MouseShortcuts UI smoke") "GUI smoke reports success"

    $legacy = Invoke-Ahk "" $LegacyTests
    Assert-True ($legacy.ExitCode -eq 0) "Legacy shortcut migration test exits successfully: $($legacy.StdErr)"
    Assert-True ($legacy.StdOut -match "PASS: Legacy.Tests") "Legacy shortcut migration reports success"

    $registration = Invoke-Ahk "" (Join-Path $Root "tests\Registration.Tests.ahk")
    Assert-True ($registration.ExitCode -eq 0) "Actual runtime hook registration succeeds: $($registration.StdErr)"
    Assert-True ($registration.StdOut -match "PASS: Registration.Tests") "Runtime registration reports success"

    Write-Host "PASS: App.Tests ($script:Checks checks)"
} finally {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}
