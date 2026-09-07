#Requires AutoHotkey v2.0
#SingleInstance Force

SetWorkingDir(A_ScriptDir)

configFile := A_ScriptDir "\mouse-remap.ini"
commandFile := A_ScriptDir "\mouse-shortcuts.cmd"
snippetDir := A_ScriptDir "\snippets"

if (A_Args.Length > 0 && A_Args[1] = "--check") {
    LoadSection(configFile, "Mappings")
    ExitApp(0)
}

settings := LoadSection(configFile, "Settings")
currentLang := NormalizeLanguage(settings.Has("language") ? settings["language"] : DetectDefaultLanguage())

buttonChoices := [
    "MButton", "XButton1", "XButton2",
    "WheelUp", "WheelDown", "WheelLeft", "WheelRight",
    "Browser_Back", "Browser_Forward", "Browser_Home", "Browser_Search", "Browser_Favorites", "Browser_Refresh", "Browser_Stop",
    "Launch_App1", "Launch_App2", "Launch_Mail", "Launch_Media",
    "Media_Play_Pause", "Media_Next", "Media_Prev", "Media_Stop",
    "Volume_Mute", "Volume_Down", "Volume_Up",
    "F13", "F14", "F15", "F16", "F17", "F18", "F19", "F20", "F21", "F22", "F23", "F24",
    "LButton", "RButton"
]

actionChoices := [
    "disabled", "voice", "enter", "backspace", "delete",
    "copy", "paste", "cut", "select_all", "undo", "redo",
    "escape", "tab", "space", "home", "end", "page_up", "page_down",
    "browser_back", "browser_forward", "desktop", "lock", "snip",
    "volume_mute", "volume_down", "volume_up",
    "media_play_pause", "media_next", "media_prev", "media_stop"
]

rowDefs := [
    {slot: "middle", labelKey: "row_middle", defaultKey: "MButton", defaultAction: "voice"},
    {slot: "side_up", labelKey: "row_side_up", defaultKey: "XButton2", defaultAction: "enter"},
    {slot: "side_down", labelKey: "row_side_down", defaultKey: "XButton1", defaultAction: "backspace"},
    {slot: "wheel_up", labelKey: "row_wheel_up", defaultKey: "WheelUp", defaultAction: "disabled"},
    {slot: "wheel_down", labelKey: "row_wheel_down", defaultKey: "WheelDown", defaultAction: "disabled"},
    {slot: "wheel_left", labelKey: "row_wheel_left", defaultKey: "WheelLeft", defaultAction: "disabled"},
    {slot: "wheel_right", labelKey: "row_wheel_right", defaultKey: "WheelRight", defaultAction: "disabled"},
    {slot: "browser_back", labelKey: "row_browser_back", defaultKey: "Browser_Back", defaultAction: "backspace"},
    {slot: "browser_forward", labelKey: "row_browser_forward", defaultKey: "Browser_Forward", defaultAction: "disabled"},
    {slot: "launch_app1", labelKey: "row_launch_app1", defaultKey: "Launch_App1", defaultAction: "backspace"},
    {slot: "launch_app2", labelKey: "row_launch_app2", defaultKey: "Launch_App2", defaultAction: "disabled"},
    {slot: "extra_1", labelKey: "row_extra_1", defaultKey: "F13", defaultAction: "disabled"},
    {slot: "extra_2", labelKey: "row_extra_2", defaultKey: "F14", defaultAction: "disabled"},
    {slot: "extra_3", labelKey: "row_extra_3", defaultKey: "F15", defaultAction: "disabled"},
    {slot: "extra_4", labelKey: "row_extra_4", defaultKey: "F16", defaultAction: "disabled"}
]

slots := LoadSection(configFile, "Slots")
mappings := LoadSection(configFile, "Mappings")
textHotkeys := LoadSection(configFile, "TextHotkeys")
snippets := LoadSection(configFile, "Snippets")

rows := []
textRows := []
sectionControls := []

app := Gui("+Resize", T("title"))
app.SetFont("s9", "Segoe UI")

languageLabel := app.Add("Text", "xm ym w170")
languageChoice := app.Add("DropDownList", "x+10 yp-3 w185", ["中文", "English"])
languageChoice.Choose(currentLang = "zh-CN" ? 1 : 2)

