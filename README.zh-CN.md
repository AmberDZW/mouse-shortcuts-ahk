# 鼠标快捷键工具

### 把每天反复用到的动作，放到手边的鼠标上。

[下载 v1.0.2](https://github.com/AmberDZW/mouse-shortcuts-ahk/releases/download/v1.0.2/MouseShortcuts-1.0.2.zip) · [English](README.md) · [更新记录](CHANGELOG.md)

Mouse Shortcuts 是一个常驻 Windows 托盘的小工具，可以把鼠标按键变成常用快捷动作：按住左键打开 Windows 语音输入，侧键发送回车或退格，也可以一键输入保存好的常用文本。

## 默认按键

| 鼠标操作 | 动作 |
| --- | --- |
| 左键静止长按 2 秒 | 启动 Windows 语音输入（`Win+H`）；松开后结束本次语音输入 |
| 鼠标中键 | 启动 Windows 语音输入（`Win+H`） |
| 侧上键 | 回车 |
| 侧下键 | 退格 |

左键点击仍会正常传给 Windows。指针移动到足以开始拖动时，长按计时会在触发前取消。左键长按说话是内置动作；中键和侧键映射可以在设置里修改。

## 为什么把它留在托盘里

- **少伸手找键盘。** 把复制、粘贴、撤销、媒体控制或浏览器前进后退，映射到手边常用的鼠标按键。
- **按住说话，松开结束。** 左键静止按住 2 秒启动 Windows 语音输入，松开左键结束本次语音输入。
- **常用文本一键输入。** 最多保存五条支持中文、Unicode 和多行内容的文本，并为每条设置自己的键盘快捷键。
- **不写脚本也能改。** 中文/English 设置界面可以检测按键、选择动作、提示快捷键冲突，并立即应用设置。
- **日常使用不挡手。** 工具收在 Windows 托盘里，可暂停/恢复，也可选择随 Windows 启动。

## 三步开始

1. 下载并完整解压 [`MouseShortcuts-1.0.2.zip`](https://github.com/AmberDZW/mouse-shortcuts-ahk/releases/download/v1.0.2/MouseShortcuts-1.0.2.zip)。
2. 双击 `MouseShortcuts.exe`。
3. 从托盘图标打开设置，修改按键或录入常用文本。

便携包已包含运行所需内容，不需要单独安装 AutoHotkey。个人设置保存在 `%LOCALAPPDATA%\MouseShortcuts\settings.msconfig`，与程序文件分开；换新版本不会覆盖你的按键、语言或文本。

## 按自己的习惯调整

设置界面提供常用鼠标键、滚轮方向、浏览器键、媒体键、启动键和 F13–F24。特殊按键需要鼠标驱动先将其呈现给 Windows，才能被识别；不确定按键名称时，可以使用内置检测功能。

你还可以：

- 将按键映射为常用键盘动作或 Windows 快捷键；
- 从托盘暂停、恢复工具；
- 选择是否随 Windows 启动；
- 导入或导出设置。

导出的设置文件可能包含你保存的文本，分享前请检查内容。

## 本地运行与语音输入

按键映射在本机执行，设置保存在本机。左键长按时，工具向 Windows 发送 `Win+H` 打开系统语音输入；麦克风权限与语音处理由 Windows 管理，Mouse Shortcuts 本身不录制音频。

程序不需要管理员权限或账号。鼠标按键能否使用，取决于 Windows 和鼠标驱动是否将它识别为受支持的按键。

## 开发与许可

源码使用 AutoHotkey v2。构建与打包要求见 [PUBLISHING.md](PUBLISHING.md)，开发说明见 [CONTRIBUTING.md](CONTRIBUTING.md)。

Mouse Shortcuts 使用 [MIT License](LICENSE)；发布包附带所需的 AutoHotkey 许可声明。

如果它替你省下了一些重复操作，点个 ⭐ 可以帮其他 Windows 用户发现这个项目。
