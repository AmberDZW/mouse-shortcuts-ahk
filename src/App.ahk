#Requires AutoHotkey v2.0

#Include %A_LineFile%\..\LeftButtonVoice.ahk

global gVersion := "1.0.3"
global gLanguage := DetectSystemLanguage()
global gDataDir := ""
global gConfigPath := ""
global gActiveConfig := CreateDefaultConfig(gLanguage)
global gActiveHotkeys := []
global gState := "stopped"
global gStateDetail := ""
global gPaused := false
global gStartupSyncFailed := false
global gTestMode := false
global gSettingsGui := 0
global gTabs := 0
global gStatusText := 0
global gMappingRows := []
global gMappingGroupSelector := 0
global gLeftButtonVoiceCheck := 0
global gLeftButtonVoiceHoldChoice := 0
global gSnippetRows := []
global gSnippetSelector := 0
global gLanguageChoice := 0
global gAutostartCheck := 0
global gCaptureGui := 0
global gCaptureHotkeys := []
global gCaptureInput := 0
global gCaptureActive := false
global gCaptureKind := ""
global gCaptureIndex := 0
global gCaptureHadBindings := false
global gHasShownTrayHint := false
global gLegacyProcesses := []
global gSingletonMutex := 0
global gTakeoverMessage := 0
global gShowSettingsMessage := 0

WriteConsole(message, useErrorStream := false) {
    try FileAppend(message, useErrorStream ? "**" : "*", "UTF-8")
}

HasArgument(name) {
    for argument in A_Args {
        if (argument = name) {
            return true
        }
    }
    return false
}

ArgumentValue(name, fallback := "") {
    for index, argument in A_Args {
        if (argument = name && index < A_Args.Length) {
            return A_Args[index + 1]
        }
    }
    return fallback
}

DetectSystemLanguage() {
    return InStr(",0804,0404,0c04,1004,", "," A_Language ",") ? "zh-CN" : "en-US"
}

RunApplicationSelfTest() {
    path := A_Temp "\MouseShortcuts-SelfTest-" A_TickCount ".msconfig"
    try {
        config := CreateDefaultConfig("zh-CN")
        validation := ValidateConfig(config)
        if validation.errors.Length {
            throw Error("Default configuration is invalid")
        }
        SaveConfigFile(config, path)
        loaded := LoadConfigFile(path, "en-US")
        if (loaded.language != "zh-CN" || loaded.mappings["middle"].action != "voice"
            || !loaded.leftButtonVoiceEnabled || loaded.leftButtonVoiceHoldMs != 2000
            || loaded.snippets.Length != 5) {
            throw Error("Configuration round trip failed")
        }
        if (FormatHotkeyForDisplay("^!1") != "Ctrl+Alt+1") {
            throw Error("Shortcut display formatting failed")
        }
        WriteConsole("PASS: MouseShortcuts self-test`n")
    } catch as error {
        WriteConsole("FAIL: MouseShortcuts self-test: " error.Message "`n", true)
        ExitApp(1)
    } finally {
        if FileExist(path) {
            FileDelete(path)
        }
    }
}

RunUiSmokeTest() {
    global gTestMode, gLanguage, gActiveConfig, gState, gSettingsGui
    global gMappingRows, gLeftButtonVoiceCheck, gLeftButtonVoiceHoldChoice, gSnippetRows
    global gStartupSyncFailed, gActiveHotkeys, gPaused
    try {
        gTestMode := true
        gLanguage := "zh-CN"
        gActiveConfig := CreateDefaultConfig(gLanguage)
        gState := "stopped"
        BuildSettingsGui(gActiveConfig)
        if (gMappingRows.Length != 15 || gSnippetRows.Length != 5 || !gSettingsGui.Hwnd
            || !IsObject(gLeftButtonVoiceCheck) || !gLeftButtonVoiceCheck.Hwnd
            || gLeftButtonVoiceCheck.Value != 1 || !IsObject(gLeftButtonVoiceHoldChoice)
            || !gLeftButtonVoiceHoldChoice.Hwnd || gLeftButtonVoiceHoldChoice.Value != 4) {
            throw Error("Unexpected settings control count")
        }
        gLeftButtonVoiceCheck.Value := 0
        if CollectConfigFromGui().leftButtonVoiceEnabled {
            throw Error("Left-button voice setting was not collected when unchecked")
        }
        gLeftButtonVoiceCheck.Value := 1
        gLeftButtonVoiceHoldChoice.Choose(3)
        if (CollectConfigFromGui().leftButtonVoiceHoldMs != 1500) {
            throw Error("Left-button hold duration was not collected from the selected value")
        }
        gLeftButtonVoiceHoldChoice.Choose(4)
        for control in gSnippetRows[1].controls {
            if !control.Visible {
                throw Error("First text shortcut controls are hidden")
            }
        }
        for control in gSnippetRows[2].controls {
            if control.Visible {
                throw Error("Inactive text shortcut controls are visible")
            }
        }
        gStartupSyncFailed := true
        gActiveHotkeys := ["*MButton"]
        PauseTool()
        if (gState != "paused" || !gPaused) {
            throw Error("Startup warning cannot enter paused state")
        }
        ResumeTool()
        if (gState != "error" || gPaused) {
            throw Error("Startup warning was lost after resume")
        }
        gStartupSyncFailed := false
        gActiveHotkeys := []
        gSettingsGui.Destroy()
        gSettingsGui := 0
        WriteConsole("PASS: MouseShortcuts UI smoke`n")
    } catch as error {
        WriteConsole("FAIL: MouseShortcuts UI smoke: " error.Message "`n", true)
        ExitApp(1)
    }
}

