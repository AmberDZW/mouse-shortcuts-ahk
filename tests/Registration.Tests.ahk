#Requires AutoHotkey v2.0
#Include ..\src\Core.ahk
#Include ..\src\Translations.ahk
#Include ..\src\App.ahk

checks := 0
AssertTrue(value, message) {
    global checks
    checks++
    if !value {
        throw Error(message)
    }
}
HasHook(name) {
    global gActiveHotkeys
    for hook in gActiveHotkeys {
        if hook = name {
            return true
        }
    }
    return false
}

try {
    config := CreateDefaultConfig("zh-CN")
    AssertTrue(RegisterConfigurationHotkeys(config).ok, "Default runtime hooks must register")
    AssertTrue(HasHook("$*RButton") && HasHook("$*RButton Up"), "Right press and release must both register")
    AssertTrue(HasHook("*MButton"), "Middle click retains its existing immediate action")
    for hook in gActiveHotkeys {
        AssertTrue(!InStr(hook, "LButton"), "Runtime must not hook left-button selection")
    }
    UnregisterConfigurationHotkeys()
    AssertTrue(gActiveHotkeys.Length = 0, "Reapply must retire previous hooks")
    config.mappings["side_up"].holdAction := "copy"
    config.mappings["side_up"].holdMs := 500
    AssertTrue(RegisterConfigurationHotkeys(config).ok, "Side-button click plus hold must register")
    AssertTrue(HasHook("$*XButton2 Up") && !HasHook("*XButton2"), "Dual actions must use one press/release gesture")
    UnregisterConfigurationHotkeys()
    config.mappings["right"].holdAction := "disabled"
    AssertTrue(RegisterConfigurationHotkeys(config).ok, "Disabled right hold must reapply")
    AssertTrue(!HasHook("$*RButton") && !HasHook("$*RButton Up"), "Disabled right hold must release the native button")
    FileAppend("PASS: Registration.Tests (" checks " checks)`n", "*")
    ExitApp(0)
} catch as err {
    FileAppend("FAIL: " err.Message "`n", "**")
    ExitApp(1)
} finally {
    UnregisterConfigurationHotkeys()
}