introText := app.Add("Text", "xm y+12 w760")
roleHeader := app.Add("Text", "xm y+10 w170")
keyHeader := app.Add("Text", "x+10 yp w185")
actionHeader := app.Add("Text", "x+12 yp w185")

for index, def in rowDefs {
    if (index = 4) {
        sectionControls.Push({control: app.Add("Text", "xm y+12 w760"), key: "section_wheel"})
    } else if (index = 8) {
        sectionControls.Push({control: app.Add("Text", "xm y+12 w760"), key: "section_browser"})
    } else if (index = 12) {
        sectionControls.Push({control: app.Add("Text", "xm y+12 w760"), key: "section_extra"})
    }

    keyValue := slots.Has(def.slot) ? slots[def.slot] : def.defaultKey
    actionValue := mappings.Has(keyValue) ? mappings[keyValue] : def.defaultAction
    if (actionValue = "") {
        actionValue := "disabled"
    }

    labelControl := app.Add("Text", "xm y+6 w170")
    keyControl := app.Add("ComboBox", "x+10 yp-3 w185", buttonChoices)
    actionControl := app.Add("ComboBox", "x+12 yp w185", actionChoices)
    SetComboText(keyControl, keyValue)
    SetComboText(actionControl, actionValue)
    rows.Push({slot: def.slot, labelKey: def.labelKey, labelControl: labelControl, keyControl: keyControl, actionControl: actionControl})
}

sectionControls.Push({control: app.Add("Text", "xm y+14 w760"), key: "section_text"})
snippetHintText := app.Add("Text", "xm y+6 w760")

Loop 5 {
    snippetName := "snippet_" A_Index
    hotkeyValue := textHotkeys.Has(snippetName) ? textHotkeys[snippetName] : "disabled"
    snippetPath := snippets.Has(snippetName) ? ResolvePath(snippets[snippetName]) : snippetDir "\" snippetName ".txt"
    snippetText := FileExist(snippetPath) ? FileRead(snippetPath, "UTF-8") : ""

    labelControl := app.Add("Text", "xm y+8 w170")
    hotkeyControl := app.Add("Edit", "x+10 yp-3 w185", hotkeyValue)
    textControl := app.Add("Edit", "x+12 yp w420 h42", snippetText)
    textRows.Push({name: snippetName, labelKey: "snippet_row_" A_Index, labelControl: labelControl, hotkeyControl: hotkeyControl, textControl: textControl})
}

actionHintText := app.Add("Text", "xm y+14 w760")

saveButton := app.Add("Button", "xm y+14 w110")
saveStartButton := app.Add("Button", "x+8 yp w140 Default")
startButton := app.Add("Button", "x+8 yp w80")
stopButton := app.Add("Button", "x+8 yp w80")

detectButton := app.Add("Button", "xm y+10 w110")
openConfigButton := app.Add("Button", "x+8 yp w110")
openLogButton := app.Add("Button", "x+8 yp w110")
exitButton := app.Add("Button", "x+8 yp w80")

statusText := app.Add("Text", "xm y+12 w760")

languageChoice.OnEvent("Change", LanguageChanged)
saveButton.OnEvent("Click", SaveOnly)
saveStartButton.OnEvent("Click", SaveAndStart)
startButton.OnEvent("Click", StartTool)
stopButton.OnEvent("Click", StopTool)
detectButton.OnEvent("Click", DetectKeys)
openConfigButton.OnEvent("Click", OpenConfig)
openLogButton.OnEvent("Click", OpenKeyLog)
exitButton.OnEvent("Click", (*) => app.Destroy())
app.OnEvent("Close", (*) => ExitApp(0))

ApplyLanguage()
statusText.Text := T("ready")
app.Show("w830")

LanguageChanged(*) {
    global currentLang, statusText
    currentLang := GetSelectedLanguage()
    ApplyLanguage()
    statusText.Text := T("language_changed")
}

