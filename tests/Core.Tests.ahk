#Requires AutoHotkey v2.0
#Include ..\src\Core.ahk

failures := []

AssertEqual(actual, expected, message) {
    global failures
    if (actual != expected) {
        failures.Push(message " (expected=" expected ", actual=" actual ")")
    }
}

AssertTrue(value, message) {
    global failures
    if !value {
        failures.Push(message)
    }
}

AssertThrows(callback, message) {
    global failures
    threw := false
    try callback.Call()
    catch {
        threw := true
    }
    if !threw {
        failures.Push(message)
    }
}

TestDefaults() {
    config := CreateDefaultConfig("zh-CN")
    AssertEqual(config.language, "zh-CN", "Default language should be Chinese when requested")
    AssertEqual(config.mappings["middle"].key, "MButton", "Middle button key")
    AssertEqual(config.mappings["middle"].action, "voice", "Middle button action")
    AssertEqual(config.mappings["side_up"].key, "XButton2", "Upper side button key")
    AssertEqual(config.mappings["side_up"].action, "enter", "Upper side button action")
    AssertEqual(config.mappings["side_down"].key, "XButton1", "Lower side button key")
    AssertEqual(config.mappings["side_down"].action, "backspace", "Lower side button action")
    AssertEqual(config.mappings["wheel_up"].action, "disabled", "Unused buttons stay visible but disabled")
    AssertEqual(config.mappings["right"].key, "RButton", "Right button is the hold-to-talk trigger")
    AssertEqual(config.mappings["right"].action, "disabled", "Short right clicks remain native")
    AssertEqual(config.mappings["right"].holdAction, "voice", "Right holds start voice typing")
    AssertEqual(config.mappings["right"].holdMs, 2000, "Right hold delay defaults to two seconds")
    AssertTrue(!SupportsButtonHold("LButton"), "Left selection must not acquire a hold mapping")
    AssertEqual(config.snippets.Length, 5, "Five text shortcut slots")
}

TestLanguageNormalization() {
    AssertEqual(NormalizeLanguage("zh_cn"), "zh-CN", "Chinese language normalization")
    AssertEqual(NormalizeLanguage("English"), "en-US", "English language normalization")
    AssertEqual(NormalizeLanguage("unknown"), "en-US", "Unknown language fallback")
}

TestTextCodec() {
    original := "第一行 Chinese + English`r`nSecond line = value | symbols`r`n第三行"
    encoded := EncodeText(original)
    AssertTrue(encoded != original, "Encoded text should not expose raw multiline content")
    AssertEqual(DecodeText(encoded), original, "Unicode multiline text round trip")
}

TestConflictValidation() {
    config := CreateDefaultConfig("en-US")
    config.mappings["wheel_up"].key := "MButton"
    config.mappings["wheel_up"].action := "copy"
    result := ValidateConfig(config)
    AssertTrue(result.errors.Length > 0, "Duplicate active mouse buttons should be rejected")

    config := CreateDefaultConfig("en-US")
    config.snippets[1].hotkey := "MButton"
    config.snippets[1].text := "Text"
    result := ValidateConfig(config)
    AssertTrue(result.errors.Length > 0, "Text shortcut should conflict with an active mouse mapping")

    config := CreateDefaultConfig("en-US")
    config.snippets[1].hotkey := "^!1"
    config.snippets[1].text := ""
    result := ValidateConfig(config)
    AssertTrue(result.errors.Length > 0, "Enabled text shortcut requires content")

    config := CreateDefaultConfig("en-US")
    config.mappings["right"].holdMs := 600
    result := ValidateConfig(config)
    AssertTrue(result.errors.Length > 0, "Unsupported hold durations should be rejected")
    config := CreateDefaultConfig("en-US")
    config.mappings["wheel_up"].holdAction := "copy"
    AssertTrue(ValidateConfig(config).errors.Length > 0, "Wheel pulses cannot be held")
    config := CreateDefaultConfig("en-US")
    config.mappings["side_up"].key := "RButton"
    AssertTrue(ValidateConfig(config).errors.Length > 0, "Hold-only triggers must participate in duplicate detection")
}

