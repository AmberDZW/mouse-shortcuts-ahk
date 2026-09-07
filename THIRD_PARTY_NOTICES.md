# Third-Party Notices

Mouse Shortcuts is compiled with the AutoHotkey v2 base runtime so end users can run `MouseShortcuts.exe` without installing AutoHotkey separately.

## AutoHotkey

- Component: AutoHotkey v2 runtime embedded in `MouseShortcuts.exe`
- Project: AutoHotkey
- Website: https://www.autohotkey.com/
- License: GNU General Public License version 2

During packaging, `build-release.ps1` appends the complete AutoHotkey license text to the generated `THIRD_PARTY_NOTICES.txt`. Packaging fails if that license source is unavailable.

Mouse Shortcuts source files remain governed by the project `LICENSE`. Ahk2Exe is used only at build time and is not included in the public archive.
