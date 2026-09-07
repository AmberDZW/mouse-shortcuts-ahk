# Contributing

Thanks for helping improve Mouse Shortcuts.

## Development

1. Install AutoHotkey v2.
2. Edit `mouse-remap.ahk`, `mouse-shortcuts-panel.ahk`, `MouseShortcuts.ps1`, or the docs.
3. Validate the default config:

```bat
mouse-shortcuts.cmd check
```

4. Run locally:

```bat
mouse-shortcuts.cmd restart
mouse-shortcuts.cmd status
```

5. Build a release package:

```bat
mouse-shortcuts.cmd package
```

## Pull Request Checklist

- Keep the tool dependency-light: AutoHotkey v2 plus built-in Windows PowerShell.
- Do not add telemetry, network calls, or hidden background behavior.
- Update `README.md` and `CHANGELOG.md` when changing user-facing behavior.
- Keep the default mapping understandable for ordinary mouse side buttons.
