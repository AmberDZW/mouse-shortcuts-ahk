#Requires AutoHotkey v2.0

global gLeftButtonPress := 0
global gLeftButtonVoiceHoldMs := 2000

RegisterLeftButtonVoice(holdDurationMs := 2000) {
    global gLeftButtonVoiceHoldMs
    gLeftButtonVoiceHoldMs := holdDurationMs
    Hotkey("~*LButton", BeginLeftButtonVoice, "On")
    try Hotkey("~*LButton Up", CancelLeftButtonVoice, "On")
    catch {
        Hotkey("~*LButton", "Off")
        throw
    }
    return ["~*LButton", "~*LButton Up"]
}

BeginLeftButtonVoice(*) {
    global gLeftButtonPress
    EndLeftButtonVoice(false)
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    gLeftButtonPress := {startedAt: A_TickCount, x: x, y: y,
        dragX: SysGet(68), dragY: SysGet(69), activated: false}
    SetTimer(CheckLeftButtonVoice, 20)
}

CancelLeftButtonVoice(*) {
    EndLeftButtonVoice()
}

EndLeftButtonVoice(sendStop := true) {
    global gLeftButtonPress
    SetTimer(CheckLeftButtonVoice, 0)
    activated := IsObject(gLeftButtonPress) && gLeftButtonPress.activated
    gLeftButtonPress := 0
    if (activated && sendStop) {
        SendInput("#h")
    }
    return activated
}

UpdateLeftButtonVoice(held, x, y, now, stopVoiceOnCancel := true, holdDurationMs := 2000) {
    global gLeftButtonPress
    if !IsObject(gLeftButtonPress) {
        return false
    }
    if (gLeftButtonPress.activated) {
        return false
    }
    if (!held || A_IsSuspended
        || Abs(x - gLeftButtonPress.x) >= gLeftButtonPress.dragX
        || Abs(y - gLeftButtonPress.y) >= gLeftButtonPress.dragY) {
        EndLeftButtonVoice(stopVoiceOnCancel)
        return false
    }
    if (now - gLeftButtonPress.startedAt < holdDurationMs) {
        return false
    }
    gLeftButtonPress.activated := true
    SetTimer(CheckLeftButtonVoice, 0)
    return true
}

CheckLeftButtonVoice() {
    global gLeftButtonVoiceHoldMs
    CoordMode("Mouse", "Screen")
    MouseGetPos(&x, &y)
    Critical("On")
    if UpdateLeftButtonVoice(GetKeyState("LButton", "P"), x, y, A_TickCount,
        true, gLeftButtonVoiceHoldMs) {
        SendInput("#h")
    }
    Critical("Off")
}