StartApplication() {
    global gTestMode, gDataDir, gConfigPath, gActiveConfig, gLanguage, gState, gStateDetail
    global gLegacyProcesses, gStartupSyncFailed

    singletonResult := AcquireApplicationSingleton()
    if (singletonResult = 0) {
        ExitApp(0)
    }
    if (singletonResult < 0) {
        MsgBox(T("takeover_failed"), T("app_name"), "Iconx")
        ExitApp(3)
    }

    gTestMode := HasArgument("--test-mode")
    gDataDir := gTestMode
        ? A_Temp "\MouseShortcuts-TestMode-" ProcessExist()
        : EnvGet("LOCALAPPDATA") "\MouseShortcuts"
    gConfigPath := gDataDir "\settings.msconfig"
    DirCreate(gDataDir)
    gLegacyProcesses := gTestMode ? [] : GetLegacyMouseShortcutsProcesses()
    legacyCandidates := gLegacyProcesses.Clone()

    if !gTestMode && !FileExist(gConfigPath) && gLegacyProcesses.Length {
        if !EnsureLegacyRuntimeStopped() {
            ExitApp(4)
        }
    }

    try {
        if FileExist(gConfigPath) {
            try gActiveConfig := LoadConfigFile(gConfigPath, DetectSystemLanguage())
            catch as primaryError {
                backupPath := gConfigPath ".bak"
                if !FileExist(backupPath) {
                    throw primaryError
                }
                gActiveConfig := LoadConfigFile(backupPath, DetectSystemLanguage())
                FileCopy(backupPath, gConfigPath, 1)
            }
        } else {
            legacyPath := gTestMode ? "" : FindLegacyConfigPath(A_ScriptDir)
            if (legacyPath = "") {
                legacyPath := LegacyConfigPathFromStartupShortcut()
            }
            if (legacyPath = "") {
                for process in legacyCandidates {
                    if (process.configPath != "" && FileExist(process.configPath)) {
                        legacyPath := process.configPath
                        break
                    }
                }
            }
            gActiveConfig := (legacyPath != "")
                ? LoadLegacyConfigFile(legacyPath, DetectSystemLanguage())
                : CreateDefaultConfig(DetectSystemLanguage())
            if FileExist(LegacyStartupShortcutPath()) {
                gActiveConfig.autostart := true
            }
            SaveConfigFile(gActiveConfig, gConfigPath)
        }
        gLanguage := gActiveConfig.language
    } catch as error {
        gActiveConfig := CreateDefaultConfig(DetectSystemLanguage())
        gLanguage := gActiveConfig.language
        gState := "error"
        gStateDetail := FriendlyError(error, "config")
    }

    BuildSettingsGui(gActiveConfig)
    ConfigureTrayMenu()

    legacyReady := gTestMode || EnsureLegacyRuntimeStopped()
    if (gState != "error" && legacyReady) {
        if gTestMode {
            UpdateStatus("stopped")
        } else {
            StartSavedConfiguration()
            try SetWindowsStartup(gActiveConfig.autostart)
            catch as error {
                gStartupSyncFailed := true
                TrayTip(T("startup_failed") " " FriendlyError(error, "system"), T("app_name"), "Iconx")
                UpdateStatus("error", T("startup_failed"))
            }
        }
    } else if !legacyReady {
        UpdateStatus("error", T("legacy_declined"))
    } else {
        UpdateStatus("error", gStateDetail)
    }

    if !HasArgument("--background") || !legacyReady {
        ShowSettings()
    }
    Persistent()
}

AcquireApplicationSingleton() {
    global gSingletonMutex, gTakeoverMessage, gShowSettingsMessage
    testScope := ArgumentValue("--test-instance", "")
    scopeSuffix := testScope = "" ? "v1" : "test." RegExReplace(testScope, "[^A-Za-z0-9.-]", "_")
    mutexName := "Local\MouseShortcuts.Application.Singleton." scopeSuffix
    gTakeoverMessage := DllCall("User32\RegisterWindowMessageW",
        "Str", "MouseShortcuts.Application.Takeover." scopeSuffix, "UInt")
    gShowSettingsMessage := DllCall("User32\RegisterWindowMessageW",
        "Str", "MouseShortcuts.Application.ShowSettings." scopeSuffix, "UInt")

    handle := DllCall("Kernel32\CreateMutexW", "Ptr", 0, "Int", false,
        "Str", mutexName, "Ptr")
    if !handle {
        return -1
    }
    alreadyExists := A_LastError = 183
    if !alreadyExists {
        gSingletonMutex := handle
        OnMessage(gTakeoverMessage, HandleTakeoverMessage)
        OnMessage(gShowSettingsMessage, HandleShowSettingsMessage)
        OnExit(ReleaseApplicationSingleton)
        return 1
    }

    DllCall("Kernel32\CloseHandle", "Ptr", handle)
    if SignalSamePathInstance() {
        return 0
    }
    BroadcastTakeoverRequest()
    Loop 40 {
        Sleep(100)
        handle := DllCall("Kernel32\CreateMutexW", "Ptr", 0, "Int", false,
            "Str", mutexName, "Ptr")
        if !handle {
            continue
        }
        if (A_LastError != 183) {
            gSingletonMutex := handle
            OnMessage(gTakeoverMessage, HandleTakeoverMessage)
            OnMessage(gShowSettingsMessage, HandleShowSettingsMessage)
            OnExit(ReleaseApplicationSingleton)
            return 1
        }
        DllCall("Kernel32\CloseHandle", "Ptr", handle)
    }
    return -1
}

SignalSamePathInstance() {
    global gShowSettingsMessage
    currentPath := StrLower(A_ScriptFullPath)
    previousDetection := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    signaled := false
    try {
        for windowId in WinGetList("ahk_exe MouseShortcuts.exe") {
            try {
                if (WinGetPID("ahk_id " windowId) = ProcessExist()) {
                    continue
                }
                if (StrLower(WinGetProcessPath("ahk_id " windowId)) = currentPath) {
                    PostMessage(gShowSettingsMessage, 0, 0, , "ahk_id " windowId)
                    signaled := true
                }
            }
        }
    } finally {
        DetectHiddenWindows(previousDetection)
    }
    return signaled
}

