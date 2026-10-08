Mouse Shortcuts / 鼠标快捷键工具
================================

把每天反复用到的动作，放到手边的鼠标上。

Mouse Shortcuts is a small Windows tray app for mouse shortcuts and saved text.
鼠标快捷键工具可将常用动作和文本放到鼠标按键上。

快速开始：先解压 MouseShortcuts-1.0.4.zip，再双击 MouseShortcuts.exe。
不要直接在压缩包内运行。不需要安装 AutoHotkey，打开程序后按键功能会自动启动。
Extract the zip, then double-click MouseShortcuts.exe. No separate installation is needed.

默认按键 / Default controls
---------------------------

- 右键静止长按 2 秒：启动 Windows 语音输入（Win+H）；松开后结束本次语音输入。
- Hold the right button still for 2 seconds to start Windows Voice Typing; release to end the session.
- 鼠标中键 / Middle button：语音输入 / Voice Typing（Win+H）
- 侧上键 / Upper side button：回车 / Enter
- 侧下键 / Lower side button：退格 / Backspace

左键正常点击和选字，不绑定长按语音。右键短按保留菜单，长按触发后不会再弹菜单。
Left clicks and text selection stay unchanged. Short right clicks open the context menu; holds suppress it.

快速开始 / Quick start
---------------------

1. 完整解压 MouseShortcuts-1.0.4.zip。
   Fully extract MouseShortcuts-1.0.4.zip.
2. 双击 MouseShortcuts.exe。
   Double-click MouseShortcuts.exe.
3. 单击托盘图标打开设置。关闭设置窗口后，按键功能继续在后台运行。
   Click the tray icon to open Settings. Shortcuts keep running when Settings is closed.

不需要单独安装 AutoHotkey。设置保存在当前 Windows 用户目录中，更新程序不会覆盖它们。
No separate AutoHotkey installation is required. Settings stay in your Windows user profile across app updates.

在设置中可修改按键、检测鼠标按键、管理五条多语言/多行文本，或启用开机启动。
每个按键可以分别设置单击、长按动作和 0.5–5 秒长按时间；滚轮只支持单次动作。
单击动作关闭时保留原按键；长按动作关闭时只执行单击。点击“保存并立即生效”应用设置。
Configure click and hold actions separately, with per-button hold durations. Wheel directions support click actions only.
Use Settings to change mappings, detect buttons, manage five Unicode/multiline text snippets, and optionally start with Windows.

个人设置保存在 `%LOCALAPPDATA%\MouseShortcuts\settings.msconfig`，更新程序不会覆盖。托盘菜单可打开设置、暂停、恢复或退出。
Settings are stored in your Windows user profile and persist across updates. Use the tray menu to open Settings, pause, resume, or exit.

如果旧版设置没有自动迁移，可在设置中导入 `mouse-remap.ini`。
If settings from a legacy copy are not found automatically, import its `mouse-remap.ini` from Settings.

语音输入由 Windows Voice Typing 处理。旧版左键语音的开关、时长会迁到右键；其他个人设置保留。
Windows handles voice input. Mouse Shortcuts sends Win+H and does not record audio itself.

许可 / License: MIT. AutoHotkey notices are included in THIRD_PARTY_NOTICES.txt.
更多信息 / More: https://github.com/AmberDZW/mouse-shortcuts-ahk