TestPersistence() {
    path := A_Temp "\MouseShortcuts-Core-Test-" A_TickCount ".ini"
    config := CreateDefaultConfig("en-US")
    config.autostart := true
    config.mappings["right"].holdAction := "disabled"
    config.mappings["right"].holdMs := 1500
    config.mappings["extra_1"].key := "F17"
    config.mappings["extra_1"].action := "copy"
    config.mappings["extra_1"].holdAction := "paste"
    config.mappings["extra_1"].holdMs := 500
    config.snippets[1].hotkey := "^!1"
    config.snippets[1].text := "你好`r`nHello"

    SaveConfigFile(config, path)
    loaded := LoadConfigFile(path, "zh-CN")
    AssertEqual(loaded.language, "en-US", "Saved language should load")
    AssertTrue(loaded.autostart, "Autostart should round trip")
    AssertEqual(loaded.mappings["right"].holdAction, "disabled", "Hold toggle should round trip")
    AssertEqual(loaded.mappings["right"].holdMs, 1500, "Hold duration should round trip")
    AssertEqual(loaded.mappings["extra_1"].key, "F17", "Custom key should round trip")
    AssertEqual(loaded.mappings["extra_1"].action, "copy", "Custom action should round trip")
    AssertEqual(loaded.mappings["extra_1"].holdAction, "paste", "Independent long action should round trip")
    AssertEqual(loaded.mappings["extra_1"].holdMs, 500, "Per-button hold duration should round trip")
    AssertEqual(loaded.snippets[1].hotkey, "^!1", "Text hotkey should round trip")
    AssertEqual(loaded.snippets[1].text, "你好`r`nHello", "Text content should round trip")
    FileDelete(path)
}

TestOldHoldMigration() {
    path := A_Temp "\MouseShortcuts-Old-Config-Test-" A_TickCount ".msconfig"
    SaveConfigFile(CreateDefaultConfig("en-US"), path)
    IniDelete(path, "Mappings", "right")
    IniDelete(path, "Holds")
    IniWrite(1, path, "Meta", "leftButtonVoiceEnabled")
    IniWrite(500, path, "Meta", "leftButtonVoiceHoldMs")
    loaded := LoadConfigFile(path, "en-US")
    AssertEqual(loaded.mappings["right"].holdAction, "voice", "Old left voice setting migrates to right")
    AssertEqual(loaded.mappings["right"].holdMs, 500, "Migration retains the user's hold duration")
    AssertEqual(loaded.mappings["side_up"].holdAction, "disabled", "Old click mappings do not gain extra holds")
    IniWrite(0, path, "Meta", "leftButtonVoiceEnabled")
    AssertEqual(LoadConfigFile(path).mappings["right"].holdAction, "disabled", "Disabled voice remains disabled during migration")
    FileDelete(path)
}

TestRejectsInvalidImports() {
    path := A_Temp "\MouseShortcuts-Invalid-Test-" A_TickCount ".msconfig"
    FileAppend("This is not a Mouse Shortcuts configuration", path, "UTF-8")
    AssertThrows(() => LoadConfigFile(path, "zh-CN"), "Random files must not import as default settings")
    FileDelete(path)
}

TestLegacyDiscovery() {
    root := A_Temp "\MouseShortcuts-Legacy-Test-" A_TickCount
    oldDirectory := root "\MouseShortcuts-0.7.0"
    newDirectory := root "\MouseShortcuts-1.0.0"
    DirCreate(oldDirectory)
    DirCreate(newDirectory)
    legacyPath := oldDirectory "\mouse-remap.ini"
    FileAppend("[Settings]`r`nlanguage=zh-CN`r`n", legacyPath, "UTF-8")
    AssertEqual(FindLegacyConfigPath(newDirectory), legacyPath, "Sibling 0.7 configuration should be discovered")
    DirDelete(root, true)
}

