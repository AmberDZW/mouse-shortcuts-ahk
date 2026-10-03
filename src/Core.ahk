#Requires AutoHotkey v2.0

GetMappingDefinitions() {
    static definitions := [
        {id: "middle", label: "middle", key: "MButton", action: "voice", group: "primary"},
        {id: "side_up", label: "side_up", key: "XButton2", action: "enter", group: "primary"},
        {id: "side_down", label: "side_down", key: "XButton1", action: "backspace", group: "primary"},
        {id: "wheel_up", label: "wheel_up", key: "WheelUp", action: "disabled", group: "wheel"},
        {id: "wheel_down", label: "wheel_down", key: "WheelDown", action: "disabled", group: "wheel"},
        {id: "wheel_left", label: "wheel_left", key: "WheelLeft", action: "disabled", group: "wheel"},
        {id: "wheel_right", label: "wheel_right", key: "WheelRight", action: "disabled", group: "wheel"},
        {id: "browser_back", label: "browser_back", key: "Browser_Back", action: "disabled", group: "extended"},
        {id: "browser_forward", label: "browser_forward", key: "Browser_Forward", action: "disabled", group: "extended"},
        {id: "vendor_1", label: "vendor_1", key: "Launch_App1", action: "disabled", group: "extended"},
        {id: "vendor_2", label: "vendor_2", key: "Launch_App2", action: "disabled", group: "extended"},
        {id: "extra_1", label: "extra_1", key: "F13", action: "disabled", group: "extended"},
        {id: "extra_2", label: "extra_2", key: "F14", action: "disabled", group: "extended"},
        {id: "extra_3", label: "extra_3", key: "F15", action: "disabled", group: "extended"},
        {id: "extra_4", label: "extra_4", key: "F16", action: "disabled", group: "extended"}
    ]
    return definitions
}

GetSupportedKeys() {
    return [
        "MButton", "XButton1", "XButton2",
        "WheelUp", "WheelDown", "WheelLeft", "WheelRight",
        "Browser_Back", "Browser_Forward", "Browser_Home", "Browser_Search",
        "Browser_Favorites", "Browser_Refresh", "Browser_Stop",
        "Launch_App1", "Launch_App2", "Launch_Mail", "Launch_Media",
        "Media_Play_Pause", "Media_Next", "Media_Prev", "Media_Stop",
        "Volume_Mute", "Volume_Down", "Volume_Up",
        "F13", "F14", "F15", "F16", "F17", "F18",
        "F19", "F20", "F21", "F22", "F23", "F24"
    ]
}

GetActionIds() {
    return [
        "disabled", "voice", "enter", "backspace", "delete", "copy", "paste",
        "cut", "select_all", "undo", "redo", "escape", "tab", "space", "home",
        "end", "page_up", "page_down", "browser_back", "browser_forward", "desktop",
        "lock", "snip", "volume_mute", "volume_down", "volume_up", "media_play_pause",
        "media_next", "media_prev", "media_stop"
    ]
}

GetActionSendValue(actionId) {
    static values := Map(
        "voice", "#h",
        "enter", "{Enter}",
        "backspace", "{Backspace}",
        "delete", "{Delete}",
        "copy", "^c",
        "paste", "^v",
        "cut", "^x",
        "select_all", "^a",
        "undo", "^z",
        "redo", "^y",
        "escape", "{Esc}",
        "tab", "{Tab}",
        "space", "{Space}",
        "home", "{Home}",
        "end", "{End}",
        "page_up", "{PgUp}",
        "page_down", "{PgDn}",
        "browser_back", "!{Left}",
        "browser_forward", "!{Right}",
        "desktop", "#d",
        "lock", "#l",
        "snip", "#+s",
        "volume_mute", "{Volume_Mute}",
        "volume_down", "{Volume_Down}",
        "volume_up", "{Volume_Up}",
        "media_play_pause", "{Media_Play_Pause}",
        "media_next", "{Media_Next}",
        "media_prev", "{Media_Prev}",
        "media_stop", "{Media_Stop}"
    )
    return values.Has(actionId) ? values[actionId] : ""
}

