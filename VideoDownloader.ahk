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
    }
    Return
}

; Runs a list of commands when the script is launched.
onInit()
{
    global ffmpegLocation := A_WorkingDir . "\files\library\ffmpeg.exe"
    global youTubeBackGroundLocation := A_WorkingDir . "\files\library\YouTubeBackground.jpg"

    If (!DirExist(A_WorkingDir . "\files\library"))
    {
        result := MsgBox("No library files detected.`n`nWould you like to run a complete setup?",
            "youtube-dlp-autohotkey-gui setup", "OC Icon? 4096")
        Switch (result)
        {
            Case "OK":
                {
                    setUp()
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
    result := MsgBox("The next steps require an established internet connection.`n`nPress Okay to continue.", "Script setup status", "OC Iconi 4096")
    Switch (result)
    {
        Case "Cancel":
            {
                ExitApp()
            }
    }
    If (setup_checkPythonVersion() = true)
    {
        ; Will install the latest version of yt-dlp from GitHub.
        Run(A_ComSpec " /k py -m pip install --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz", , , &consolePID)
        Sleep(2000)
        Try
        {
            While (WinGetTitle("ahk_pid " . consolePID) != A_ComSpec)
            {
                Sleep(500)
            }
            Sleep(2000)
            WinClose("ahk_pid " . consolePID)
        }
        WinWaitClose("ahk_pid " . consolePID)
        Try
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
            ; Creates a blacklist file without showing a prompt to the user.
            checkBlackListFile("createBlackListFile", false)
            result := MsgBox("Installation completed!`n`nWould you like to open README file?",
                "Script setup status", "OC Iconi 4096")
            Switch (result)
            {
                Case "OK":
                    {
                        Run("https://github.com/LeoTN/yt-dlp-autohotkey-gui#video-downloader-with-basic-autohotkey-gui")
                    }
            }
        }
    }
}

setup_checkPythonVersion()
{
    Try
    {
        FileDelete(A_Temp . "\python_install_log.txt")
    }
    RunWait(A_ComSpec " /c python --version > " . A_Temp . "\python_install_log.txt")
    Sleep(500)
    ; This occures when the command does not achieve anything => python is not installed.
    If (FileRead(A_Temp . "\python_install_log.txt") = "")
    {
        result := MsgBox("No valid PYTHON installation found.`n`nWould you like to install PYTHON now?",
            "Script setup status", "OC Iconi 4096")
        Switch (result)
        {
            Case "OK":
                {
                    Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements',
                        , , &consolePID)
                    Sleep(2000)
                    Try
                    {
                        While (WinGetTitle("ahk_pid " . consolePID) != A_ComSpec)
                        {
                            Sleep(500)
                        }
                        Sleep(2000)
                        WinClose("ahk_pid " . consolePID)
                    }
                    Catch
                    {
                        ExitApp()
                    }
                    Return setup_checkPythonVersion()
                }
            Case "Cancel":
                {
                    ExitApp()
                }
        }
    }
    Loop Read (A_Temp . "\python_install_log.txt")
    {
        Loop Parse (A_LoopReadLine)
        {
            ; Scanns the output from the console and extracts the python version.
            If (RegExMatch(A_LoopReadLine, "[0-9]+.[0-9]+.[0-9]+", &outMatch) != 0)
            {
                outString := outMatch[]
                ; The minimum recommended python version to run yt-dlp smooth.
                minimumPythonVersion := "3.8.0"
                pythonVersion := outString
                If (VerCompare(pythonVersion, minimumPythonVersion) < 0)
                {
                    result := MsgBox("Outdated PYTHON installation detected.`n"
                        "Found : (Python " . outString . ")`nRequired : (" . minimumPythonVersion . " or higher)"
                        "`nWould you like to update it?",
                        "Script setup status", "OC Iconi 4096")
                    Switch (result)
                    {
                        Case "OK":
                            {
                                ; Runs the uninstall console with admin rights.
                                tmpString1 := RegExReplace(outString, ".[0-9]$")
                                tmpString2 := ' /c winget uninstall "python ' . tmpString1 . '"'
                                tmpString3 := '*RunAs "' A_ComSpec . '"' . tmpString2
                                Try
                                {
                                    RunWait(tmpString3)
                                }
                                Catch
                                {
                                    ExitApp()
                                }
                                Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements',
                                    , , &consolePID)
                                Sleep(2000)
                                Try
                                {
                                    while (WinGetTitle("ahk_pid " . consolePID) != A_ComSpec)
                                    {
                                        Sleep(500)
                                    }
                                    Sleep(2000)
                                    WinClose("ahk_pid " . consolePID)
                                }
                                Catch
                                {
                                    ExitApp()
                                }
                                Return setup_checkPythonVersion()
                            }
                        Case "Cancel":
                            {
                                ExitApp()
                            }
                    }
                }
                Else
                {
                    Return true
                }
            }
        }
    }
    Return
}