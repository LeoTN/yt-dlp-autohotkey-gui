; NOTE : This is the main .ahk file which has to be started !!!
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Client"
#MaxThreadsPerHotkey 1
#Warn Unreachable, Off

; Imports important functions and variables
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFileManager.ahk"
#Include "HotKeys & Methods.ahk"
#Include "FileManager.ahk"
#Include "GUI.ahk"
#Include "DownloadOptionsGUI.ahk"
onInit()

/*
DEBUG SECTION
-------------------------------------------------
Add debug hotkeys here.
*/

; Debug hotkey template.
F6::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below.
        A_Clipboard := buildCommandString()
    }
    Return
}

F7::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below
        startDownload(buildCommandString(), true)
    }
    Return
}

; Runs a list of commands when the script is launched.
onInit()
{
    global ffmpegLocation := A_WorkingDir . "\files\library\ffmpeg.exe"
    global youTubeBackGroundLocation := A_WorkingDir . "\files\library\YouTubeBackground.jpg"
    ; If there is no config file it is likely that the user executes the script for the first time.
    If (!FileExist(configFileLocation))
    {
        result := MsgBox("Unable to find a config file in the default location.`n`n"
            "Press YES, if you would like to run a complete setup.`n`n"
            "In case you just want to create a default config file press NO.", "No config file found !", "YNC Iconi 4096")
        Switch (result)
        {
            Case "Yes":
                {
                    setUp()
                }
            Case "No":
                {
                    createDefaultConfigFile()
                }
            Case "Cancel":
                {
                    ExitApp()
                }
        }
    }
    ; Only called to check the config file status.
    readConfigFile("booleanDebugMode")
    checkBlackListFile("createBlackListFile")
    Hotkey_onInit()
    mainGUI_onInit()
    optionsGUI_onInit()
}

; Guides the user through a bunch of prompts and helps to install the script.
setUp()
{
    If (!DirExist(A_WorkingDir . "\files\library"))
    {
        DirCreate(A_WorkingDir . "\files\library")
    }
    FileInstall("files\library\YouTubeBackground.jpg", youTubeBackGroundLocation, 1)
    ; Required for yt-dlp to operate with extra functionallity.
    FileInstall("files\library\ffmpeg.exe", ffmpegLocation, 1)
    FileInstall("files\library\ffplay.exe", A_WorkingDir . "\files\library\ffplay.exe", 1)
    FileInstall("files\library\ffprobe.exe", A_WorkingDir . "\files\library\ffprobe.exe", 1)
    MsgBox("Successfully installed library contents.", "Installation status", "O Iconi T2")

    createDefaultConfigFile()
    checkBlackListFile("createBlackListFile", false)
}