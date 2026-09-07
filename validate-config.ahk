#Requires AutoHotkey v2.0

configFile := A_ScriptDir "\mouse-remap.ini"

try {
    ValidateConfig(configFile)
    ExitApp(0)
} catch {
    ExitApp(1)
}

ValidateConfig(filePath) {
    mappings := LoadSection(filePath, "Mappings")
    textHotkeys := LoadSection(filePath, "TextHotkeys")
    actions := LoadSection(filePath, "Actions")
    snippets := LoadSection(filePath, "Snippets")
    if (mappings.Count = 0 && textHotkeys.Count = 0) {
        throw Error("Missing [Mappings] or [TextHotkeys] entries in " filePath)
    }
    if (actions.Count = 0) {
        throw Error("Missing [Actions] entries in " filePath)
    }

    activeCount := 0
    for keyName, actionName in mappings {
        if (keyName = "" || actionName = "" || IsDisabled(actionName)) {
            continue
        }
        activeCount += 1
    }
    for snippetName, hotkeyName in textHotkeys {
        if (snippetName = "" || hotkeyName = "" || IsDisabled(hotkeyName)) {
            continue
        }
        if !snippets.Has(snippetName) {
            throw Error("Missing [Snippets] entry for " snippetName)
        }
        activeCount += 1
    }
    if (activeCount = 0) {
        throw Error("No active mappings or text hotkeys in " filePath)
    }
}

IsDisabled(actionName) {
    normalized := StrLower(Trim(actionName))
    return normalized = "disabled" || normalized = "disable" || normalized = "none" || normalized = "off"
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
