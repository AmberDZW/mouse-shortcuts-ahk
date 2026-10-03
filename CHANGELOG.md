# Changelog

## 1.0.3

- Added an enable switch and adjustable 0.5–5 second left-button voice wake-up duration in Settings.
- Open Settings with a single click on the tray icon; closing Settings keeps shortcuts running in the tray.

## 1.0.2

- Turned voice typing off when the left button is released after a qualifying hold, making the two-second gesture behave as push-to-talk.

## 1.0.1

- Added a pass-through left-button hold gesture that sends Win+H after two seconds without pointer movement; short clicks still pass through and dragging cancels the gesture.

## 1.0.0

- Replaced the script-oriented portable bundle with one compiled `MouseShortcuts.exe` entry point.
- Added a bilingual settings and tray workflow for mappings, state, pause/resume, autostart, defaults, and config import/export.
- Added five user-friendly text shortcut slots without requiring AutoHotkey syntax.
- Moved user configuration out of the application directory so upgrades preserve mappings, language, and text.
- Disabled all optional mappings by default while keeping them visible in Settings.
- Added stronger duplicate and possible global-hotkey conflict warnings.
- Added a mouse-button detector for Windows-visible mouse, browser, media, launch, and extended keys.
- Reworked release packaging to fail when Ahk2Exe, the base binary, runtime, or AutoHotkey license is missing.
- Reduced the public zip to one top-level folder containing only the executable, user README, product license, and third-party notices.
- Added a dedicated application icon and Windows 1.0.0 product/version metadata.
- Added upgrade migration from sibling 0.7 folders, running legacy processes, and the legacy startup shortcut.
- Added a product-wide singleton handoff so the same executable opens the existing Settings window and a newer folder replaces an older 1.x process.
- Added compiled-EXE runtime, metadata, path-with-spaces, and cross-folder handoff checks to the release gate.

## 0.7.0

- Portable release packages now bundle `runtime/AutoHotkey64.exe`.
- End users no longer need to install AutoHotkey separately when using the release zip.
- Runtime discovery now prefers the bundled runtime, then falls back to an installed AutoHotkey v2.
- Added `THIRD_PARTY_NOTICES.md` and bundled AutoHotkey license text in release packages.

## 0.6.0

- Added custom text shortcuts backed by UTF-8 snippet files.
- Added five snippet slots in the control panel.
- Added `[TextHotkeys]` and `[Snippets]` config sections.
- Text shortcuts paste through the clipboard and then restore the previous clipboard.
- Release packages now include the `snippets/` directory.

## 0.5.0

- Added a language selector in the control panel.
- Added Chinese and English UI text for the control panel.
- Added `[Settings] language=zh-CN|en-US` so the selected language is remembered.

## 0.4.0

- Added explicit optional rows for `WheelUp`, `WheelDown`, `WheelLeft`, `WheelRight`, browser keys, vendor app keys, and extra programmable keys.
- Added `disabled` as a first-class action so supported buttons can be listed without being active.
- Expanded key detection for side-scroll wheels, browser keys, media keys, volume keys, and vendor launch keys.
- Added `validate-config.ahk` so config checks no longer disturb the running remapper instance.

## 0.3.0

- Fixed config check startup errors caused by writing to an unavailable stdout handle.
- Added `mouse-shortcuts-panel.ahk`, a visual control panel for changing middle, upper side, and lower side button mappings.
- Added `open-control-panel.cmd` and `mouse-shortcuts.cmd panel`.
- Added `[Slots]` metadata in `mouse-remap.ini` so the control panel can remember which physical buttons are assigned to each role.

## 0.2.0

- Added a unified command wrapper: `mouse-shortcuts.cmd`.
- Added PowerShell management commands for start, stop, restart, status, config check, autostart install, autostart uninstall, and release packaging.
- Added Windows startup shortcut support.
- Added a release zip builder.
- Added tray menu actions for opening config, opening the folder, reloading config, and exiting.
- Refreshed open-source documentation.
- Added ASCII-named delivery notes for release packages.

## 0.1.0

- Initial AutoHotkey v2 mouse button remapper.
