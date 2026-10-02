;@Ahk2Exe-SetName Mouse Shortcuts
;@Ahk2Exe-SetProductName Mouse Shortcuts
;@Ahk2Exe-SetDescription Portable mouse button and text shortcut utility
;@Ahk2Exe-SetVersion 1.0.2.0
;@Ahk2Exe-SetOrigFilename MouseShortcuts.exe
;@Ahk2Exe-SetCopyright Copyright (c) 2026 Mouse Shortcuts contributors

#Requires AutoHotkey v2.0
#SingleInstance Off
#UseHook true

#Include Core.ahk
#Include Translations.ahk
#Include App.ahk

if HasArgument("--self-test") {
    RunApplicationSelfTest()
    ExitApp(0)
}

if HasArgument("--export-default") {
    exportPath := ArgumentValue("--export-default")
    exportLanguage := ArgumentValue("--language", DetectSystemLanguage())
    if (exportPath = "") {
        WriteConsole("Missing path after --export-default`n", true)
        ExitApp(2)
    }
    SaveConfigFile(CreateDefaultConfig(exportLanguage), exportPath)
    ExitApp(0)
}

if HasArgument("--ui-smoke") {
    RunUiSmokeTest()
    ExitApp(0)
}

StartApplication()