BroadcastTakeoverRequest() {
    global gTakeoverMessage
    previousDetection := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    try {
        for windowId in WinGetList("ahk_exe MouseShortcuts.exe") {
            try {
                if (WinGetPID("ahk_id " windowId) != ProcessExist()) {
                    PostMessage(gTakeoverMessage, 0, 0, , "ahk_id " windowId)
                }
            }
        }
    } finally {
        DetectHiddenWindows(previousDetection)
    }
}

HandleTakeoverMessage(*) {
    SetTimer(ExitTool, -10)
    return 0
}

HandleShowSettingsMessage(*) {
    SetTimer(ShowSettings, -10)
    return 0
}

ReleaseApplicationSingleton(*) {
    global gSingletonMutex
    if gSingletonMutex {
        DllCall("Kernel32\CloseHandle", "Ptr", gSingletonMutex)
        gSingletonMutex := 0
    }
}

StartSavedConfiguration() {
    global gActiveConfig
    validation := ValidateConfig(gActiveConfig)
    if validation.errors.Length {
        UpdateStatus("error", DescribeValidationError(validation.errors[1]))
        return false
    }

    registration := RegisterConfigurationHotkeys(gActiveConfig)
    if !registration.ok {
        UpdateStatus("error", FriendlyError(registration.message, "hotkey"))
        return false
    }
    UpdateStatus("running")
    return true
}

RegisterConfigurationHotkeys(config) {
    global gActiveHotkeys
    registered := []
    try {
        if config.leftButtonVoiceEnabled {
            registered := RegisterLeftButtonVoice(config.leftButtonVoiceHoldMs)
        }
        for definition in GetMappingDefinitions() {
            mapping := config.mappings[definition.id]
            if IsDisabled(mapping.action) {
                continue
            }
            specification := "*" Trim(mapping.key)
            Hotkey(specification, SendConfiguredAction.Bind(mapping.action), "On")
            registered.Push(specification)
        }

        for snippet in config.snippets {
            if IsDisabled(snippet.hotkey) {
                continue
            }
            specification := "*" Trim(snippet.hotkey)
            Hotkey(specification, PasteConfiguredText.Bind(snippet.text), "On")
            registered.Push(specification)
        }
    } catch as error {
        for specification in registered {
            try Hotkey(specification, "Off")
        }
        return {ok: false, message: error.Message}
    }
    gActiveHotkeys := registered
    return {ok: true, message: ""}
}

UnregisterConfigurationHotkeys() {
    global gActiveHotkeys
    CancelLeftButtonVoice()
    for specification in gActiveHotkeys {
        try Hotkey(specification, "Off")
    }
    gActiveHotkeys := []
}

SendConfiguredAction(actionId, *) {
    sendValue := GetActionSendValue(actionId)
    if (sendValue != "") {
        SendInput(sendValue)
    }
}

PasteConfiguredText(text, *) {
    static busy := false
    if (busy || text = "") {
        return
    }
    busy := true
    savedClipboard := 0
    clipboardCaptured := false
    try {
        savedClipboard := ClipboardAll()
        clipboardCaptured := true
        A_Clipboard := ""
        A_Clipboard := text
        if !ClipWait(1) {
            throw Error(T("clipboard_busy"))
        }
        SendInput("^v")
        Sleep(150)
    } catch as error {
        TrayTip(error.Message, T("app_name"), "Iconx")
    } finally {
        try {
            if clipboardCaptured {
                A_Clipboard := savedClipboard
            }
        } catch {
            TrayTip(T("clipboard_busy"), T("app_name"), "Icon!")
        } finally {
            busy := false
        }
    }
}

TryApplyConfiguration(candidate, showSuccess := true) {
    global gActiveConfig, gConfigPath, gTestMode, gPaused, gStartupSyncFailed

    validation := ValidateConfig(candidate)
    if validation.errors.Length {
        MsgBox(T("save_failed") "`n`n" DescribeValidationError(validation.errors[1]), T("app_name"), "Iconx")
        return false
    }

    if !gTestMode && !EnsureLegacyRuntimeStopped() {
        UpdateStatus("error", T("legacy_declined"))
        return false
    }

    conflicts := FindPossibleShortcutConflicts(candidate)
    if conflicts.Length {
        lines := ""
        for conflict in conflicts {
            lines .= (lines = "" ? "" : "`n") "- " conflict
        }
        answer := MsgBox(TF("possible_conflict", lines), T("possible_conflict_title"), "YesNo Icon!")
        if (answer != "Yes") {
            return false
        }
    }

    previous := gActiveConfig
    if !gTestMode {
        UnregisterConfigurationHotkeys()
        registration := RegisterConfigurationHotkeys(candidate)
        if !registration.ok {
            RegisterConfigurationHotkeys(previous)
            if gPaused {
                Suspend(true)
            }
            MsgBox(T("save_failed") "`n`n" FriendlyError(registration.message, "hotkey"), T("app_name"), "Iconx")
            return false
        }
    }

    if !gTestMode {
        try {
            SetWindowsStartup(candidate.autostart)
        } catch as error {
            try SetWindowsStartup(previous.autostart)
            UnregisterConfigurationHotkeys()
            RegisterConfigurationHotkeys(previous)
            if gPaused {
                Suspend(true)
            }
            MsgBox(T("startup_failed") "`n`n" FriendlyError(error, "system"), T("app_name"), "Iconx")
            return false
        }
    }

    try {
        SaveConfigFile(candidate, gConfigPath)
    } catch as error {
        if !gTestMode {
            try SetWindowsStartup(previous.autostart)
            UnregisterConfigurationHotkeys()
            RegisterConfigurationHotkeys(previous)
            if gPaused {
                Suspend(true)
            }
        }
        MsgBox(T("save_failed") "`n`n" FriendlyError(error, "storage"), T("app_name"), "Iconx")
        return false
    }

    gActiveConfig := candidate
    gStartupSyncFailed := false

    UpdateStatus(gPaused ? "paused" : (gTestMode ? "stopped" : "running"))
    if showSuccess {
        SetFooterMessage(T("saved_applied"))
    }
    return true
}

