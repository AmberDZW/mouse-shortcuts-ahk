#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

configFile := A_ScriptDir "\mouse-remap.ini"

if (A_Args.Length > 0 && A_Args[1] = "--check") {
    ValidateConfig(configFile)
    FileAppend("mouse-remap config OK`n", "*", "UTF-8")
    ExitApp(0)
}

mappings := LoadSection(configFile, "Mappings")
actions := LoadSection(configFile, "Actions")

if (mappings.Count = 0) {
    MsgBox("No mappings found in " configFile, "Mouse Shortcuts", "Iconx")
    ExitApp(1)
}

loaded := 0
errors := ""
for keyName, actionName in mappings {
    sendValue := actions.Has(actionName) ? actions[actionName] : actionName
    try {
        Hotkey("*" keyName, MakeSender(sendValue), "On")
        loaded += 1
    } catch as err {
        errors .= keyName " -> " actionName ": " err.Message "`n"
    }
}

if (loaded = 0) {
    MsgBox("No hotkeys could be registered.`n`n" errors, "Mouse Shortcuts", "Iconx")
    ExitApp(1)
}

if (errors != "") {
    MsgBox("Some mappings were skipped:`n`n" errors, "Mouse Shortcuts", "Icon!")
}

TrayTip("Mouse Shortcuts", "Loaded " loaded " mouse mappings.", 2)
Persistent()

MakeSender(sendValue) {
    return (*) => SendInput(sendValue)
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