TestLegacyLoad() {
    root := A_Temp "\MouseShortcuts-Legacy-Load-Test-" A_TickCount
    snippetDirectory := root "\snippets"
    DirCreate(snippetDirectory)
    legacyPath := root "\mouse-remap.ini"
    snippetText := "你好，旧配置`r`nHello from 0.7"
    legacyContent := "; Mouse Shortcuts config`r`n[Settings]`r`nlanguage=zh-CN`r`n"
        . "[Slots]`r`nmiddle=MButton`r`nside_up=XButton2`r`nside_down=XButton1`r`n"
        . "launch_app1=Launch_App1`r`nextra_1=F17`r`n"
        . "[Mappings]`r`nMButton=voice`r`nXButton2=enter`r`nXButton1=backspace`r`n"
        . "Launch_App1=paste`r`nF17=copy`r`n"
        . "[TextHotkeys]`r`nsnippet_1=^!1`r`n"
        . "[Snippets]`r`nsnippet_1=snippets\snippet_1.txt`r`n"
    FileAppend(legacyContent, legacyPath, "UTF-8")
    FileAppend(snippetText, snippetDirectory "\snippet_1.txt", "UTF-8")

    loaded := LoadLegacyConfigFile(legacyPath, "en-US", true)
    AssertEqual(loaded.language, "zh-CN", "Legacy language should migrate")
    AssertEqual(loaded.mappings["middle"].action, "voice", "Legacy middle-button action should migrate")
    AssertEqual(loaded.mappings["vendor_1"].key, "Launch_App1", "Legacy vendor slot alias should migrate")
    AssertEqual(loaded.mappings["vendor_1"].action, "paste", "Legacy vendor action should migrate")
    AssertEqual(loaded.mappings["extra_1"].key, "F17", "Legacy custom key should migrate")
    AssertEqual(loaded.snippets[1].hotkey, "^!1", "Legacy text hotkey should migrate")
    AssertEqual(loaded.snippets[1].text, snippetText, "Legacy Unicode multiline text should migrate")
    AssertTrue(loaded.autostart, "Manual legacy import should preserve the current autostart choice")
    AssertEqual(loaded.mappings["right"].holdAction, "voice", "Legacy config defaults to right-button voice")
    AssertEqual(loaded.mappings["right"].holdMs, 2000, "Legacy config defaults to two seconds")
    AssertEqual(ValidateConfig(loaded).errors.Length, 0, "Migrated legacy configuration should validate")
    DirDelete(root, true)
}

TestModifierNormalization() {
    AssertEqual(ModifierPrefixFromState("<^>!+"), "^!+", "Captured modifiers should keep Ctrl Alt and Shift")
    AssertEqual(ModifierPrefixFromState(">#<^"), "^#", "Captured modifier order should be stable")
}

TestLegacyCommandLineParsing() {
    commandLine := '"C:\Program Files\AutoHotkey\AutoHotkey64.exe" /ErrorStdOut "F:\Old Folder\mouse-remap.ahk"'
    AssertEqual(LegacyConfigPathFromCommandLine(commandLine), "F:\Old Folder\mouse-remap.ini", "Running 0.7 command line should reveal its config")
    panelCommand := '"C:\AutoHotkey64.exe" "D:\Portable Apps\MouseShortcuts\mouse-shortcuts-panel.ahk"'
    AssertEqual(LegacyConfigPathFromCommandLine(panelCommand), "D:\Portable Apps\MouseShortcuts\mouse-remap.ini", "Open 0.7 panel should reveal its config")
    AssertEqual(LegacyConfigPathFromCommandLine("unrelated.exe"), "", "Unrelated processes should be ignored")
}

TestDefaults()
TestLanguageNormalization()
TestTextCodec()
TestConflictValidation()
TestPersistence()
TestOldHoldMigration()
TestRejectsInvalidImports()
TestLegacyDiscovery()
TestLegacyLoad()
TestModifierNormalization()
TestLegacyCommandLineParsing()

if failures.Length {
    for failure in failures {
        FileAppend("FAIL: " failure "`n", "**", "UTF-8")
    }
    ExitApp(1)
}

FileAppend("PASS: Core.Tests (" 11 " groups)`n", "*", "UTF-8")
ExitApp(0)