FindPossibleShortcutConflicts(config) {
    conflicts := []
    seen := Map()
    common := Map(
        "#l", true, "#d", true, "#h", true, "#v", true, "+#s", true,
        "!tab", true, "^!delete", true, "^escape", true
    )

    mouseOnly := Map(
        "mbutton", true, "xbutton1", true, "xbutton2", true,
        "wheelup", true, "wheeldown", true, "wheelleft", true, "wheelright", true
    )
    for index, definition in GetMappingDefinitions() {
        mapping := config.mappings[definition.id]
        keyName := Trim(mapping.key)
        if IsDisabled(mapping.action) || mouseOnly.Has(StrLower(keyName)) {
            continue
        }
        canonical := CanonicalTrigger(keyName)
        if !CanTemporarilyRegisterHotkey(keyName, 100 + index) && !seen.Has(canonical) {
            conflicts.Push(T(definition.label) " (" keyName ")")
            seen[canonical] := true
        }
    }

    for index, snippet in config.snippets {
        hotkeyName := Trim(snippet.hotkey)
        if IsDisabled(hotkeyName) {
            continue
        }
        canonical := CanonicalTrigger(hotkeyName)
        warning := false
        if common.Has(canonical) {
            warning := true
        } else if !RegExMatch(hotkeyName, "[\^!+#]") && RegExMatch(hotkeyName, "i)^[a-z0-9]$") {
            warning := true
        } else if !CanTemporarilyRegisterHotkey(hotkeyName, index) {
            warning := true
        }
        if warning && !seen.Has(canonical) {
            conflicts.Push(FormatHotkeyForDisplay(hotkeyName))
            seen[canonical] := true
        }
    }
    return conflicts
}

CanTemporarilyRegisterHotkey(hotkeyName, index) {
    modifiers := 0
    if InStr(hotkeyName, "!")
        modifiers |= 0x1
    if InStr(hotkeyName, "^")
        modifiers |= 0x2
    if InStr(hotkeyName, "+")
        modifiers |= 0x4
    if InStr(hotkeyName, "#")
        modifiers |= 0x8
    keyName := RegExReplace(hotkeyName, "[\^!+#~*$<>]")
    virtualKey := GetKeyVK(keyName)
    if !virtualKey {
        return true
    }
    identifier := 0xB000 + index
    ok := DllCall("User32\RegisterHotKey", "Ptr", 0, "Int", identifier,
        "UInt", modifiers | 0x4000, "UInt", virtualKey, "Int")
    if ok {
        DllCall("User32\UnregisterHotKey", "Ptr", 0, "Int", identifier)
    }
    return !!ok
}

DescribeValidationError(item) {
    switch item.code {
        case "duplicate_trigger":
            return T("duplicate_trigger") " " FormatHotkeyForDisplay(item.value)
        case "missing_key", "missing_mapping":
            return T("missing_key")
        case "unknown_action":
            return T("unknown_action") " " item.value
        case "empty_snippet":
            return TF("empty_snippet", item.value)
        case "missing_snippets":
            return T("config_error")
        default:
            return T("config_error")
    }
}

FriendlyError(errorValue, context := "") {
    message := IsObject(errorValue) ? errorValue.Message : errorValue
    if (context = "hotkey") {
        return T("error_hotkey")
    }
    if (context = "system") {
        return T("error_system")
    }
    if (context = "storage") {
        return T("error_storage")
    }
    if (context = "config" || InStr(message, "config_") = 1) {
        return T("error_config_file")
    }
    return T("error_unexpected")
}

SetWindowsStartup(enabled) {
    global gTestMode
    if gTestMode {
        return
    }
    registryPath := "HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
    valueName := "MouseShortcuts"
    if enabled {
        if A_IsCompiled {
            command := '"' A_ScriptFullPath '" --background'
        } else {
            command := '"' A_AhkPath '" "' A_ScriptFullPath '" --background'
        }
        RegWrite(command, "REG_SZ", registryPath, valueName)
    } else {
        valueExists := false
        try {
            RegRead(registryPath, valueName)
            valueExists := true
        } catch as error {
            if (Type(error) != "OSError" || (error.Number != 2 && error.Number != 3)) {
                throw error
            }
        }
        if valueExists {
            try RegDelete(registryPath, valueName)
            catch as error {
                if (Type(error) != "OSError" || error.Number != 2) {
                    throw error
                }
            }
        }
    }
    legacyShortcut := LegacyStartupShortcutPath()
    if FileExist(legacyShortcut) {
        FileDelete(legacyShortcut)
    }
}

LegacyStartupShortcutPath() {
    return A_AppData "\Microsoft\Windows\Start Menu\Programs\Startup\Mouse Shortcuts.lnk"
}

LegacyConfigPathFromStartupShortcut() {
    return LegacyConfigPathFromShortcut(LegacyStartupShortcutPath())
}

LegacyConfigPathFromShortcut(shortcutPath) {
    if !FileExist(shortcutPath) {
        return ""
    }
    try {
        shell := ComObject("WScript.Shell")
        shortcut := shell.CreateShortcut(shortcutPath)
        candidates := []
        if (shortcut.WorkingDirectory != "") {
            candidates.Push(shortcut.WorkingDirectory "\mouse-remap.ini")
        }
        if (shortcut.TargetPath != "") {
            SplitPath(shortcut.TargetPath, , &targetDirectory)
            candidates.Push(targetDirectory "\mouse-remap.ini")
        }
        for candidate in candidates {
            if FileExist(candidate) {
                return candidate
            }
        }
    }
    return ""
}

GetLegacyMouseShortcutsProcesses() {
    processes := []
    seen := Map()
    try {
        service := ComObjGet("winmgmts:\\.\root\cimv2")
        query := "SELECT ProcessId, CommandLine FROM Win32_Process "
            . "WHERE Name='AutoHotkey64.exe' OR Name='AutoHotkey.exe'"
        for process in service.ExecQuery(query) {
            commandLine := ""
            try commandLine := process.CommandLine
            if (commandLine = "") {
                continue
            }
            lowered := StrLower(commandLine)
            if !InStr(lowered, "mouse-remap.ahk") && !InStr(lowered, "mouse-shortcuts-panel.ahk") {
                continue
            }
            pid := process.ProcessId + 0
            if seen.Has(pid) {
                continue
            }
            processes.Push({pid: pid, commandLine: commandLine,
                configPath: LegacyConfigPathFromCommandLine(commandLine)})
            seen[pid] := true
        }
    }
    return processes
}