CreateDefaultConfig(language := "en-US") {
    mappings := Map()
    for definition in GetMappingDefinitions() {
        mappings[definition.id] := {key: definition.key, action: definition.action}
    }

    snippets := []
    Loop 5 {
        snippets.Push({hotkey: "", text: ""})
    }

    return {
        schema: 1,
        language: NormalizeLanguage(language),
        autostart: false,
        leftButtonVoiceEnabled: true,
        leftButtonVoiceHoldMs: 2000,
        mappings: mappings,
        snippets: snippets
    }
}

GetLeftButtonVoiceHoldOptions() {
    return [
        {milliseconds: 500, label: "0.5"},
        {milliseconds: 1000, label: "1"},
        {milliseconds: 1500, label: "1.5"},
        {milliseconds: 2000, label: "2"},
        {milliseconds: 2500, label: "2.5"},
        {milliseconds: 3000, label: "3"},
        {milliseconds: 3500, label: "3.5"},
        {milliseconds: 4000, label: "4"},
        {milliseconds: 4500, label: "4.5"},
        {milliseconds: 5000, label: "5"}
    ]
}

IsSupportedLeftButtonVoiceHoldDuration(milliseconds) {
    for option in GetLeftButtonVoiceHoldOptions() {
        if (option.milliseconds = milliseconds) {
            return true
        }
    }
    return false
}

NormalizeLanguage(value) {
    normalized := StrLower(Trim(value))
    if (normalized = "zh" || normalized = "zh-cn" || normalized = "zh_cn"
        || normalized = "chinese" || normalized = "中文") {
        return "zh-CN"
    }
    return "en-US"
}

IsDisabled(value) {
    normalized := StrLower(Trim(value))
    return normalized = "" || normalized = "disabled" || normalized = "off"
}

CanonicalTrigger(value) {
    value := StrReplace(Trim(value), " ")
    if (value = "") {
        return ""
    }

    modifiers := ""
    for marker in ["^", "!", "+", "#"] {
        if InStr(value, marker) {
            modifiers .= marker
        }
    }
    key := RegExReplace(value, "[\^!+#~*$<>]")
    return modifiers StrLower(key)
}

ModifierPrefixFromState(value) {
    prefix := ""
    for marker in ["^", "!", "+", "#"] {
        if InStr(value, marker) {
            prefix .= marker
        }
    }
    return prefix
}

ValidateConfig(config) {
    errors := []
    warnings := []
    used := Map()
    actions := Map()
    for actionId in GetActionIds() {
        actions[actionId] := true
    }

    for definition in GetMappingDefinitions() {
        if !config.mappings.Has(definition.id) {
            errors.Push({code: "missing_mapping", value: definition.id})
            continue
        }

        mapping := config.mappings[definition.id]
        keyName := Trim(mapping.key)
        actionId := StrLower(Trim(mapping.action))
        if (keyName = "") {
            errors.Push({code: "missing_key", value: definition.id})
            continue
        }
        if !actions.Has(actionId) {
            errors.Push({code: "unknown_action", value: actionId})
            continue
        }
        if IsDisabled(actionId) {
            continue
        }

        canonical := CanonicalTrigger(keyName)
        if used.Has(canonical) {
            errors.Push({code: "duplicate_trigger", value: keyName})
        } else {
            used[canonical] := definition.id
        }
    }

    if !IsSupportedLeftButtonVoiceHoldDuration(config.leftButtonVoiceHoldMs) {
        errors.Push({code: "invalid_left_hold_duration", value: config.leftButtonVoiceHoldMs})
    }

    if (config.snippets.Length < 5) {
        errors.Push({code: "missing_snippets", value: config.snippets.Length})
    }
    for index, snippet in config.snippets {
        hotkeyName := Trim(snippet.hotkey)
        if IsDisabled(hotkeyName) {
            continue
        }
        if (Trim(snippet.text) = "") {
            errors.Push({code: "empty_snippet", value: index})
        }

        canonical := CanonicalTrigger(hotkeyName)
        if used.Has(canonical) {
            errors.Push({code: "duplicate_trigger", value: hotkeyName})
        } else {
            used[canonical] := "snippet_" index
        }
    }

    return {errors: errors, warnings: warnings}
}

