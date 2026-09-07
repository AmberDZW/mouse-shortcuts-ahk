# Delivery Notes

## End-user package

The 1.0.0 deliverable is:

```text
<archive-directory>\MouseShortcuts-1.0.0.zip
```

Users extract the zip and double-click `MouseShortcuts.exe`. They do not install AutoHotkey and do not choose among scripts.

The zip contains one `MouseShortcuts-1.0.0` folder with exactly:

```text
MouseShortcuts.exe
README.txt
LICENSE.txt
THIRD_PARTY_NOTICES.txt
```

`README.txt` begins with the extraction, single-entry, no-extra-install, and no-run-inside-zip instructions.

## Upgrade behavior

The release contains no default config or user snippets. Runtime settings live in the current user's Windows data directory, so replacing the application with a later version does not overwrite mappings or text shortcuts.

## Acceptance gate

The package is shareable only after `tests\Release.Tests.ps1` passes. A broad public release should additionally smoke-test the intended physical mouse models because proprietary HID-only buttons depend on vendor drivers.

## Verified artifact

Verified on 2026-07-10:

- Core configuration tests: 10 groups passed.
- Application tests: 14 checks passed.
- Compiled release and archive tests: 47 checks passed.
- Visible 125% DPI checks covered both languages, optional-button paging, F17 detection, Ctrl+Alt+1 recording, and Chinese/English multiline text persistence.
- The protected pre-existing 0.7 processes were not stopped or modified during verification.

```text
File:   <archive-directory>\MouseShortcuts-1.0.0.zip
Size:   658697 bytes
SHA256: aeae154186cd5a458372a414bade8bedaa8581ff9d86326bc1e30ff0e2d90a3d
```