EnsureLegacyRuntimeStopped() {
    global gLegacyProcesses, gTestMode
    if gTestMode {
        return true
    }
    gLegacyProcesses := GetLegacyMouseShortcutsProcesses()
    if !gLegacyProcesses.Length {
        return true
    }
    if (MsgBox(T("legacy_running"), T("legacy_title"), "YesNo Icon!") != "Yes") {
        return false
    }

    currentProcesses := GetLegacyMouseShortcutsProcesses()
    previousDetection := A_DetectHiddenWindows
    DetectHiddenWindows(true)
    for process in currentProcesses {
        try WinClose("ahk_pid " process.pid)
    }
    DetectHiddenWindows(previousDetection)
    for process in currentProcesses {
        try ProcessWaitClose(process.pid, 2)
    }

    remainingProcesses := GetLegacyMouseShortcutsProcesses()
    for process in remainingProcesses {
        try ProcessClose(process.pid)
    }
    for process in remainingProcesses {
        try ProcessWaitClose(process.pid, 2)
    }
    gLegacyProcesses := GetLegacyMouseShortcutsProcesses()
    if gLegacyProcesses.Length {
        MsgBox(T("legacy_close_failed"), T("legacy_title"), "Iconx")
        return false
    }
    return true
}

BuildSettingsGui(configToShow) {
    global gSettingsGui, gTabs, gStatusText, gMappingRows, gLeftButtonVoiceCheck
    global gLeftButtonVoiceHoldChoice, gSnippetRows
    global gLanguageChoice, gAutostartCheck, gTestMode, gSnippetSelector, gMappingGroupSelector

    if IsObject(gSettingsGui) {
        try gSettingsGui.Destroy()
    }
    gMappingRows := []
    gSnippetRows := []

    title := gTestMode ? T("window_title_test") : T("window_title")
    gSettingsGui := Gui("-MaximizeBox +MinimizeBox", title)
    gSettingsGui.SetFont("s9", "Segoe UI")
    gSettingsGui.MarginX := 20
    gSettingsGui.MarginY := 16

    gStatusText := gSettingsGui.Add("Text", "xm ym w735 h28")
    gStatusText.SetFont("s11 bold")

    gTabs := gSettingsGui.Add("Tab3", "xm y+8 w745 h420", [T("tab_buttons"), T("tab_text"), T("tab_general")])

    gTabs.UseTab(1)
    gMappingGroupSelector := gSettingsGui.Add("DropDownList", "x55 y105 w220", [T("group_common"), T("group_more")])
    gMappingGroupSelector.Choose(1)
    gMappingGroupSelector.OnEvent("Change", SwitchMappingGroup)
    buttonHeader := gSettingsGui.Add("Text", "x55 y140 w140", T("column_button"))
    keyHeader := gSettingsGui.Add("Text", "x200 yp w180", T("column_key"))
    actionHeader := gSettingsGui.Add("Text", "x390 yp w220", T("column_action"))
    buttonHeader.SetFont("bold")
    keyHeader.SetFont("bold")
    actionHeader.SetFont("bold")

    supportedKeys := GetSupportedKeys()
    actionIds := GetActionIds()
    actionLabels := []
    for actionId in actionIds {
        actionLabels.Push(ActionDisplayName(actionId))
    }

    for index, definition in GetMappingDefinitions() {
        isCommon := index <= 7
        localIndex := isCommon ? index : index - 7
        rowY := 170 + ((localIndex - 1) * 34)
        mapping := configToShow.mappings[definition.id]
        labelControl := gSettingsGui.Add("Text", "x55 y" rowY " w140 h23 +0x200", T(definition.label))
        keyControl := gSettingsGui.Add("ComboBox", "x200 y" (rowY - 2) " w180", supportedKeys)
        keyControl.Text := mapping.key
        actionControl := gSettingsGui.Add("DropDownList", "x390 y" (rowY - 2) " w220", actionLabels)
        actionControl.Choose(ActionIndex(mapping.action))
        detectButton := gSettingsGui.Add("Button", "x620 y" (rowY - 2) " w75 h25", T("detect"))
        detectButton.OnEvent("Click", BeginMappingCapture.Bind(index))
        controls := [labelControl, keyControl, actionControl, detectButton]
        for control in controls {
            control.Visible := isCommon
        }
        gMappingRows.Push({definition: definition, keyControl: keyControl,
            actionControl: actionControl, group: isCommon ? 1 : 2, controls: controls})
    }

    gLeftButtonVoiceCheck := gSettingsGui.Add("CheckBox", "x55 y410 w265 h28", T("left_hold_voice"))
    gLeftButtonVoiceCheck.Value := configToShow.leftButtonVoiceEnabled ? 1 : 0
    holdOptions := GetLeftButtonVoiceHoldOptions()
    holdLabels := []
    for option in holdOptions {
        holdLabels.Push(option.label)
    }
    gSettingsGui.Add("Text", "x340 y410 w90 h25 +0x200", T("left_hold_duration"))
    gLeftButtonVoiceHoldChoice := gSettingsGui.Add("DropDownList", "x430 y408 w72", holdLabels)
    holdChoiceIndex := 4
    for index, option in holdOptions {
        if (option.milliseconds = configToShow.leftButtonVoiceHoldMs) {
            holdChoiceIndex := index
            break
        }
    }
    gLeftButtonVoiceHoldChoice.Choose(holdChoiceIndex)
    gSettingsGui.Add("Text", "x510 y410 w70 h25 +0x200", T("seconds"))
    holdHint := gSettingsGui.Add("Text", "x55 y440 w680 h20", T("left_hold_hint"))
    holdHint.SetFont("s8 c666666")

    gTabs.UseTab(2)
    snippetTabNames := []
    Loop 5 {
        snippetTabNames.Push(TF("text_slot", A_Index))
    }
    gSnippetSelector := gSettingsGui.Add("DropDownList", "x55 y112 w200", snippetTabNames)
    gSnippetSelector.Choose(1)
    gSnippetSelector.OnEvent("Change", SwitchSnippet)
    Loop 5 {
        snippetIndex := A_Index
        snippet := configToShow.snippets[A_Index]
        shortcutLabel := gSettingsGui.Add("Text", "x55 y160 w100 h25 +0x200", T("shortcut"))
        shortcutLabel.SetFont("bold")
        hotkeyControl := gSettingsGui.Add("Edit", "x155 y158 w235 h25 ReadOnly", FormatHotkeyForDisplay(snippet.hotkey))
        recordButton := gSettingsGui.Add("Button", "x400 y157 w80 h27", T("record"))
        clearButton := gSettingsGui.Add("Button", "x490 y157 w80 h27", T("clear"))
        textControl := gSettingsGui.Add("Edit", "x55 y205 w655 h175 WantTab", snippet.text)
        recordButton.OnEvent("Click", BeginSnippetCapture.Bind(A_Index))
        clearButton.OnEvent("Click", ClearSnippetHotkey.Bind(A_Index))
        controls := [shortcutLabel, hotkeyControl, recordButton, clearButton, textControl]
        for control in controls {
            control.Visible := snippetIndex = 1
        }
        gSnippetRows.Push({hotkey: snippet.hotkey, hotkeyControl: hotkeyControl,
            textControl: textControl, controls: controls})
    }

    gTabs.UseTab(3)
    languageLabel := gSettingsGui.Add("Text", "x48 y115 w180 h25 +0x200", T("language"))
    gLanguageChoice := gSettingsGui.Add("DropDownList", "x240 y112 w220", [T("language_chinese"), T("language_english")])
    gLanguageChoice.Choose(configToShow.language = "zh-CN" ? 1 : 2)
    gLanguageChoice.OnEvent("Change", ChangeLanguage)

    gAutostartCheck := gSettingsGui.Add("CheckBox", "x48 y165 w500 h28", T("autostart"))
    gAutostartCheck.Value := configToShow.autostart ? 1 : 0

    exportButton := gSettingsGui.Add("Button", "x48 y225 w180 h34", T("export"))
    importButton := gSettingsGui.Add("Button", "x240 y225 w180 h34", T("import"))
    defaultsButton := gSettingsGui.Add("Button", "x432 y225 w180 h34", T("restore_defaults"))
    exportButton.OnEvent("Click", ExportConfiguration)
    importButton.OnEvent("Click", ImportConfiguration)
    defaultsButton.OnEvent("Click", RestoreDefaults)

    versionText := gSettingsGui.Add("Text", "x48 y300 w500 h25", T("app_name") " " gVersion)
    versionText.SetFont("c666666")

    gTabs.UseTab()
    gTabs.Choose(1)
    applyButton := gSettingsGui.Add("Button", "x485 y490 w155 h36 Default", T("save_apply"))
    hideButton := gSettingsGui.Add("Button", "x650 y490 w115 h36", T("hide_to_tray"))
    global gFooterText := gSettingsGui.Add("Text", "x22 y495 w450 h30 +0x200")
    applyButton.OnEvent("Click", SaveAndApplyFromGui)
    hideButton.OnEvent("Click", HideSettings)

    gSettingsGui.OnEvent("Close", HideSettings)
    gSettingsGui.OnEvent("Escape", HideSettings)
    gSettingsGui.OnEvent("Size", HandleGuiSize)
    gSettingsGui.Show("Hide w785 h545")
    RefreshStatusControl()
}