EncodeText(text) {
    if (text = "") {
        return ""
    }

    byteCount := StrPut(text, "UTF-8") - 1
    bytes := Buffer(byteCount + 1, 0)
    StrPut(text, bytes, "UTF-8")
    flags := 0x40000001
    charCount := 0
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", bytes.Ptr, "UInt", byteCount,
        "UInt", flags, "Ptr", 0, "UIntP", &charCount) {
        throw OSError()
    }
    output := Buffer(charCount * 2, 0)
    if !DllCall("Crypt32\CryptBinaryToStringW", "Ptr", bytes.Ptr, "UInt", byteCount,
        "UInt", flags, "Ptr", output.Ptr, "UIntP", &charCount) {
        throw OSError()
    }
    return StrGet(output, "UTF-16")
}

DecodeText(value) {
    if (value = "") {
        return ""
    }

    byteCount := 0
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", value, "UInt", 0, "UInt", 0x1,
        "Ptr", 0, "UIntP", &byteCount, "Ptr", 0, "Ptr", 0) {
        throw OSError()
    }
    bytes := Buffer(byteCount + 1, 0)
    if !DllCall("Crypt32\CryptStringToBinaryW", "Str", value, "UInt", 0, "UInt", 0x1,
        "Ptr", bytes.Ptr, "UIntP", &byteCount, "Ptr", 0, "Ptr", 0) {
        throw OSError()
    }
    return StrGet(bytes, byteCount, "UTF-8")
}

SaveConfigFile(config, filePath) {
    validation := ValidateConfig(config)
    if validation.errors.Length {
        throw Error("config_invalid")
    }

    SplitPath(filePath, , &directory)
    if (directory != "") {
        DirCreate(directory)
    }

    tempPath := filePath ".tmp"
    if FileExist(tempPath) {
        FileDelete(tempPath)
    }
    FileAppend("", tempPath, "UTF-16")

    IniWrite(1, tempPath, "Meta", "schema")
    IniWrite(NormalizeLanguage(config.language), tempPath, "Meta", "language")
    IniWrite(config.autostart ? 1 : 0, tempPath, "Meta", "autostart")
    IniWrite(config.leftButtonVoiceEnabled ? 1 : 0, tempPath, "Meta", "leftButtonVoiceEnabled")
    IniWrite(config.leftButtonVoiceHoldMs, tempPath, "Meta", "leftButtonVoiceHoldMs")

    for definition in GetMappingDefinitions() {
        mapping := config.mappings[definition.id]
        IniWrite(mapping.key "|" mapping.action, tempPath, "Mappings", definition.id)
    }

    Loop 5 {
        snippet := config.snippets[A_Index]
        section := "Snippet" A_Index
        IniWrite(snippet.hotkey, tempPath, section, "hotkey")
        IniWrite(EncodeText(snippet.text), tempPath, section, "text")
    }

    if FileExist(filePath) {
        FileCopy(filePath, filePath ".bak", 1)
    }
    FileMove(tempPath, filePath, 1)
}

LoadConfigFile(filePath, fallbackLanguage := "en-US") {
    config := CreateDefaultConfig(fallbackLanguage)
    if !FileExist(filePath) {
        return config
    }

    schema := IniRead(filePath, "Meta", "schema", "")
    if (schema != "1") {
        throw Error("config_schema")
    }
    config.language := NormalizeLanguage(IniRead(filePath, "Meta", "language", config.language))
    config.autostart := IniRead(filePath, "Meta", "autostart", "0") = "1"
    leftButtonVoiceSetting := IniRead(filePath, "Meta", "leftButtonVoiceEnabled",
        config.leftButtonVoiceEnabled ? "1" : "0")
    if (leftButtonVoiceSetting != "0" && leftButtonVoiceSetting != "1") {
        throw Error("config_invalid_left_voice")
    }
    config.leftButtonVoiceEnabled := leftButtonVoiceSetting = "1"
    leftButtonVoiceHoldSetting := IniRead(filePath, "Meta", "leftButtonVoiceHoldMs",
        config.leftButtonVoiceHoldMs)
    if !RegExMatch(leftButtonVoiceHoldSetting, "^\d+$") {
        throw Error("config_invalid_left_hold_duration")
    }
    config.leftButtonVoiceHoldMs := Integer(leftButtonVoiceHoldSetting)
    if !IsSupportedLeftButtonVoiceHoldDuration(config.leftButtonVoiceHoldMs) {
        throw Error("config_invalid_left_hold_duration")
    }

    for definition in GetMappingDefinitions() {
        saved := IniRead(filePath, "Mappings", definition.id, "__MISSING__")
        if (saved = "__MISSING__") {
            throw Error("config_missing_mapping", -1, definition.id)
        }
        separator := InStr(saved, "|")
        if !separator {
            throw Error("config_invalid_mapping", -1, definition.id)
        }
        keyName := Trim(SubStr(saved, 1, separator - 1))
        actionId := StrLower(Trim(SubStr(saved, separator + 1)))
        if (keyName = "" || actionId = "") {
            throw Error("config_invalid_mapping", -1, definition.id)
        }
        config.mappings[definition.id] := {key: keyName, action: actionId}
    }

    Loop 5 {
        section := "Snippet" A_Index
        hotkeyName := IniRead(filePath, section, "hotkey", "__MISSING__")
        encoded := IniRead(filePath, section, "text", "__MISSING__")
        if (hotkeyName = "__MISSING__" || encoded = "__MISSING__") {
            throw Error("config_missing_snippet", -1, A_Index)
        }
        config.snippets[A_Index].hotkey := hotkeyName
        try config.snippets[A_Index].text := DecodeText(encoded)
        catch as error {
            throw Error("config_invalid_snippet", -1, A_Index)
        }
    }
    return config
}

