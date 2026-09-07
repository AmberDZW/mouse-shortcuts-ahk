#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

configFile := A_ScriptDir "\mouse-remap.ini"

if (A_Args.Length > 0 && A_Args[1] = "--check") {
    ValidateConfig(configFile)
    ExitApp(0)
}

mappings := LoadSection(configFile, "Mappings")
actions := LoadSection(configFile, "Actions")
textHotkeys := LoadSection(configFile, "TextHotkeys")
snippets := LoadSection(configFile, "Snippets")

if (mappings.Count = 0 && textHotkeys.Count = 0) {
    MsgBox("No mappings or text hotkeys found in " configFile, "Mouse Shortcuts", "Iconx")
    ExitApp(1)
}

loaded := 0
errors := ""
for keyName, actionName in mappings {
    if IsDisabled(actionName) {
        continue
    }
    sendValue := actions.Has(actionName) ? actions[actionName] : actionName
    if (sendValue = "") {
        continue
    }
    try {
        Hotkey("*" keyName, MakeSender(sendValue), "On")
        loaded += 1
    } catch as err {
        errors .= keyName " -> " actionName ": " err.Message "`n"
    }
}

for snippetName, hotkeyName in textHotkeys {
    if IsDisabled(hotkeyName) {
        continue
    }
    if !snippets.Has(snippetName) {
        errors .= hotkeyName " -> " snippetName ": snippet path not found`n"
        continue
    }
    snippetPath := ResolvePath(snippets[snippetName])
    try {
        Hotkey("*" hotkeyName, PasteTextFile.Bind(snippetPath), "On")
        loaded += 1
    } catch as err {
        errors .= hotkeyName " -> " snippetName ": " err.Message "`n"
    }
}

if (loaded = 0) {
    MsgBox("No mouse mappings or text shortcuts could be registered.`n`n" errors, "Mouse Shortcuts", "Iconx")
    ExitApp(1)
}

if (errors != "") {
    MsgBox("Some mappings were skipped:`n`n" errors, "Mouse Shortcuts", "Icon!")
}

ConfigureTrayMenu()
TrayTip("Mouse Shortcuts", "Loaded " loaded " mouse mappings.", 2)
Persistent()

MakeSender(sendValue) {
    return (*) => SendInput(sendValue)
}

PasteTextFile(filePath, *) {
    if !FileExist(filePath) {
        ToolTip("Snippet not found: " filePath)
        SetTimer(() => ToolTip(), -1200)
        return
    }

    text := FileRead(filePath, "UTF-8")
    PasteText(text)
}

PasteText(text) {
    if (text = "") {
        return
    }

    savedClipboard := ClipboardAll()
    A_Clipboard := ""
    A_Clipboard := text
    if ClipWait(1) {
        Send("^v")
        Sleep(120)
    }
    A_Clipboard := savedClipboard
}

ResolvePath(pathValue) {
    if (InStr(pathValue, ":\") || SubStr(pathValue, 1, 2) = "\\") {
        return pathValue
    }
    return A_ScriptDir "\" pathValue
}

IsDisabled(actionName) {
    normalized := StrLower(Trim(actionName))
    return normalized = "disabled" || normalized = "disable" || normalized = "none" || normalized = "off"
}

ConfigureTrayMenu() {
    A_IconTip := "Mouse Shortcuts"
    A_TrayMenu.Delete()
    A_TrayMenu.Add("Open config", OpenConfig)
    A_TrayMenu.Add("Open folder", OpenFolder)
    A_TrayMenu.Add()
    A_TrayMenu.Add("Reload config", ReloadConfig)
    A_TrayMenu.Add("Exit", ExitTool)
}

OpenConfig(*) {
    global configFile
    Run('notepad.exe "' configFile '"')
}

OpenFolder(*) {
    Run('explorer.exe "' A_ScriptDir '"')
}

ReloadConfig(*) {
    Reload()
}

ExitTool(*) {
    ExitApp(0)
}

ValidateConfig(filePath) {
    mappings := LoadSection(filePath, "Mappings")
    actions := LoadSection(filePath, "Actions")
    if (mappings.Count = 0) {
        throw Error("Missing [Mappings] entries in " filePath)
    }
    if (actions.Count = 0) {
        throw Error("Missing [Actions] entries in " filePath)
    }
}

LoadSection(filePath, sectionName) {
    if (!FileExist(filePath)) {
        throw Error("Config file not found: " filePath)
    }

    result := Map()
    currentSection := ""

    Loop Read, filePath, "UTF-8" {
        line := Trim(A_LoopReadLine)
        if (line = "" || SubStr(line, 1, 1) = ";" || SubStr(line, 1, 1) = "#") {
            continue
        }

        if (RegExMatch(line, "^\[(.+)\]$", &match)) {
            currentSection := Trim(match[1])
            continue
        }

        if (currentSection != sectionName) {
            continue
        }

        pos := InStr(line, "=")
        if (!pos) {
            continue
        }

        key := Trim(SubStr(line, 1, pos - 1))
        value := Trim(SubStr(line, pos + 1))
        if (key != "" && value != "") {
            result[key] := value
        }
    }

    return result
}