SwitchSnippet(*) {
    global gSnippetSelector, gSnippetRows, gSettingsGui
    selected := gSnippetSelector.Value
    for index, row in gSnippetRows {
        for control in row.controls {
            control.Visible := index = selected
        }
    }
    WinRedraw("ahk_id " gSettingsGui.Hwnd)
}

SwitchMappingGroup(*) {
    global gMappingGroupSelector, gMappingRows, gSettingsGui
    selected := gMappingGroupSelector.Value
    for row in gMappingRows {
        for control in row.controls {
            control.Visible := row.group = selected
        }
    }
    WinRedraw("ahk_id " gSettingsGui.Hwnd)
}

ActionIndex(actionId) {
    for index, candidate in GetActionIds() {
        if (candidate = actionId) {
            return index
        }
    }
    return 1
}

CollectConfigFromGui() {
    global gMappingRows, gLeftButtonVoiceCheck, gLeftButtonVoiceHoldChoice
    global gSnippetRows, gLanguageChoice, gAutostartCheck
    config := CreateDefaultConfig(gLanguageChoice.Value = 1 ? "zh-CN" : "en-US")
    config.autostart := gAutostartCheck.Value = 1
    config.leftButtonVoiceEnabled := gLeftButtonVoiceCheck.Value = 1
    holdOptions := GetLeftButtonVoiceHoldOptions()
    holdChoiceIndex := gLeftButtonVoiceHoldChoice.Value
    config.leftButtonVoiceHoldMs := holdChoiceIndex > 0
        ? holdOptions[holdChoiceIndex].milliseconds : 2000

    actionIds := GetActionIds()
    for row in gMappingRows {
        actionIndex := row.actionControl.Value
        actionId := actionIndex > 0 ? actionIds[actionIndex] : "disabled"
        config.mappings[row.definition.id] := {key: Trim(row.keyControl.Text), action: actionId}
    }
    for index, row in gSnippetRows {
        config.snippets[index] := {hotkey: row.hotkey, text: row.textControl.Value}
    }
    return config
}

SaveAndApplyFromGui(*) {
    TryApplyConfiguration(CollectConfigFromGui())
}

