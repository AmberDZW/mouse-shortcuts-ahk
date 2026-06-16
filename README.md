# Mouse Shortcuts

一个轻量的 Windows 鼠标按键重映射工具，基于 AutoHotkey v2。它适合把鼠标侧键、中键、厂商驱动暴露出来的特殊键，改成 Enter、Backspace、Delete、复制、粘贴、Win+H 等常用动作。

## 安装

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 下载本项目。
3. 双击 `start-mouse-remap.cmd`。
4. 要停止时双击 `stop-mouse-remap.cmd`。

## 修改鼠标按键

编辑 `mouse-remap.ini`：

```ini
[Mappings]
XButton2=enter
XButton1=backspace
MButton=voice

[Actions]
enter={Enter}
backspace={Backspace}
voice=#h
copy=^c
paste=^v
```

`[Mappings]` 左边是鼠标按键名，右边是动作名。

`[Actions]` 里可以定义动作名对应的 AutoHotkey `SendInput` 内容。

常用写法：

| 动作 | 写法 |
| --- | --- |
| Enter | `{Enter}` |
| Backspace | `{Backspace}` |
| Delete | `{Delete}` |
| Ctrl+C | `^c` |
| Ctrl+V | `^v` |
| Ctrl+X | `^x` |
| Win+H | `#h` |
| Win+D | `#d` |
| Alt+Left | `!{Left}` |

## 不知道鼠标键叫什么

运行：

```bat
key-test.ahk
```

然后按一下有问题的鼠标键。检测结果会写入：

```text
key-test.log
```

把日志里看到的键名填进 `mouse-remap.ini` 的 `[Mappings]` 左边即可。

常见键名：

- `XButton1`
- `XButton2`
- `MButton`
- `Browser_Back`
- `Browser_Forward`
- `Launch_App1`
- `Launch_App2`
- `F13` 到 `F24`

## 默认配置

默认配置适配一个常见侧键方案：

- `XButton2`：Enter
- `XButton1` / `Browser_Back` / `Launch_App1`：Backspace
- `MButton`：Win+H

## 检查配置

```bat
"%LOCALAPPDATA%\Programs\AutoHotkey\v2\AutoHotkey64.exe" /ErrorStdOut mouse-remap.ahk --check
```

看到 `mouse-remap config OK` 就说明配置文件能读取。

## License

MIT
