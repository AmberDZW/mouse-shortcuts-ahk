#Requires AutoHotkey v2.0

T(key) {
    global gLanguage
    static en := Map(
        "app_name", "Mouse Shortcuts",
        "window_title", "Mouse Shortcuts - Settings",
        "window_title_test", "Mouse Shortcuts - Settings [Test]",
        "tab_buttons", "Mouse buttons",
        "tab_text", "Text shortcuts",
        "tab_general", "General",
        "group_common", "Common buttons",
        "group_more", "More buttons",
        "status_running", "Running",
        "status_paused", "Paused",
        "status_stopped", "Not started",
        "status_error", "Configuration issue",
        "column_button", "Button",
        "column_key", "Detected key",
        "column_action", "Action",
        "detect", "Detect",
        "middle", "Middle button",
        "side_up", "Upper side button",
        "side_down", "Lower side button",
        "left_hold_voice", "Enable stationary left-button hold for Voice Typing",
        "left_hold_duration", "Wake after",
        "seconds", "seconds",
        "left_hold_hint", "Release to end; dragging before activation cancels",
        "wheel_up", "Wheel up",
        "wheel_down", "Wheel down",
        "wheel_left", "Side wheel left",
        "wheel_right", "Side wheel right",
        "browser_back", "Browser back",
        "browser_forward", "Browser forward",
        "vendor_1", "Vendor key 1",
        "vendor_2", "Vendor key 2",
        "extra_1", "Extra key 1",
        "extra_2", "Extra key 2",
        "extra_3", "Extra key 3",
        "extra_4", "Extra key 4",
        "action_disabled", "Off",
        "action_voice", "Voice typing",
        "action_enter", "Enter",
        "action_backspace", "Backspace",
        "action_delete", "Delete",
        "action_copy", "Copy",
        "action_paste", "Paste",
        "action_cut", "Cut",
        "action_select_all", "Select all",
        "action_undo", "Undo",
        "action_redo", "Redo",
        "action_escape", "Escape",
        "action_tab", "Tab",
        "action_space", "Space",
        "action_home", "Home",
        "action_end", "End",
        "action_page_up", "Page up",
        "action_page_down", "Page down",
        "action_browser_back", "Go back",
        "action_browser_forward", "Go forward",
        "action_desktop", "Show desktop",
        "action_lock", "Lock computer",
        "action_snip", "Screen snip",
        "action_volume_mute", "Mute",
        "action_volume_down", "Volume down",
        "action_volume_up", "Volume up",
        "action_media_play_pause", "Play / pause",
        "action_media_next", "Next track",
        "action_media_prev", "Previous track",
        "action_media_stop", "Stop media",
        "text_slot", "Text shortcut {}",
        "shortcut", "Shortcut",
        "record", "Record",
        "clear", "Clear",
        "not_set", "Not set",
        "language", "Language",
        "language_chinese", "Chinese",
        "language_english", "English",
        "autostart", "Start automatically when I sign in to Windows",
        "export", "Export configuration",
        "import", "Import configuration",
        "restore_defaults", "Restore defaults",
        "save_apply", "Save and apply",
        "hide_to_tray", "Hide to tray",
        "settings", "Settings",
        "pause", "Pause",
        "resume", "Resume",
        "exit", "Exit",
        "saved_applied", "Settings saved and applied.",
        "save_failed", "The settings could not be applied:",
        "config_error", "The saved configuration has a problem.",
        "duplicate_trigger", "Two active items use the same button or shortcut:",
        "missing_key", "Choose a key for every visible button row.",
        "unknown_action", "One selected action is not supported.",
        "empty_snippet", "Add text or clear the shortcut for text shortcut {}.",
        "possible_conflict_title", "Possible shortcut conflict",
        "possible_conflict", "These shortcuts may already be used by Windows or another app:`n`n{}`n`nSave them anyway?",
        "capture_title", "Detect a button",
        "capture_key", "Press the mouse button or vendor key now.",
        "capture_shortcut", "Hold the modifier keys, then press the shortcut key or mouse button.",
        "capture_vendor_hint", "If nothing appears, map the vendor button to F13-F24 in the mouse manufacturer's app.",
        "cancel", "Cancel",
        "detected", "Detected: {}",
        "defaults_confirm", "Restore default buttons, turn off Windows startup, and clear all text shortcuts?",
        "defaults_title", "Restore defaults",
        "import_title", "Import Mouse Shortcuts configuration",
        "export_title", "Export Mouse Shortcuts configuration",
        "import_ok", "Configuration imported and applied.",
        "import_failed", "This configuration could not be imported:",
        "export_ok", "Configuration exported.",
        "export_failed", "The configuration could not be exported:",
        "tray_hidden", "Mouse Shortcuts is still running in the notification area.",
        "startup_failed", "Windows startup could not be updated:",
        "clipboard_busy", "The text could not be pasted because the clipboard is busy."
        , "legacy_title", "Older version detected"
        , "legacy_running", "An older Mouse Shortcuts version is still running. Close it now to prevent duplicate mouse actions?"
        , "legacy_declined", "Older version is still running"
        , "legacy_close_failed", "The older version could not be closed."
        , "takeover_failed", "Another Mouse Shortcuts instance is running and could not be replaced. Exit it from the tray, then try again."
        , "error_config_file", "The configuration file is invalid or incomplete."
        , "error_hotkey", "One selected key could not be activated. Detect it again or choose another key."
        , "error_storage", "Windows could not read or write the configuration file."
        , "error_system", "Windows could not update this system setting."
        , "error_unexpected", "The operation could not be completed."
    )
    static zh := Map(
        "app_name", "鼠标快捷键",
        "window_title", "鼠标快捷键 - 设置",
        "window_title_test", "鼠标快捷键 - 设置 [测试]",
        "tab_buttons", "鼠标按键",
        "tab_text", "文本快捷粘贴",
        "tab_general", "常规",
        "group_common", "常用按键",
        "group_more", "更多按键",
        "status_running", "正在运行",
        "status_paused", "已暂停",
        "status_stopped", "未启动",
        "status_error", "配置有问题",
        "column_button", "按键位置",
        "column_key", "检测到的按键",
        "column_action", "对应动作",
        "detect", "检测",
        "middle", "鼠标中键",
        "side_up", "侧上键",
        "side_down", "侧下键",
        "left_hold_voice", "启用左键静止长按语音输入",
        "left_hold_duration", "唤醒时长",
        "seconds", "秒",
        "left_hold_hint", "松开结束；计时完成前拖动会取消",
        "wheel_up", "滚轮向上",
        "wheel_down", "滚轮向下",
        "wheel_left", "侧滚轮向左",
        "wheel_right", "侧滚轮向右",
        "browser_back", "浏览器后退键",
        "browser_forward", "浏览器前进键",
        "vendor_1", "厂商自定义键 1",
        "vendor_2", "厂商自定义键 2",
        "extra_1", "额外按键 1",
        "extra_2", "额外按键 2",
        "extra_3", "额外按键 3",
        "extra_4", "额外按键 4",
        "action_disabled", "关闭",
        "action_voice", "语音输入",
        "action_enter", "回车",
        "action_backspace", "退格",
        "action_delete", "删除",
        "action_copy", "复制",
        "action_paste", "粘贴",
        "action_cut", "剪切",
        "action_select_all", "全选",
        "action_undo", "撤销",
        "action_redo", "重做",
        "action_escape", "退出 / Esc",
        "action_tab", "Tab 键",
        "action_space", "空格",
        "action_home", "行首",
        "action_end", "行尾",
        "action_page_up", "向上翻页",
        "action_page_down", "向下翻页",
        "action_browser_back", "返回上一页",
        "action_browser_forward", "前进下一页",
        "action_desktop", "显示桌面",
        "action_lock", "锁定电脑",
        "action_snip", "屏幕截图",
        "action_volume_mute", "静音",
        "action_volume_down", "减小音量",
        "action_volume_up", "增大音量",
        "action_media_play_pause", "播放 / 暂停",
        "action_media_next", "下一首",
        "action_media_prev", "上一首",
        "action_media_stop", "停止播放",
        "text_slot", "文本快捷键 {}",
        "shortcut", "快捷键",
        "record", "录制",
        "clear", "清除",
        "not_set", "未设置",
        "language", "界面语言",
        "language_chinese", "中文",
        "language_english", "English",
        "autostart", "登录 Windows 后自动启动",
        "export", "导出配置",
        "import", "导入配置",
        "restore_defaults", "恢复默认设置",
        "save_apply", "保存并立即生效",
        "hide_to_tray", "隐藏到托盘",
        "settings", "打开设置",
        "pause", "暂停",
        "resume", "恢复",
        "exit", "退出",
        "saved_applied", "设置已保存并立即生效。",
        "save_failed", "设置无法生效：",
        "config_error", "已保存的配置存在问题。",
        "duplicate_trigger", "两个已启用的功能使用了同一个按键或快捷键：",
        "missing_key", "请为每一个可见按键行选择按键。",
        "unknown_action", "有一个动作不受支持。",
        "empty_snippet", "请填写文本快捷键 {} 的内容，或清除它的快捷键。",
        "possible_conflict_title", "快捷键可能冲突",
        "possible_conflict", "以下快捷键可能已被 Windows 或其他软件占用：`n`n{}`n`n仍然保存吗？",
        "capture_title", "检测按键",
        "capture_key", "现在请按一下鼠标按键或厂商自定义键。",
        "capture_shortcut", "先按住 Ctrl、Alt、Shift 或 Win，再按快捷键或鼠标按键。",
        "capture_vendor_hint", "如果没有检测结果，请在鼠标厂商软件中把该按键设为 F13-F24。",
        "cancel", "取消",
        "detected", "已检测：{}",
        "defaults_confirm", "恢复默认鼠标按键、关闭开机启动并清空全部文本快捷键吗？",
        "defaults_title", "恢复默认设置",
        "import_title", "导入鼠标快捷键配置",
        "export_title", "导出鼠标快捷键配置",
        "import_ok", "配置已导入并立即生效。",
        "import_failed", "无法导入此配置：",
        "export_ok", "配置已导出。",
        "export_failed", "无法导出配置：",
        "tray_hidden", "鼠标快捷键仍在右下角通知区域运行。",
        "startup_failed", "无法更新开机启动：",
        "clipboard_busy", "剪贴板正忙，文本未能粘贴。"
        , "legacy_title", "检测到旧版本"
        , "legacy_running", "旧版鼠标快捷键仍在运行。为避免同一按键执行两次，现在关闭旧版并继续吗？"
        , "legacy_declined", "旧版本仍在运行"
        , "legacy_close_failed", "无法关闭旧版本。"
        , "takeover_failed", "另一个鼠标快捷键实例仍在运行，暂时无法接管。请先从托盘退出旧实例后重试。"
        , "error_config_file", "配置文件无效或内容不完整。"
        , "error_hotkey", "有一个按键无法启用。请重新检测该按键，或换一个按键。"
        , "error_storage", "Windows 无法读取或写入配置文件。"
        , "error_system", "Windows 无法更新此系统设置。"
        , "error_unexpected", "无法完成此操作。"
    )
    dictionary := gLanguage = "zh-CN" ? zh : en
    return dictionary.Has(key) ? dictionary[key] : key
}

TF(key, values*) {
    text := T(key)
    for value in values {
        text := StrReplace(text, "{}", value, true, , 1)
    }
    return text
}

ActionDisplayName(actionId) {
    return T("action_" actionId)
}

FormatHotkeyForDisplay(hotkeyName) {
    if IsDisabled(hotkeyName) {
        return T("not_set")
    }
    parts := []
    if InStr(hotkeyName, "^")
        parts.Push("Ctrl")
    if InStr(hotkeyName, "!")
        parts.Push("Alt")
    if InStr(hotkeyName, "+")
        parts.Push("Shift")
    if InStr(hotkeyName, "#")
        parts.Push("Win")
    keyName := RegExReplace(hotkeyName, "[\^!+#~*$<>]")
    if (keyName != "")
        parts.Push(keyName)

    display := ""
    for part in parts {
        display .= (display = "" ? "" : "+") part
    }
    return display != "" ? display : hotkeyName
}