ShowSettings(*) {
    global gSettingsGui
    if !IsObject(gSettingsGui) {
        BuildSettingsGui(gActiveConfig)
    }
    gSettingsGui.Show("w785 h545")
    WinActivate("ahk_id " gSettingsGui.Hwnd)
}

HideSettings(*) {
    global gSettingsGui, gHasShownTrayHint, gTestMode
    if IsObject(gSettingsGui) {
        gSettingsGui.Hide()
    }
    if !gHasShownTrayHint && !gTestMode {
        TrayTip(T("tray_hidden"), T("app_name"), "Iconi")
        gHasShownTrayHint := true
    }
    return true
}

HandleGuiSize(guiObject, minMax, width, height) {
    if (minMax = -1) {
        SetTimer(HideSettings, -10)
    }
}

ChangeLanguage(*) {
    global gLanguage, gLanguageChoice, gActiveConfig, gConfigPath
    candidate := CollectConfigFromGui()
    newLanguage := gLanguageChoice.Value = 1 ? "zh-CN" : "en-US"
    candidate.language := newLanguage
    oldLanguage := gLanguage
    gActiveConfig.language := newLanguage
    try {
        SaveConfigFile(gActiveConfig, gConfigPath)
    } catch as error {
        gActiveConfig.language := oldLanguage
        gLanguageChoice.Choose(oldLanguage = "zh-CN" ? 1 : 2)
        MsgBox(T("save_failed") "`n`n" FriendlyError(error, "storage"), T("app_name"), "Iconx")
        return
    }
    gLanguage := newLanguage
    BuildSettingsGui(candidate)
    ConfigureTrayMenu()
    ShowSettings()
}

SetFooterMessage(message) {
    global gFooterText
    if IsObject(gFooterText) {
        gFooterText.Text := message
        SetTimer(() => ClearFooterMessage(), -4000)
    }
}

ClearFooterMessage() {
    global gFooterText
    if IsObject(gFooterText) {
        gFooterText.Text := ""
    }
}

UpdateStatus(state, detail := "") {
    global gState, gStateDetail
    gState := state
    gStateDetail := detail
    RefreshStatusControl()
    ConfigureTrayMenu()
}

RefreshStatusControl() {
    global gStatusText, gState, gStateDetail
    if !IsObject(gStatusText) {
        return
    }
    switch gState {
        case "running":
            label := "● " T("status_running")
            color := "2E7D32"
        case "paused":
            label := "● " T("status_paused")
            color := "B26A00"
        case "error":
            label := "● " T("status_error")
            color := "B3261E"
        default:
            label := "● " T("status_stopped")
            color := "666666"
    }
    if (gStateDetail != "") {
        label .= " - " gStateDetail
    }
    gStatusText.SetFont("c" color)
    gStatusText.Text := label
}

ConfigureTrayMenu() {
    global gState, gCaptureActive, gActiveHotkeys
    A_IconTip := T("app_name") " - " T("status_" (gState = "error" ? "error" : gState))
    A_TrayMenu.Delete()
    A_TrayMenu.Add(T("settings"), ShowSettings)
    A_TrayMenu.Default := T("settings")
    A_TrayMenu.ClickCount := 1
    A_TrayMenu.Add()
    if !gCaptureActive && (gState = "running" || (gState = "error" && gActiveHotkeys.Length)) {
        A_TrayMenu.Add(T("pause"), PauseTool)
    } else if !gCaptureActive && (gState = "paused") {
        A_TrayMenu.Add(T("resume"), ResumeTool)
    }
    A_TrayMenu.Add()
    A_TrayMenu.Add(T("exit"), ExitTool)
}

PauseTool(*) {
    global gPaused, gCaptureActive
    if gCaptureActive {
        return
    }
    CancelLeftButtonVoice()
    Suspend(true)
    gPaused := true
    UpdateStatus("paused")
}

ResumeTool(*) {
    global gPaused, gCaptureActive, gStartupSyncFailed
    if gCaptureActive {
        return
    }
    Suspend(false)
    gPaused := false
    UpdateStatus(gStartupSyncFailed ? "error" : "running",
        gStartupSyncFailed ? T("startup_failed") : "")
}

ExitTool(*) {
    UnregisterConfigurationHotkeys()
    ReleaseApplicationSingleton()
    ExitApp(0)
}

BeginMappingCapture(index, *) {
    BeginCapture("mapping", index)
}

BeginSnippetCapture(index, *) {
    BeginCapture("snippet", index)
}

BeginCapture(kind, index) {
    global gCaptureGui, gCaptureKind, gCaptureIndex, gCaptureActive
    global gCaptureHadBindings, gPaused, gActiveHotkeys, gSettingsGui

    if gCaptureActive {
        CancelCapture()
    }
    gCaptureKind := kind
    gCaptureIndex := index
    gCaptureActive := true
    gCaptureHadBindings := gActiveHotkeys.Length > 0
    Suspend(false)
    UnregisterConfigurationHotkeys()
    gSettingsGui.Opt("+Disabled")
    ConfigureTrayMenu()

    gCaptureGui := Gui("+Owner" gSettingsGui.Hwnd " -MaximizeBox -MinimizeBox", T("capture_title"))
    gCaptureGui.SetFont("s10", "Segoe UI")
    prompt := kind = "mapping" ? T("capture_key") : T("capture_shortcut")
    gCaptureGui.Add("Text", "xm ym w480 h35 Center", prompt)
    gCaptureGui.Add("Text", "xm y+8 w480 h45 Center c666666", T("capture_vendor_hint"))
    cancelButton := gCaptureGui.Add("Button", "xm+190 y+12 w100 h30", T("cancel"))
    cancelButton.OnEvent("Click", CancelCapture)
    gCaptureGui.OnEvent("Close", CancelCapture)
    gCaptureGui.OnEvent("Escape", CancelCapture)
    gCaptureGui.Show("w520 h165")
    SetTimer(EnableCaptureHooks, -250)
}

