; NOTE: This is the main .ahk file which has to be started!!!
#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFileManager.ahk"
#Include "HotKeys & Methods.ahk"
#Include "FileManager.ahk"
#Include "MainGUI.ahk"
#Include "DownloadOptionsGUI.ahk"
#Include "Acc.ahk"

onInit()

; Runs a list of commands when the script is launched.
onInit()
{
    global videoDownloaderRegistryDirectory := "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader"
    ; The location of the script's library and other not changed files.
    global scriptBaseFilesLocation := onInit_handleVideoDownloaderInstallationDirectory()
    ; Working directory for downloads, settings and presets.
    global workingBaseFilesLocation := onInit_handleVideoDownloaderWorkingDirectory()
    ; When this value is true certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := false
    onInit_checkIfSetupIsRequired()
    global downloadOptionsGUITooltipFileLocation := scriptBaseFilesLocation . "\library\scripts\DownloadOptionsGUITooltips.exe"
    global ffmpegLocation := RegRead(videoDownloaderRegistryDirectory, "ffmpegLocation", "")
    global mainGUIBackGroundLocation := scriptBaseFilesLocation . "\library\assets\main_gui_background.png"
    local scriptIconLocation := scriptBaseFilesLocation . "\library\assets\green_arrow_icon.ico"

    Try
    {
        TraySetIcon(scriptIconLocation)
    }
    If (!FileExist(downloadOptionsGUITooltipFileLocation))
    {
        result := MsgBox("Missing tooltip executable file.`n`nNote: Although this file is not mandatory, it is recommended "
            . "to run the setup executable file to repair the application.`n`nPrepare for setup?", "VD - Corrupted / Missing Files!", "YN Icon! 262144")
        Switch (result)
        {
            Case "Yes":
                {
                    MsgBox("You can now run the installer file.`nScript terminated.", "VD - Ready for Setup", "Iconi T5")
                    handleMainGUI_repairScript()
                    ExitApp()
                }
            Case "No":
                {
                    ; Do nothing and run anyways. (In this case not risky)
                }
            Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                    ExitApp()
                }
        }
    }
    If (!FileExist(mainGUIBackGroundLocation) || !FileExist(scriptIconLocation))
    {
        result := MsgBox("Missing graphic files.`n`nNote: Although these files are not mandatory, it is recommended "
            . "to run the setup executable file to repair the application.`n`nPrepare for setup?", "VD - Corrupted / Missing Files!", "YN Icon! 262144")
        Switch (result)
        {
            Case "Yes":
                {
                    MsgBox("You can now run the installer file.`nScript terminated.", "VD - Ready for Setup", "Iconi T5")
                    handleMainGUI_repairScript()
                    ExitApp()
                }
            Case "No":
                {
                    ; Do nothing and run anyways. (Low risk but missing graphics)
                }
            Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                    ExitApp()
                }
        }
    }

    ; Checks the system for other already running instances of this script.
    findProcessWithWildcard("VideoDownloader.exe")
    config_onInit()
    ; Only called to check the config file status.
    readConfigFile("booleanDebugMode")
    checkBlackListFile("createBlackListFile")
    hotkey_onInit()
    mainGUI_onInit()
    optionsGUI_onInit()
    ; Shows a small tutorial to guide the user.
    If (readConfigFile("ASK_FOR_TUTORIAL"))
    {
        scriptTutorial()
    }
    If (readConfigFile("SHOW_OPTIONS_GUI_ON_LAUNCH"))
    {
        If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            hotkey_openOptionsGUI()
        }
        Else
        {
            WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
        }
    }
    If (readConfigFile("SHOW_MAIN_GUI_ON_LAUNCH"))
    {
        If (!WinExist("ahk_id " . mainGUI.Hwnd))
        {
            hotkey_openMainGUI()
        }
        Else
        {
            WinActivate("ahk_id " . mainGUI.Hwnd)
        }
    }
}

