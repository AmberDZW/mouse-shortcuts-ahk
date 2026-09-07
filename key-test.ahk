#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook true

if (A_Args.Length > 0 && A_Args[1] = "--check") {
    ExitApp(0)
}

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
~WheelUp::Log("WheelUp")
~WheelDown::Log("WheelDown")
~WheelLeft::Log("WheelLeft")
~WheelRight::Log("WheelRight")
~Browser_Back::Log("Browser_Back")
~Browser_Forward::Log("Browser_Forward")
~Browser_Home::Log("Browser_Home")
~Browser_Search::Log("Browser_Search")
~Browser_Favorites::Log("Browser_Favorites")
~Browser_Refresh::Log("Browser_Refresh")
~Browser_Stop::Log("Browser_Stop")
~Launch_App1::Log("Launch_App1")
~Launch_App2::Log("Launch_App2")
~Launch_Mail::Log("Launch_Mail")
~Launch_Media::Log("Launch_Media")
~Media_Play_Pause::Log("Media_Play_Pause")
~Media_Next::Log("Media_Next")
~Media_Prev::Log("Media_Prev")
~Media_Stop::Log("Media_Stop")
~Volume_Mute::Log("Volume_Mute")
~Volume_Down::Log("Volume_Down")
~Volume_Up::Log("Volume_Up")
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
