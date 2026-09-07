#Requires AutoHotkey v2.0
#Include ..\src\Core.ahk
#Include ..\src\Translations.ahk
#Include ..\src\App.ahk

root := A_Temp "\MouseShortcuts-Legacy-Shortcut-Test-" A_TickCount
oldDirectory := root "\Old Mouse Shortcuts"
shortcutPath := root "\Mouse Shortcuts.lnk"
try {
    DirCreate(oldDirectory)
    commandPath := oldDirectory "\mouse-shortcuts.cmd"
    configPath := oldDirectory "\mouse-remap.ini"
    FileAppend("@echo off`r`n", commandPath, "UTF-8")
    FileAppend("[Settings]`r`nlanguage=zh-CN`r`n", configPath, "UTF-8")

    shell := ComObject("WScript.Shell")
    shortcut := shell.CreateShortcut(shortcutPath)
    shortcut.TargetPath := commandPath
    shortcut.WorkingDirectory := oldDirectory
    shortcut.Save()

    actual := LegacyConfigPathFromShortcut(shortcutPath)
    if (actual != configPath) {
        throw Error("Legacy shortcut resolved to: " actual)
    }
    FileAppend("PASS: Legacy.Tests`n", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: Legacy.Tests: " err.Message "`n", "**", "UTF-8")
    ExitApp(1)
} finally {
    try DirDelete(root, true)
}