EnableCaptureHooks() {
    global gCaptureActive, gCaptureHotkeys, gCaptureInput
    if !gCaptureActive {
        return
    }
    gCaptureHotkeys := []
    for keyName in ["MButton", "XButton1", "XButton2", "WheelUp", "WheelDown", "WheelLeft", "WheelRight"] {
        specification := "*" keyName
        try {
            Hotkey(specification, CaptureKnownKey.Bind(keyName), "On")
            gCaptureHotkeys.Push(specification)
        }
    }

    input := InputHook()
    input.VisibleText := false
    input.VisibleNonText := false
    input.KeyOpt("{All}", "E")
    input.KeyOpt("{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}", "-E")
    input.OnEnd := CaptureInputEnded
    gCaptureInput := input
    input.Start()
}

CaptureKnownKey(keyName, *) {
    CompleteCapture(keyName)
}

CaptureInputEnded(input) {
    global gCaptureActive
    if !gCaptureActive {
        return
    }
    keyName := input.EndKey
    if (keyName != "") {
        CompleteCapture(keyName, ModifierPrefixFromState(input.EndMods))
    }
}

CompleteCapture(keyName, capturedModifiers := "") {
    global gCaptureActive, gCaptureKind, gCaptureIndex, gMappingRows, gSnippetRows
    if !gCaptureActive {
        return
    }
    kind := gCaptureKind
    index := gCaptureIndex
    modifierPrefix := capturedModifiers != "" ? capturedModifiers : CurrentModifierPrefix()
    trigger := kind = "snippet" ? modifierPrefix keyName : keyName
    StopCaptureHooks()

    if (kind = "mapping") {
        gMappingRows[index].keyControl.Text := keyName
    } else {
        gSnippetRows[index].hotkey := trigger
        gSnippetRows[index].hotkeyControl.Value := FormatHotkeyForDisplay(trigger)
    }
    SetFooterMessage(TF("detected", FormatHotkeyForDisplay(trigger)))
}

CurrentModifierPrefix() {
    prefix := ""
    if GetKeyState("Ctrl", "P")
        prefix .= "^"
    if GetKeyState("Alt", "P")
        prefix .= "!"
    if GetKeyState("Shift", "P")
        prefix .= "+"
    if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P"))
        prefix .= "#"
    return prefix
}

CancelCapture(*) {
    StopCaptureHooks()
}

StopCaptureHooks() {
    global gCaptureActive, gCaptureHotkeys, gCaptureInput, gCaptureGui
    global gCaptureHadBindings, gActiveConfig, gTestMode, gSettingsGui, gPaused

    if !gCaptureActive {
        return
    }
    gCaptureActive := false
    for specification in gCaptureHotkeys {
        try Hotkey(specification, "Off")
    }
    gCaptureHotkeys := []
    if IsObject(gCaptureInput) {
        try gCaptureInput.Stop()
    }
    gCaptureInput := 0
    if IsObject(gCaptureGui) {
        try gCaptureGui.Destroy()
    }
    gCaptureGui := 0
    if IsObject(gSettingsGui) {
        gSettingsGui.Opt("-Disabled")
        try WinActivate("ahk_id " gSettingsGui.Hwnd)
    }

    if gCaptureHadBindings && !gTestMode {
        RegisterConfigurationHotkeys(gActiveConfig)
    }
    if gPaused {
        Suspend(true)
    }
    ConfigureTrayMenu()
}

ClearSnippetHotkey(index, *) {
    global gSnippetRows
    gSnippetRows[index].hotkey := ""
    gSnippetRows[index].hotkeyControl.Value := T("not_set")
}

RestoreDefaults(*) {
    global gLanguageChoice
    if (MsgBox(T("defaults_confirm"), T("defaults_title"), "YesNo Icon?") != "Yes") {
        return
    }
    defaults := CreateDefaultConfig(gLanguageChoice.Value = 1 ? "zh-CN" : "en-US")
    if TryApplyConfiguration(defaults, false) {
        BuildSettingsGui(defaults)
        ShowSettings()
        SetFooterMessage(T("saved_applied"))
    }
}

ExportConfiguration(*) {
    candidate := CollectConfigFromGui()
    validation := ValidateConfig(candidate)
    if validation.errors.Length {
        MsgBox(T("export_failed") "`n`n" DescribeValidationError(validation.errors[1]), T("app_name"), "Iconx")
        return
    }

    defaultPath := A_MyDocuments "\MouseShortcuts-config.msconfig"
    selectedPath := FileSelect("S16", defaultPath, T("export_title"), "Mouse Shortcuts (*.msconfig)")
    if (selectedPath = "") {
        return
    }
    if !RegExMatch(selectedPath, "i)\.msconfig$") {
        selectedPath .= ".msconfig"
    }
    try {
        SaveConfigFile(candidate, selectedPath)
        MsgBox(T("export_ok"), T("app_name"), "Iconi")
    } catch as error {
        MsgBox(T("export_failed") "`n`n" FriendlyError(error, "storage"), T("app_name"), "Iconx")
    }
}

ImportConfiguration(*) {
    global gLanguage, gActiveConfig
    selectedPath := FileSelect(1, A_MyDocuments, T("import_title"), "Mouse Shortcuts (*.msconfig; *.ini)")
    if (selectedPath = "") {
        return
    }
    try {
        SplitPath(selectedPath, &selectedName)
        imported := StrLower(selectedName) = "mouse-remap.ini"
            ? LoadLegacyConfigFile(selectedPath, gLanguage, gActiveConfig.autostart)
            : LoadConfigFile(selectedPath, gLanguage)
        validation := ValidateConfig(imported)
        if validation.errors.Length {
            MsgBox(T("import_failed") "`n`n" DescribeValidationError(validation.errors[1]), T("app_name"), "Iconx")
            return
        }
        if TryApplyConfiguration(imported, false) {
            gLanguage := imported.language
            BuildSettingsGui(imported)
            ConfigureTrayMenu()
            ShowSettings()
            MsgBox(T("import_ok"), T("app_name"), "Iconi")
        }
    } catch as error {
        MsgBox(T("import_failed") "`n`n" FriendlyError(error, "config"), T("app_name"), "Iconx")
    }
}
