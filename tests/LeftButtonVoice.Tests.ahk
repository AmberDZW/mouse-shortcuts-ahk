#Requires AutoHotkey v2.0
#Include ..\src\LeftButtonVoice.ahk

checks := 0

AssertTrue(value, message) {
    global checks
    checks += 1
    if !value {
        throw Error(message)
    }
}

StartPress() {
    global gLeftButtonPress
    EndLeftButtonVoice(false)
    BeginLeftButtonVoice()
    SetTimer(CheckLeftButtonVoice, 0)
    return gLeftButtonPress
}

try {
    press := StartPress()
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 1999),
        "Must not trigger before two seconds")
    AssertTrue(UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 2000),
        "Must trigger at two seconds")
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 4000),
        "A continued hold must not trigger twice")
    AssertTrue(EndLeftButtonVoice(false), "Releasing an active hold must stop voice typing")
    AssertTrue(!IsObject(gLeftButtonPress), "Release must clear the active hold")

    press := StartPress()
    AssertTrue(!UpdateLeftButtonVoice(false, press.x, press.y, press.startedAt + 500, false),
        "A short click must not trigger")
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 2000),
        "Released clicks must not leave a pending trigger")

    press := StartPress()
    AssertTrue(!UpdateLeftButtonVoice(true, press.x + press.dragX, press.y, press.startedAt + 100),
        "Dragging must cancel the gesture")
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 2000),
        "Returning the pointer after dragging must not revive the gesture")

    press := StartPress()
    Suspend(true)
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 2000, false),
        "Suspending shortcuts must cancel the gesture")
    Suspend(false)
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 3000),
        "Resuming must not fire a previously cancelled hold")

    press := StartPress()
    AssertTrue(UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 2000),
        "A fresh hold must trigger again")

    press := StartPress()
    AssertTrue(!UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 1499, true, 1500),
        "A configured 1.5-second hold must not trigger early")
    AssertTrue(UpdateLeftButtonVoice(true, press.x, press.y, press.startedAt + 1500, true, 1500),
        "A configured 1.5-second hold must trigger at its selected duration")
    EndLeftButtonVoice(false)

    registered := RegisterLeftButtonVoice(1500)
    AssertTrue(registered.Length = 2, "Both pass-through mouse hooks must register")
    AssertTrue(gLeftButtonVoiceHoldMs = 1500, "Registration must apply the selected hold duration")
    for specification in registered {
        Hotkey(specification, "Off")
    }
    FileAppend("PASS: LeftButtonVoice.Tests (" checks " checks)`n", "*", "UTF-8")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: LeftButtonVoice.Tests: " err.Message "`n", "**", "UTF-8")
    ExitApp(1)
} finally {
    Suspend(false)
    EndLeftButtonVoice(false)
}
