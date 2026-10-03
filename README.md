# Mouse Shortcuts

### Put the actions you repeat most on the mouse you already use.

[Download v1.0.3](https://github.com/AmberDZW/mouse-shortcuts-ahk/releases/download/v1.0.3/MouseShortcuts-1.0.3.zip) · [简体中文](README.zh-CN.md) · [Changelog](CHANGELOG.md)

Mouse Shortcuts is a small Windows tray app for turning mouse buttons into practical shortcuts. Hold the left button to start Windows Voice Typing, tap a side button for Enter or Backspace, or paste a saved phrase without reaching for the keyboard.

## Default controls

| Mouse action | Result |
| --- | --- |
| Hold the left button still for 2 seconds | Start Windows Voice Typing (`Win+H`); release to end the voice session |
| Middle button | Start Windows Voice Typing (`Win+H`) |
| Upper side button | Enter |
| Lower side button | Backspace |

Left clicks pass through to Windows as usual. Moving the pointer far enough to begin a drag cancels the left-button hold before it activates. Settings lets you enable or disable the left hold-to-talk gesture and choose its wake-up time from 0.5 to 5 seconds. The middle- and side-button mappings can also be changed.

## Why keep it around?

- **Reach fewer keys.** Put familiar actions such as copy, paste, undo, media controls, or browser navigation on buttons your hand already finds.
- **Speak without a keyboard detour.** A stationary two-second left-button hold starts Windows Voice Typing; releasing the button ends that voice session.
- **Reuse the phrases you type every day.** Save up to five Unicode or multiline text snippets and assign each its own keyboard shortcut.
- **Adjust it without editing scripts.** The bilingual Settings window can detect buttons, change actions, warn about shortcut conflicts, and apply changes immediately.
- **Keep it out of the way.** Mouse Shortcuts lives in the system tray, with pause/resume and optional Windows startup controls.

## Get started

1. Download and fully extract [`MouseShortcuts-1.0.3.zip`](https://github.com/AmberDZW/mouse-shortcuts-ahk/releases/download/v1.0.3/MouseShortcuts-1.0.3.zip).
2. Double-click `MouseShortcuts.exe`; shortcuts start automatically.
3. Click the tray icon to open Settings, then save and apply your changes. Closing Settings keeps shortcuts running in the tray.

The portable package includes what it needs; you do not need to install AutoHotkey. Your settings are kept in `%LOCALAPPDATA%\MouseShortcuts\settings.msconfig`, separately from the executable, so replacing the app with a newer release preserves them.

## Make it yours

Settings includes common mouse buttons, wheel directions, browser and media buttons, launch buttons, and F13–F24. Hardware-specific buttons are available when the mouse driver exposes them to Windows as standard keys. Use the built-in button detector if you are not sure how Windows identifies a button.

You can also:

- choose from common keyboard and Windows actions;
- pause or resume shortcuts from the tray;
- enable or disable startup with Windows;
- import and export your settings.

Exported settings may contain the phrases you saved. Review the file before sharing it.

## Local behavior

Mouse Shortcuts runs its mappings on your PC and stores its settings locally. For voice input, it sends the `Win+H` shortcut to open Windows Voice Typing; microphone access and speech processing are handled by Windows. Mouse Shortcuts does not record audio itself.

The app does not require administrator privileges or an account. A mouse button only works when Windows and its driver expose it as a supported key.

## For contributors

The source is AutoHotkey v2. See [PUBLISHING.md](PUBLISHING.md) for build requirements and release packaging, and [CONTRIBUTING.md](CONTRIBUTING.md) for development notes.

Mouse Shortcuts is [MIT licensed](LICENSE). The release package includes the required AutoHotkey notices.

If this makes a repetitive part of your day easier, a ⭐ helps other Windows users find it.
