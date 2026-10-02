# Mouse Shortcuts

## 解压后直接使用

1. 下载 [MouseShortcuts-1.0.2.zip](https://github.com/AmberDZW/mouse-shortcuts-ahk/releases/download/v1.0.2/MouseShortcuts-1.0.2.zip) 并**完整解压**。
2. 双击解压目录中的 `MouseShortcuts.exe`。
3. 不需要安装 AutoHotkey，也不需要安装其他运行环境。

> 不要直接在压缩包预览窗口里运行。请先解压整个文件夹，再双击 `MouseShortcuts.exe`。

Mouse Shortcuts 是面向普通 Windows 用户的鼠标快捷键和常用文本工具。发布包只有一个程序入口，不包含需要用户选择的脚本、命令文件或配置文件。

## 默认按键

- 左键静止长按 2 秒：语音输入 `Win+H`，每次按住只触发一次；拖拽会取消长按计时。
- 鼠标中键：语音输入 `Win+H`
- 侧上键：回车
- 侧下键：退格

滚轮、侧滚轮、浏览器键和扩展键会显示在设置中，但默认不启用。

## 设置与托盘

双击 `MouseShortcuts.exe` 可打开设置窗口。界面支持中文和 English，并会记住上次使用的语言。

可以在设置窗口中：

- 为每个可识别的鼠标按键选择动作。
- 录入和检测按键，不需要填写 AutoHotkey 语法。
- 保存至少五组中文、英文或多行常用文本。
- 查看重复按键和可能的快捷键冲突。
- 开启或关闭 Windows 开机启动。
- 恢复默认设置，或导入、导出配置。
- 保存并立即应用设置。

程序运行后会常驻 Windows 右下角托盘。托盘菜单可打开设置、暂停、恢复或退出，并显示当前运行状态。

## 配置与升级

个人设置保存在 `%LOCALAPPDATA%\MouseShortcuts\settings.msconfig`，不放在发布包内。安装新版本时解压并运行新的 `MouseShortcuts.exe`，原有按键、语言和常用文本会继续保留。

从 0.7 升级时，工具会优先自动查找相邻旧目录、正在运行的旧版或旧版开机启动位置。如果旧版放在其他目录，也可以在“导入配置”中直接选择旧的 `mouse-remap.ini`。

导出的配置可能包含个人常用文本。分享配置文件前请检查内容。

## 支持的按键范围

工具支持中键、侧键、滚轮、侧滚轮、浏览器键，以及 Windows 能识别的媒体键、启动键和 F13-F24 等扩展键。厂商专用按键需要先由鼠标驱动暴露为 Windows 可识别的按键；完全封闭的专有硬件信号无法保证通用识别。

## 源码构建

最终用户不需要本节中的工具。维护者构建说明见 [PUBLISHING.md](PUBLISHING.md)，发布验证运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\Release.Tests.ps1
```

## License

Mouse Shortcuts 源码使用 MIT License。编译后的便携程序包含 AutoHotkey v2 运行时；完整第三方说明和 AutoHotkey 许可证文本位于发布包的 `THIRD_PARTY_NOTICES.txt`。