FindLegacyConfigPath(applicationDirectory) {
    candidates := []
    candidates.Push(applicationDirectory "\mouse-remap.ini")
    SplitPath(applicationDirectory, , &parentDirectory)
    if (parentDirectory != "") {
        candidates.Push(parentDirectory "\mouse-remap.ini")
        Loop Files, parentDirectory "\MouseShortcuts*", "D" {
            if (A_LoopFileFullPath != applicationDirectory) {
                candidates.Push(A_LoopFileFullPath "\mouse-remap.ini")
            }
        }
    }

    newestPath := ""
    newestTime := ""
    for candidate in candidates {
        if !FileExist(candidate) {
            continue
        }
        modified := FileGetTime(candidate, "M")
        if (newestPath = "" || modified > newestTime) {
            newestPath := candidate
            newestTime := modified
        }
    }
    return newestPath
}

LegacyConfigPathFromCommandLine(commandLine) {
    scriptNames := "(?:mouse-remap|mouse-shortcuts-panel)\.ahk"
    pattern := 'i)(?:"([^"\r\n]*\\' scriptNames ')"|([^\s"\r\n]*\\' scriptNames '))'
    if !RegExMatch(commandLine, pattern, &match) {
        return ""
    }
    scriptPath := match[1] != "" ? match[1] : match[2]
    SplitPath(scriptPath, , &directory)
    return directory != "" ? directory "\mouse-remap.ini" : ""
}

LoadLegacyConfigFile(filePath, fallbackLanguage := "en-US", autostart := false) {
    config := CreateDefaultConfig(fallbackLanguage)
    config.autostart := autostart
    if !FileExist(filePath) {
        return config
    }

    config.language := NormalizeLanguage(IniRead(filePath, "Settings", "language", config.language))
    for definition in GetMappingDefinitions() {
        legacyId := definition.id
        if (legacyId = "vendor_1") {
            legacyId := "launch_app1"
        } else if (legacyId = "vendor_2") {
            legacyId := "launch_app2"
        }
        keyName := IniRead(filePath, "Slots", legacyId, definition.key)
        actionId := IniRead(filePath, "Mappings", keyName, "disabled")
        config.mappings[definition.id] := {key: keyName, action: actionId}
    }

    Loop 5 {
        name := "snippet_" A_Index
        hotkeyName := IniRead(filePath, "TextHotkeys", name, "")
        if IsDisabled(hotkeyName) {
            hotkeyName := ""
        }
        relativePath := IniRead(filePath, "Snippets", name, "")
        snippetPath := relativePath
        if (relativePath != "" && !RegExMatch(relativePath, "i)^(?:[A-Z]:\\|\\\\)")) {
            SplitPath(filePath, , &legacyDirectory)
            snippetPath := legacyDirectory "\" relativePath
        }
        snippetText := FileExist(snippetPath) ? FileRead(snippetPath, "UTF-8") : ""
        config.snippets[A_Index] := {hotkey: hotkeyName, text: snippetText}
    }
    return config
}
