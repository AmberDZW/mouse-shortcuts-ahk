#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

logFile := A_ScriptDir "\key-test.log"
if FileExist(logFile) {
    FileDelete(logFile)
}
FileAppend("Press the problem buttons now. Close this script from the tray icon when done.`n", logFile, "UTF-8")

Log(name) {
    global logFile
    stamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(stamp "  " name "`n", logFile, "UTF-8")
    ToolTip("Detected: " name)
    SetTimer(() => ToolTip(), -800)
}

~XButton1::Log("XButton1")
~XButton2::Log("XButton2")
~MButton::Log("MButton")
~Browser_Back::Log("Browser_Back")
~Browser_Forward::Log("Browser_Forward")
~Launch_App1::Log("Launch_App1")
~Launch_App2::Log("Launch_App2")
~F13::Log("F13")
~F14::Log("F14")
~F15::Log("F15")
~F16::Log("F16")
~F17::Log("F17")
~F18::Log("F18")
~F19::Log("F19")
~F20::Log("F20")
~F21::Log("F21")
~F22::Log("F22")
~F23::Log("F23")
~F24::Log("F24")
~Delete::Log("Delete")
~Insert::Log("Insert")
~Home::Log("Home")
~End::Log("End")
~PgUp::Log("PgUp")
~PgDn::Log("PgDn")
