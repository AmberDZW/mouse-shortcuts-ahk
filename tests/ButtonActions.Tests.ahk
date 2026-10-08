#Requires AutoHotkey v2.0
#Include ..\src\Core.ahk
#Include ..\src\ButtonActions.ahk

checks := 0
sent := []
SendConfiguredAction(action, *) {
    global sent
    sent.Push(action)
}

AssertEqual(actual, expected, message) {
    global checks
    checks++
    if actual != expected {
        throw Error(message " (expected=" expected ", actual=" actual ")")
    }
}

NewPress(key := "RButton", clickAction := "disabled", holdAction := "voice", duration := 500) {
    return CreateButtonPress({key: key, action: clickAction, holdAction: holdAction, holdMs: duration}, 10, 20, 1000, 4, 4)
}

try {
    press := NewPress()
    AssertEqual(AdvanceButtonPress(press, 10, 20, 1499), "", "No early activation")
    AssertEqual(AdvanceButtonPress(press, 10, 20, 1500), "hold", "Activation at selected delay")
    AssertEqual(AdvanceButtonPress(press, 10, 20, 9000), "", "Continued hold fires once")
    AssertEqual(ButtonReleaseAction(press), "voice", "Voice ends on release without native click")
    AssertEqual(ButtonReleaseAction(NewPress()), "native", "Short right click retains native context menu")

    press := NewPress("XButton1", "backspace", "copy", 1500)
    AssertEqual(ButtonReleaseAction(press), "backspace", "Short side click uses its click action")
    AssertEqual(AdvanceButtonPress(press, 10, 20, 2499), "", "Independent per-button delay")
    AssertEqual(AdvanceButtonPress(press, 10, 20, 2500), "hold", "Long side press uses hold branch")
    AssertEqual(ButtonReleaseAction(press), "", "Long side press does not also backspace or repeat copy")

    press := NewPress()
    AssertEqual(AdvanceButtonPress(press, 14, 20, 1100), "drag", "Movement cancels before delay")
    AssertEqual(AdvanceButtonPress(press, 10, 20, 6000), "", "Returning after dragging cannot revive hold")
    AssertEqual(ButtonReleaseAction(press), "", "Cancelled gesture produces no shortcut")
    press := NewPress()
    AssertEqual(AdvanceButtonPress(press, 20, 30, 2000), "drag", "Movement takes precedence over elapsed delay")

    press := NewPress("F13", "copy", "paste")
    AssertEqual(AdvanceButtonPress(press, 200, 300, 1500), "hold", "Non-mouse keys are not cancelled by mouse movement")

    mapping := NewPress().mapping
    hooks := RegisterButtonActions(mapping)
    AssertEqual(hooks[1], "$*RButton", "Runtime registers right down hook only")
    AssertEqual(hooks[2], "$*RButton Up", "Runtime registers right up hook")
    for hook in hooks {
        Hotkey(hook, "Off")
    }
    gButtonPresses["RButton"] := NewPress()
    gButtonPresses["RButton"].fired := true
    FinishButtonPress("RButton")
    AssertEqual(sent.Length, 1, "Runtime release emits one stop action")
    AssertEqual(sent[1], "voice", "Runtime voice stop action")
    FinishButtonPress("RButton")
    AssertEqual(sent.Length, 1, "Duplicate releases cannot stop twice")
    gButtonPresses["XButton1"] := NewPress("XButton1", "enter", "copy")
    FinishButtonPress("XButton1")
    AssertEqual(sent[2], "enter", "Runtime short side press emits click action")
    gButtonPresses["RButton"] := NewPress()
    gButtonPresses["RButton"].fired := true
    gButtonPresses["MButton"] := NewPress("MButton", "enter", "copy")
    CancelButtonPresses()
    AssertEqual(gButtonPresses.Count, 0, "Pause/save/exit clears pending gestures")
    AssertEqual(sent.Length, 3, "Cancellation stops active voice without firing pending short click")
    FileAppend("PASS: ButtonActions.Tests (" checks " checks)`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "**")
    ExitApp(1)
} finally {
    CancelButtonPresses()
}
