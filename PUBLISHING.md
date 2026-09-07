# Publishing Guide

This guide is for maintainers. End users do not install AutoHotkey or use any command in this file.

## Output contract

The version comes from `VERSION`. The default output remains:

```text
<archive-directory>\MouseShortcuts-<version>.zip
```

The archive must contain one top-level folder and exactly these files:

```text
MouseShortcuts-<version>\
  MouseShortcuts.exe
  README.txt
  LICENSE.txt
  THIRD_PARTY_NOTICES.txt
```

No `.ahk`, `.ps1`, `.cmd`, `.ini`, default config, snippet file, compiler, or standalone runtime is shipped.

## Build prerequisites

The build is intentionally fail-closed. All of these files must exist:

- `src\MouseShortcuts.ahk`
- Ahk2Exe compiler
- AutoHotkey v2 base binary
- AutoHotkey v2 runtime
- AutoHotkey license text
- `README.release.txt`, `LICENSE`, and `THIRD_PARTY_NOTICES.md`

Standard per-user AutoHotkey locations are detected automatically. Override them when necessary:

```powershell
$env:AHK2EXE = 'C:\path\to\Ahk2Exe.exe'
$env:AHK_BASE = 'C:\path\to\AutoHotkey64.exe'
$env:AHK_EXE = 'C:\path\to\AutoHotkey64.exe'
$env:AHK_LICENSE = 'C:\path\to\AutoHotkey\license.txt'
```

For an ordinary AutoHotkey v2 build, `AHK_BASE` and `AHK_EXE` may point to the same `AutoHotkey64.exe` file. The compiler is a build-time dependency only.

## Build and verify

From the source directory:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\build-release.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Release.Tests.ps1
```

`build-release.ps1` compiles to a temporary staging directory, verifies the PE header and zip whitelist, then replaces the target archive. A failed build leaves an existing release archive untouched.

Before publishing, also test on a clean supported Windows x64 user account:

1. Download the same zip that will be shared.
2. Confirm Windows can extract it into one folder.
3. Confirm the folder contains exactly four files.
4. Double-click `MouseShortcuts.exe` without installing AutoHotkey.
5. Change mappings, language, snippets, and autostart; restart Windows and verify persistence.
6. Replace the executable with the new version and verify the existing user configuration remains.
7. Exercise tray Settings, Pause, Resume, and Exit.

## Publish

Publish the verified zip and the matching `CHANGELOG.md` entry. Do not rebuild after verification. Record the SHA-256 checksum beside the release asset.

The public description should say:

> Mouse Shortcuts is a portable Windows mouse-button and text-shortcut utility. Extract the zip and double-click MouseShortcuts.exe. No AutoHotkey installation is required.