ApplyLanguage() {
    global languageLabel, introText, roleHeader, keyHeader, actionHeader, sectionControls, rows, textRows
    global snippetHintText, actionHintText, saveButton, saveStartButton, startButton, stopButton
    global detectButton, openConfigButton, openLogButton, exitButton

    languageLabel.Text := T("language")
    introText.Text := T("intro")
    roleHeader.Text := T("role_header")
    keyHeader.Text := T("key_header")
    actionHeader.Text := T("action_header")
    for item in sectionControls {
        item.control.Text := T(item.key)
    }
    for row in rows {
        row.labelControl.Text := T(row.labelKey)
    }
    for row in textRows {
        row.labelControl.Text := T(row.labelKey)
    }
    snippetHintText.Text := T("snippet_hint")
    actionHintText.Text := T("action_hint")
    saveButton.Text := T("save")
    saveStartButton.Text := T("save_start")
    startButton.Text := T("start")
    stopButton.Text := T("stop")
    detectButton.Text := T("detect_keys")
    openConfigButton.Text := T("open_config")
    openLogButton.Text := T("open_key_log")
    exitButton.Text := T("close")
}

SaveOnly(*) {
    global statusText
    if SaveConfig() {
        statusText.Text := T("saved")
    }
}

SaveAndStart(*) {
    global statusText
    if !SaveConfig() {
        return
    }
    code := RunCommand("restart")
    statusText.Text := code = 0 ? T("saved_started") : T("save_start_failed") " " code
}

StartTool(*) {
    global statusText
    code := RunCommand("start")
    statusText.Text := code = 0 ? T("started") : T("start_failed") " " code
}

StopTool(*) {
    global statusText
    code := RunCommand("stop")
    statusText.Text := code = 0 ? T("stopped") : T("stop_failed") " " code
}

DetectKeys(*) {
    global statusText
    Run('"' A_AhkPath '" "' A_ScriptDir '\key-test.ahk"')
    statusText.Text := T("detector_opened")
}

OpenConfig(*) {
    global configFile
    Run('notepad.exe "' configFile '"')
}

OpenKeyLog(*) {
    logFile := A_ScriptDir "\key-test.log"
    if !FileExist(logFile) {
        FileAppend("No keys detected yet.`r`n", logFile, "UTF-8")
    }
    Run('notepad.exe "' logFile '"')
}

SaveConfig() {
    global rows, textRows, configFile, snippetDir

    used := Map()
    slotLines := ""
    mappingLines := ""
    textHotkeyLines := ""
    snippetLines := ""

    for row in rows {
        keyText := Trim(row.keyControl.Text)
        actionText := Trim(row.actionControl.Text)

        if (keyText = "") {
            MsgBox(T("fill_every_key"), T("title"), "Icon!")
            return false
        }
        if (actionText = "") {
            actionText := "disabled"
        }

        slotLines .= row.slot "=" keyText "`r`n"

        if IsDisabled(actionText) {
            continue
        }
        if used.Has(keyText) {
            MsgBox(T("duplicate_active_button") " " keyText, T("title"), "Icon!")
            return false
        }
        used[keyText] := true
        mappingLines .= keyText "=" actionText "`r`n"
    }

    DirCreate(snippetDir)
    for row in textRows {
        hotkeyText := Trim(row.hotkeyControl.Value)
        snippetText := row.textControl.Value
        if (hotkeyText = "") {
            hotkeyText := "disabled"
        }

        snippetRelativePath := "snippets\" row.name ".txt"
        snippetPath := A_ScriptDir "\" snippetRelativePath
        file := FileOpen(snippetPath, "w", "UTF-8")
        file.Write(snippetText)
        file.Close()

        if !IsDisabled(hotkeyText) {
            if (snippetText = "") {
                MsgBox(T("empty_snippet") " " row.name, T("title"), "Icon!")
                return false
            }
            if used.Has(hotkeyText) {
                MsgBox(T("duplicate_active_button") " " hotkeyText, T("title"), "Icon!")
                return false
            }
            used[hotkeyText] := true
        }

        textHotkeyLines .= row.name "=" hotkeyText "`r`n"
        snippetLines .= row.name "=" snippetRelativePath "`r`n"
    }

    content := "; Mouse Shortcuts config`r`n"
        . "; Edit with open-control-panel.cmd, mouse-shortcuts-panel.ahk, or by hand.`r`n"
        . "; Set an action or text hotkey to disabled to keep it visible but inactive.`r`n`r`n"
        . "[Settings]`r`n"
        . "language=" GetSelectedLanguage() "`r`n`r`n"
        . "[Slots]`r`n"
        . slotLines
        . "`r`n[Mappings]`r`n"
        . mappingLines
        . "`r`n[TextHotkeys]`r`n"
        . textHotkeyLines
        . "`r`n[Snippets]`r`n"
        . snippetLines
        . "`r`n[Actions]`r`n"
        . BuildActionsText()

    file := FileOpen(configFile, "w", "UTF-8")
    file.Write(content)
    file.Close()
    return true
}

