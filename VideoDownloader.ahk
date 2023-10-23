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
; When this value is true certain functions will behave differently and do not show unnecessary prompts.
global booleanFirstTimeLaunch := false

onInit_checkIfSetupIsNeeded()

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFileManager.ahk"
#Include "HotKeys & Methods.ahk"
#Include "FileManager.ahk"
#Include "MainGUI.ahk"
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
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation", "")
    If (regValue = "")
    {
        RegWrite(chooseScriptWorkingDirectory(), "REG_SZ",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation")
        regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation", "")
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
                    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation", "")
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
    Try
    {
        TraySetIcon(scriptBaseFilesLocation . "\library\assets\green_arrow_icon.ico")
    }
    If (FileExist(scriptBaseFilesLocation . "\library\FFmpeg\ffmpeg.exe"))
    {
        global ffmpegLocation := scriptBaseFilesLocation . "\library\FFmpeg\ffmpeg.exe"
    }
    Else
    {
        result := MsgBox("No FFmpeg files have been found. The script may run without them but it is highly recommended to run the setup."
            "`n`nPress YES to run the setup or NO to ignore and run anyways.", "Missing FFmpeg Files", "YNC Icon!")
        Switch (result)
        {
            Case "Yes":
                {
                    If (A_IsCompiled = false)
                    {
                        MsgBox("You are using the a non compiled version of this script."
                            "`n`nPlease continue by using a compiled version to install.", "Warning !", "O Icon! 262144 T5")
                        ExitApp()
                        ExitApp()
                    }
                    Try
                    {
                        Run(scriptBaseFilesLocation . "\library\setup\VideoDownloaderSetup.exe /run-setup")
                        If (ProcessWait("VideoDownloaderSetup.exe", 30) = 0)
                        {
                            ExitApp()
                        }
                        ProcessWaitClose("VideoDownloaderSetup.exe")
                        Reload()
                    }
                    Catch
                    {
                        MsgBox("Unable to execute VideoDownloaderSetup.exe.`n`nTerminating script.", "Error !", "O IconX T1.5")
                        ExitApp()
                        ExitApp()
                    }
                }
            Case "No":
                {
                    global ffmpegLocation := "NO_PATH_PROVIDED"
                }
            Default:
                {
                    MsgBox("Terminating script.", "Script Status", "O Iconi T1.5")
                    ExitApp()
                }
        }
    }

    global youTubeBackGroundLocation := scriptBaseFilesLocation . "\library\assets\YouTubeBackground.jpg"
    ; Checks the system for other already running instances of this script.
    findProcessWithWildcard("VideoDownloader.exe")

    ; Only called to check the config file status.
    readConfigFile("booleanDebugMode")
    checkBlackListFile("createBlackListFile")
    Hotkey_onInit()
    mainGUI_onInit()
    optionsGUI_onInit()
    ; Shows a small tutorial to guide the user.
    If (readConfigFile("ASK_FOR_TUTORIAL") = true)
    {
        scriptTutorial()
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
}

onInit_checkIfSetupIsNeeded()
{
    ; Cannot use true or false because RegRead() returns an actual string every time.
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired", "")
    If (regValue = "")
    {
        RegWrite(1, "REG_DWORD",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired")
        regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired", "")
    }
    Else If (regValue = "0")
    {
        regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation", "")
        If (validatePath(regValue, false) = false)
        {
            RegWrite(1, "REG_DWORD",
                "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired")
            regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired", "")
        }
        RunWait(A_ComSpec ' /c yt-dlp --version >> "' . A_Temp . '\tmp.txt"', , "Hide")
        If (FileExist(A_Temp . "\tmp.txt"))
        {
            ; This means that the command could not be found and yt-dlp is not installed.
            If (FileRead(A_Temp . "\tmp.txt") = "")
            {
                RegWrite(1, "REG_DWORD",
                    "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired")
                regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired", "")
            }
        }
    }
    If (regValue = "1")
    {
        If (A_IsCompiled = false)
        {
            MsgBox("You are using the a non compiled version of this script."
                "`n`nPlease continue by using a compiled version to install.", "Warning !", "O Icon! 262144 T5")
            ExitApp()
            ExitApp()
        }
        Try
        {
            Run(scriptBaseFilesLocation . "\library\setup\VideoDownloaderSetup.exe /run-setup")
            If (ProcessWait("VideoDownloaderSetup.exe", 30) = 0)
            {
                ExitApp()
            }
            ProcessWaitClose("VideoDownloaderSetup.exe")
            Reload()
        }
        Catch
        {
            MsgBox("Unable to execute VideoDownloaderSetup.exe.`n`nTerminating script.", "Error !", "O IconX T1.5")
            ExitApp()
            ExitApp()
        }
    }
    Else
    {
        ; This tells the script to start smoothly without any prompts beeing shown due to missing files.
        regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanFirstTimeLaunch", "")
        If (regValue = "1")
        {
            global booleanFirstTimeLaunch := true
            RegWrite(0, "REG_DWORD",
                "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanFirstTimeLaunch")
        }
    }
}