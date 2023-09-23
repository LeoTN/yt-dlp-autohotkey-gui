; NOTE: This is the main .ahk file which has to be started !!!
#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"
; Needs to stay at the start of the script.
; The scripts library and other not changed files.
global scriptBaseFilesLocation := onInit_handleScriptBaseFilesLocation()
; Creates the workingBaseFilesLocation variable.
; Has to be done before including all the other scripts because they will not work unless they have directory to work.
global workingBaseFilesLocation := onInit_handleWorkingBaseFilesLocation()
; Imports important functions and variables.
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
F5::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below.
        A_Clipboard := A_ComSpec ' /k ' . buildCommandString() . '> "' . readConfigFile("DOWNLOAD_LOG_FILE_LOCATION") . '"'
    }
}

F6::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below.
        scriptTutorial()
    }
}

F7::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below
        MsgBox("Hello there.")
    }
}

onInit_handleWorkingBaseFilesLocation()
{
    ; Very important, basically sets the script working directory !!!
    If (FileExist(A_Temp . "\video_downloader_choose_working_directory.txt"))
    {
        MsgBox("One last thing. Please select a folder to be used as the script working directory.`n"
            "This will be the place where all the downloads will go by default.`n`n"
            "Be careful because this cannot be changed later on.", "Choose a Working Directory", "OC Iconi")
        RegWrite(chooseScriptWorkingDirectory(), "REG_SZ",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation")
        FileDelete(A_Temp . "\video_downloader_choose_working_directory.txt")
        Reload()
    }
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation", "")
    If (regValue = "")
    {
        RegWrite(chooseScriptWorkingDirectory(), "REG_SZ",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation")
        Reload()
    }
    If (validatePath(regValue, false) = false)
    {
        result := MsgBox("Invalid working directory found in the registry editor.`n`n"
            "Press [Retry] to select it manually.", "Invalid Working Directory", "RC Icon!")
        Switch (result)
        {
            Case "Retry":
                {
                    RegWrite(chooseScriptWorkingDirectory(), "REG_SZ",
                        "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation")
                    Reload()
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
    Else
    {
        Return regValue
    }

}

onInit_handleScriptBaseFilesLocation()
{
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation", "")

    If (regValue = "" || validatePath(regValue, false) = false)
    {
        result := MsgBox("Invalid script directory found in the registry editor.`n`n"
            "Replace it with the current directory the script runs in?", "Invalid Script Directory", "YN Icon!")
        Switch (result)
        {
            Case "Yes":
                {
                    If (!InStr(A_WorkingDir, "yt_dlp_autohotkey_gui_files"))
                    {
                        RegWrite(A_WorkingDir . "\yt_dlp_autohotkey_gui_files", "REG_SZ",
                            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation")
                    }
                    Else
                    {
                        RegWrite(A_WorkingDir, "REG_SZ",
                            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation")
                    }
                    Reload()
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
    ; Prepares both strings for a comparison.
    Else If (!InStr(A_WorkingDir, "yt_dlp_autohotkey_gui_files"))
    {
        tmpWorkingDir := A_WorkingDir . "\yt_dlp_autohotkey_gui_files"
    }
    Else
    {
        tmpWorkingDir := A_WorkingDir
    }
    If (!InStr(regValue, "yt_dlp_autohotkey_gui_files"))
    {
        tmpRegValue := regValue . "\yt_dlp_autohotkey_gui_files"
    }
    Else
    {
        tmpRegValue := regValue
    }
    ; Checks if the path in the registry is correct.
    If (tmpWorkingDir != tmpRegValue)
    {
        result := MsgBox("Different script directory found in the registry editor.`n`n"
            "Replace it with the current directory the script runs in?", "Invalid Script Directory", "YN Icon!")
        Switch (result)
        {
            Case "Yes":
                {
                    If (!InStr(A_WorkingDir, "yt_dlp_autohotkey_gui_files"))
                    {
                        RegWrite(A_WorkingDir . "\yt_dlp_autohotkey_gui_files", "REG_SZ",
                            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation")
                    }
                    Else
                    {
                        RegWrite(A_WorkingDir, "REG_SZ",
                            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation")
                    }
                    Reload()
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
    Return regValue
}

; Runs a list of commands when the script is launched.
onInit()
{
    global ffmpegLocation := scriptBaseFilesLocation . "\library\FFmpeg\ffmpeg.exe"
    global youTubeBackGroundLocation := scriptBaseFilesLocation . "\library\YouTubeBackground.jpg"

    ; Checks the system for other already running instances of this script.
    findProcessWithWildcard("VideoDownloader.exe")

    If (!FileExist(ffmpegLocation))
    {
        If (A_IsCompiled = false)
        {
            MsgBox("You are using the a non compiled version of this script."
                "`n`nPlease continue by using a compiled version to install.", "Warning !", "O Icon! 262144 T5")
            ExitApp()
        }
        result := MsgBox("No library files detected.`n`nWould you like to run a complete setup ?",
            "VideoDownloader Setup Status", "OC Icon? 4096")
        Switch (result)
        {
            Case "OK":
                {
                    Try
                    {
                        Run(scriptBaseFilesLocation . "\library\setup\Setup.exe /run-setup")
                        ExitApp()
                    }
                    Catch
                    {
                        MsgBox("Unable to execute Setup.exe.`n`nTerminating script.", "Error", "O IconX T1.5")
                        ExitApp()
                    }
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
    ; Shows a small tutorial to guide the user.
    If (readConfigFile("ASK_FOR_TUTORIAL") = true)
    {
        Return scriptTutorial()
    }
    If (readConfigFile("SHOW_MAIN_GUI_ON_LAUNCH") = true)
    {
        If (!WinExist("ahk_id " . mainGUI.Hwnd))
        {
            Hotkey_openMainGUI()
        }
        Else
        {
            WinActivate("ahk_id " . mainGUI.Hwnd)
        }
    }
    If (readConfigFile("SHOW_OPTIONS_GUI_ON_LAUNCH") = true)
    {
        If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            Hotkey_openOptionsGUI()
        }
        Else
        {
            WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
        }
    }
}