GetSelectedLanguage() {
    global languageChoice
    return languageChoice.Text = "English" ? "en-US" : "zh-CN"
}

NormalizeLanguage(value) {
    normalized := StrLower(Trim(value))
    return (normalized = "zh" || normalized = "zh-cn" || normalized = "zh_cn" || normalized = "chinese" || normalized = "中文") ? "zh-CN" : "en-US"
}

DetectDefaultLanguage() {
    return InStr(",0804,0404,0c04,1004,", "," A_Language ",") ? "zh-CN" : "en-US"
}

IsDisabled(actionName) {
    normalized := StrLower(Trim(actionName))
    return normalized = "disabled" || normalized = "disable" || normalized = "none" || normalized = "off"
}

BuildActionsText() {
    return "enter={Enter}`r`n"
        . "backspace={Backspace}`r`n"
        . "delete={Delete}`r`n"
        . "voice=#h`r`n"
        . "copy=^c`r`n"
        . "paste=^v`r`n"
        . "cut=^x`r`n"
        . "select_all=^a`r`n"
        . "undo=^z`r`n"
        . "redo=^y`r`n"
        . "escape={Esc}`r`n"
        . "tab={Tab}`r`n"
        . "space={Space}`r`n"
        . "home={Home}`r`n"
        . "end={End}`r`n"
        . "page_up={PgUp}`r`n"
        . "page_down={PgDn}`r`n"
        . "browser_back=!{Left}`r`n"
        . "browser_forward=!{Right}`r`n"
        . "desktop=#d`r`n"
        . "lock=#l`r`n"
        . "snip=#+s`r`n"
        . "volume_mute={Volume_Mute}`r`n"
        . "volume_down={Volume_Down}`r`n"
        . "volume_up={Volume_Up}`r`n"
        . "media_play_pause={Media_Play_Pause}`r`n"
        . "media_next={Media_Next}`r`n"
        . "media_prev={Media_Prev}`r`n"
        . "media_stop={Media_Stop}`r`n"
}

RunCommand(command) {
    global commandFile
    if !FileExist(commandFile) {
        MsgBox(T("command_not_found") " " commandFile, T("title"), "Iconx")
        return 1
    }
    return RunWait('"' commandFile '" ' command, A_ScriptDir, "Hide")
}

