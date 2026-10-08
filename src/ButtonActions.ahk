#Requires AutoHotkey v2.0

global gButtonPresses := Map()

CreateButtonPress(mapping, x, y, now, dragX, dragY) {
    return {mapping: mapping, x: x, y: y, startedAt: now, dragX: dragX, dragY: dragY,
        mouse: RegExMatch(mapping.key, "i)^(RButton|MButton|XButton1|XButton2)$"),
        fired: false, cancelled: false, nativeDown: false}
}

AdvanceButtonPress(press, x, y, now) {
    if press.fired || press.cancelled {
        return ""
    }
    if press.mouse && (Abs(x - press.x) >= press.dragX || Abs(y - press.y) >= press.dragY) {
        press.cancelled := true
        return "drag"
    }
    if (now - press.startedAt < press.mapping.holdMs) {
        return ""
    }
    press.fired := true
    return "hold"
}

ButtonReleaseAction(press) {
    if press.cancelled {
        return ""
    }
    if press.fired {
        return press.mapping.holdAction = "voice" ? "voice" : ""
    }
    return IsDisabled(press.mapping.action) ? "native" : press.mapping.action
}

RegisterButtonActions(mapping) {
    down := "$*" mapping.key
    up := down " Up"
    Hotkey(down, BeginButtonPress.Bind(mapping), "On")
    try Hotkey(up, FinishButtonPress.Bind(mapping.key), "On")
    catch {
        Hotkey(down, "Off")
        throw
    }
    return [down, up]
}

BeginButtonPress(mapping, *) {
    global gButtonPresses
    if gButtonPresses.Has(mapping.key) {
        return
    }
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    gButtonPresses[mapping.key] := CreateButtonPress(mapping, x, y, A_TickCount, SysGet(68), SysGet(69))
    SetTimer(CheckButtonPresses, 20)
}

CheckButtonPresses() {
    global gButtonPresses
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    Critical("On")
    released := []
    for key, press in gButtonPresses {
        if !GetKeyState(key, "P") {
            released.Push(key)
            continue
        }
        event := AdvanceButtonPress(press, x, y, A_TickCount)
        if (event = "hold") {
            SendConfiguredAction(press.mapping.holdAction)
        } else if (event = "drag") {
            SendEvent("{Blind}{" key " down}")
            press.nativeDown := true
        }
    }
    for key in released {
        FinishButtonPress(key)
    }
    Critical("Off")
}

FinishButtonPress(key, *) {
    global gButtonPresses
    if !gButtonPresses.Has(key) {
        return
    }
    Critical("On")
    press := gButtonPresses[key]
    gButtonPresses.Delete(key)
    if !gButtonPresses.Count {
        SetTimer(CheckButtonPresses, 0)
    }
    if press.nativeDown {
        SendEvent("{Blind}{" key " up}")
    } else {
        action := ButtonReleaseAction(press)
        if (action = "native") {
            SendEvent("{Blind}{" key "}")
        } else if (action != "") {
            SendConfiguredAction(action)
        }
    }
    Critical("Off")
}

CancelButtonPresses() {
    global gButtonPresses
    SetTimer(CheckButtonPresses, 0)
    for key, press in gButtonPresses {
        if press.nativeDown {
            SendEvent("{Blind}{" key " up}")
        }
        if (press.fired && press.mapping.holdAction = "voice") {
            SendConfiguredAction("voice")
        }
    }
    gButtonPresses := Map()
}