onInit_checkIfSetupIsRequired()
{
    ; Cannot use true or false because RegRead() returns an actual string every time.
    ; Performs a bunch of integrity checks before launching.
    regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
    If (regValue = "")
    {
        RegWrite(1, "REG_DWORD",
            videoDownloaderRegistryDirectory, "booleanSetupRequired")
        regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
    }
    Else If (regValue = "0")
    {
        If (!getPythonInstallionStatus())
        {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
        If (!getYTDLPInstallionStatus())
        {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
        If (!getFFmpegInstallionStatus())
        {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
    }
    If (regValue = "1")
    {
        handleMainGUI_repairScript(false)
    }
    Else
    {
        ; This tells the script to start smoothly without any prompts beeing shown due to missing files.
        regValue := RegRead(videoDownloaderRegistryDirectory, "booleanFirstTimeLaunch", "")
        If (regValue != "0")
        {
            global booleanFirstTimeLaunch := true
            RegWrite(0, "REG_DWORD", videoDownloaderRegistryDirectory, "booleanFirstTimeLaunch")

            regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
            If (validatePath(regValue, false) && regValue != "")
            {
                defaultWorkingDirectory := regValue
            }
            Else
            {
                defaultWorkingDirectory := A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files"
            }
            result := MsgBox("Would you like to change the script's working directory?`n`nThe default path is"
                "`n[" . defaultWorkingDirectory . "]`n`nThis will be the place for downloaded files, settings and presets."
                "`n`nNote: You can only change this now.", "VD - Change Working Directory?", "YN Icon? 262144")
            Switch (result)
            {
                Case "Yes":
                    {
                        global workingBaseFilesLocation := changeWorkingDirectory()
                    }
            }
        }
    }
}

onInit_handleVideoDownloaderWorkingDirectory()
{
    regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
    If (validatePath(regValue, false) && regValue != "")
    {
        defaultWorkingDirectory := regValue
    }
    Else
    {
        ; In case the working directory is invalid.
        defaultWorkingDirectory := A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files"

        result := MsgBox("Invalid working directory found in the registry editor. The working directory will contain downloaded "
            . "files, settings and presets.`n`nPress [Retry] to select it manually.", "VD - Invalid Working Directory!", "RC Icon! 262144")
        Switch (result)
        {
            Case "Retry":
                {
                    RegWrite(changeWorkingDirectory(), "REG_SZ", videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory")
                    regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
                }
            Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                    ExitApp()
                }
        }
    }
    Return regValue
}

onInit_handleVideoDownloaderInstallationDirectory()
{
    regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory", "")
    ; Repairs the path is it is incorrect or corrupted.
    If (regValue = "" || !validatePath(regValue, false))
    {
        RegWrite(A_WorkingDir, "REG_SZ", videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory")
        regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory", "")
    }
    If (!InStr(regValue, "yt_dlp_autohotkey_gui_files"))
    {
        Return regValue . "\yt_dlp_autohotkey_gui_files"
    }
    Else
    {
        Return regValue
    }
}

/*
DEBUG SECTION
-------------------------------------------------
Add debug hotkeys here.
*/

; Debug hotkey template.
F5::
{
    If (readConfigFile("booleanDebugMode"))
    {
        ; Enter code below.
        A_Clipboard := A_ComSpec ' /k ' . buildCommandString() . '> "' . readConfigFile("DOWNLOAD_LOG_FILE_LOCATION") . '"'
    }
}

F6::
{
    If (readConfigFile("booleanDebugMode"))
    {
        ; Enter code below.
        handleDownloadOptionsGUI_ResolveElementConflicts()
    }
}

F7::
{
    If (readConfigFile("booleanDebugMode"))
    {
        ; Enter code below
        handleDownloadOptionsGUI_ProcessCommandStringInputs()
    }
}

/*
DEBUG SECTION END
-------------------------------------------------
*/