ResolvePath(pathValue) {
    if (InStr(pathValue, ":\") || SubStr(pathValue, 1, 2) = "\\") {
        return pathValue
    }
    return A_ScriptDir "\" pathValue
}

SetComboText(control, value) {
    try {
        control.ChooseString(value)
    } catch {
        control.Text := value
    }
}

T(key) {
    global currentLang
    static en := Map(
        "title", "Mouse Shortcuts",
        "language", "Language / 语言",
        "intro", "Set mouse buttons and text shortcuts, then click Save and Start. Use disabled for items you want listed but inactive.",
        "role_header", "Button role",
        "key_header", "Detected key",
        "action_header", "Action",
        "section_wheel", "Wheel and side-scroll buttons",
        "section_browser", "Browser and vendor buttons",
        "section_extra", "Extra programmable keys",
        "section_text", "Custom text shortcuts",
        "row_middle", "Middle button",
        "row_side_up", "Upper side button",
        "row_side_down", "Lower side button",
        "row_wheel_up", "Wheel up",
        "row_wheel_down", "Wheel down",
        "row_wheel_left", "Side wheel left",
        "row_wheel_right", "Side wheel right",
        "row_browser_back", "Browser back key",
        "row_browser_forward", "Browser forward key",
        "row_launch_app1", "Vendor app key 1",
        "row_launch_app2", "Vendor app key 2",
        "row_extra_1", "Extra key 1",
        "row_extra_2", "Extra key 2",
        "row_extra_3", "Extra key 3",
        "row_extra_4", "Extra key 4",
        "snippet_row_1", "Text shortcut 1",
        "snippet_row_2", "Text shortcut 2",
        "snippet_row_3", "Text shortcut 3",
        "snippet_row_4", "Text shortcut 4",
        "snippet_row_5", "Text shortcut 5",
        "snippet_hint", "Hotkey examples: ^!1 = Ctrl+Alt+1, #v = Win+V. Set hotkey to disabled when unused.",
        "action_hint", "Actions: voice=Win+H, disabled=not mapped. Advanced users may type a raw AutoHotkey SendInput value.",
        "save", "Save",
        "save_start", "Save and Start",
        "start", "Start",
        "stop", "Stop",
        "detect_keys", "Detect Keys",
        "open_config", "Open Config",
        "open_key_log", "Open Key Log",
        "close", "Close",
        "ready", "Ready.",
        "language_changed", "Language changed. Click Save to keep it.",
        "saved", "Saved. Click Start or Save and Start to apply it.",
        "saved_started", "Saved and started.",
        "save_start_failed", "Save succeeded, but start failed. Exit code:",
        "started", "Started.",
        "start_failed", "Start failed. Exit code:",
        "stopped", "Stopped.",
        "stop_failed", "Stop failed. Exit code:",
        "detector_opened", "Key detector opened. Press mouse buttons, then open key log.",
        "fill_every_key", "Please fill every key field. Use action disabled when a key should stay inactive.",
        "duplicate_active_button", "Duplicate active button:",
        "empty_snippet", "Text is empty for active shortcut:",
        "command_not_found", "Command file not found:"
    )
    static zh := Map(
        "title", "鼠标快捷键",
        "language", "语言 / Language",
        "intro", "设置鼠标按键和文本快捷键，然后点击“保存并启动”。不想启用的项目请选择 disabled。",
        "role_header", "按键位置",
        "key_header", "检测到的键名",
        "action_header", "动作",
        "section_wheel", "滚轮和侧滚轮",
        "section_browser", "浏览器键和厂商键",
        "section_extra", "额外可编程键",
        "section_text", "自定义文本快捷键",
        "row_middle", "鼠标中键",
        "row_side_up", "侧上键",
        "row_side_down", "侧下键",
        "row_wheel_up", "滚轮上",
        "row_wheel_down", "滚轮下",
        "row_wheel_left", "侧滚轮左",
        "row_wheel_right", "侧滚轮右",
        "row_browser_back", "浏览器后退键",
        "row_browser_forward", "浏览器前进键",
        "row_launch_app1", "厂商扩展键 1",
        "row_launch_app2", "厂商扩展键 2",
        "row_extra_1", "额外键 1",
        "row_extra_2", "额外键 2",
        "row_extra_3", "额外键 3",
        "row_extra_4", "额外键 4",
        "snippet_row_1", "文本快捷键 1",
        "snippet_row_2", "文本快捷键 2",
        "snippet_row_3", "文本快捷键 3",
        "snippet_row_4", "文本快捷键 4",
        "snippet_row_5", "文本快捷键 5",
        "snippet_hint", "快捷键示例：^!1 = Ctrl+Alt+1，#v = Win+V。不使用时把快捷键设为 disabled。",
        "action_hint", "动作说明：voice=Win+H，disabled=不映射。高级用户也可以输入 AutoHotkey SendInput 原始值。",
        "save", "保存",
        "save_start", "保存并启动",
        "start", "启动",
        "stop", "停止",
        "detect_keys", "检测按键",
        "open_config", "打开配置",
        "open_key_log", "打开日志",
        "close", "关闭",
        "ready", "就绪。",
        "language_changed", "语言已切换。点击“保存”后下次会记住。",
        "saved", "已保存。点击“启动”或“保存并启动”后生效。",
        "saved_started", "已保存并启动。",
        "save_start_failed", "保存成功，但启动失败。退出码：",
        "started", "已启动。",
        "start_failed", "启动失败。退出码：",
        "stopped", "已停止。",
        "stop_failed", "停止失败。退出码：",
        "detector_opened", "按键检测器已打开。请按鼠标键，然后打开日志查看键名。",
        "fill_every_key", "请填写每一行的键名。不想启用时把动作设为 disabled。",
        "duplicate_active_button", "重复启用的按键：",
        "empty_snippet", "启用的文本快捷键内容为空：",
        "command_not_found", "找不到命令文件："
    )
    dict := currentLang = "zh-CN" ? zh : en
    return dict.Has(key) ? dict[key] : key
}

LoadSection(filePath, sectionName) {
    result := Map()
    if (!FileExist(filePath)) {
        return result
    }

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
