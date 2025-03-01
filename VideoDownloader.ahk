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
onInit() {
    global videoDownloaderRegistryDirectory := "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader"
    ; The location of the script's library and other not changed files.
    global scriptBaseFilesLocation := onInit_handleVideoDownloaderInstallationDirectory()
    ; Working directory for downloads, settings and presets.
    global workingBaseFilesLocation := onInit_handleVideoDownloaderWorkingDirectory()
    ; When this value is true certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := false
    onInit_checkIfSetupIsRequired()
    global downloadOptionsGUITooltipFileLocation := scriptBaseFilesLocation .
        "\library\scripts\DownloadOptionsGUITooltips.exe"
    global ffmpegLocation := RegRead(videoDownloaderRegistryDirectory, "ffmpegLocation", "")
    global mainGUIBackGroundLocation := scriptBaseFilesLocation . "\library\assets\main_gui_background.png"
    local scriptIconLocation := scriptBaseFilesLocation . "\library\assets\green_arrow_icon.ico"

    try
    {
        TraySetIcon(scriptIconLocation)
    }
    if (!FileExist(downloadOptionsGUITooltipFileLocation)) {
        result := MsgBox(
            "Missing tooltip executable file.`n`nNote: Although this file is not mandatory, it is recommended "
            . "to run the setup executable file to repair the application.`n`nPrepare for setup?",
            "VD - Corrupted / Missing Files!", "YN Icon! 262144")
        switch (result) {
            case "Yes":
            {
                MsgBox("You can now run the installer file.`nScript terminated.", "VD - Ready for Setup", "Iconi T5")
                handleMainGUI_repairScript()
                ExitApp()
            }
            case "No":
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
    if (!FileExist(mainGUIBackGroundLocation) || !FileExist(scriptIconLocation)) {
        result := MsgBox("Missing graphic files.`n`nNote: Although these files are not mandatory, it is recommended "
            . "to run the setup executable file to repair the application.`n`nPrepare for setup?",
            "VD - Corrupted / Missing Files!", "YN Icon! 262144")
        switch (result) {
            case "Yes":
            {
                MsgBox("You can now run the installer file.`nScript terminated.", "VD - Ready for Setup", "Iconi T5")
                handleMainGUI_repairScript()
                ExitApp()
            }
            case "No":
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
    if (readConfigFile("ASK_FOR_TUTORIAL")) {
        scriptTutorial()
    }
    if (readConfigFile("SHOW_OPTIONS_GUI_ON_LAUNCH")) {
        if (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd)) {
            hotkey_openOptionsGUI()
        }
        else {
            WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
        }
    }
    if (readConfigFile("SHOW_MAIN_GUI_ON_LAUNCH")) {
        if (!WinExist("ahk_id " . mainGUI.Hwnd)) {
            hotkey_openMainGUI()
        }
        else {
            WinActivate("ahk_id " . mainGUI.Hwnd)
        }
    }
}

onInit_checkIfSetupIsRequired() {
    ; Cannot use true or false because RegRead() returns an actual string every time.
    ; Performs a bunch of integrity checks before launching.
    regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
    if (regValue = "") {
        RegWrite(1, "REG_DWORD",
            videoDownloaderRegistryDirectory, "booleanSetupRequired")
        regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
    }
    else if (regValue = "0") {
        if (!getPythonInstallionStatus()) {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
        if (!getYTDLPInstallionStatus()) {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
        if (!getFFmpegInstallionStatus()) {
            RegWrite(1, "REG_DWORD",
                videoDownloaderRegistryDirectory, "booleanSetupRequired")
            regValue := RegRead(videoDownloaderRegistryDirectory, "booleanSetupRequired", "")
        }
    }
    if (regValue = "1") {
        handleMainGUI_repairScript(false)
    }
    else {
        ; This tells the script to start smoothly without any prompts beeing shown due to missing files.
        regValue := RegRead(videoDownloaderRegistryDirectory, "booleanFirstTimeLaunch", "")
        if (regValue != "0") {
            global booleanFirstTimeLaunch := true
            RegWrite(0, "REG_DWORD", videoDownloaderRegistryDirectory, "booleanFirstTimeLaunch")

            regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
            if (validatePath(regValue, false) && regValue != "") {
                defaultWorkingDirectory := regValue
            }
            else {
                defaultWorkingDirectory := A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files"
            }
            result := MsgBox("Would you like to change the script's working directory?`n`nThe default path is"
                "`n[" . defaultWorkingDirectory .
                "]`n`nThis will be the place for downloaded files, settings and presets."
                "`n`nNote: You can only change this now.", "VD - Change Working Directory?", "YN Icon? 262144")
            switch (result) {
                case "Yes":
                {
                    global workingBaseFilesLocation := changeWorkingDirectory()
                }
            }
        }
    }
}

onInit_handleVideoDownloaderWorkingDirectory() {
    regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
    if (validatePath(regValue, false) && regValue != "") {
        defaultWorkingDirectory := regValue
    }
    else {
        ; In case the working directory is invalid.
        defaultWorkingDirectory := A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files"

        result := MsgBox(
            "Invalid working directory found in the registry editor. The working directory will contain downloaded "
            . "files, settings and presets.`n`nPress [Retry] to select it manually.", "VD - Invalid Working Directory!",
            "RC Icon! 262144")
        switch (result) {
            case "Retry":
            {
                RegWrite(changeWorkingDirectory(), "REG_SZ", videoDownloaderRegistryDirectory,
                "videoDownloaderWorkingDirectory")
                regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderWorkingDirectory", "")
            }
            Default:
            {
                MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                ExitApp()
            }
        }
    }
    return regValue
}

onInit_handleVideoDownloaderInstallationDirectory() {
    regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory", "")
    ; Repairs the path is it is incorrect or corrupted.
    if (regValue = "" || !validatePath(regValue, false)) {
        RegWrite(A_WorkingDir, "REG_SZ", videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory")
        regValue := RegRead(videoDownloaderRegistryDirectory, "videoDownloaderInstallationDirectory", "")
    }
    if (!InStr(regValue, "yt_dlp_autohotkey_gui_files")) {
        return regValue . "\yt_dlp_autohotkey_gui_files"
    }
    else {
        return regValue
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
    if (readConfigFile("booleanDebugMode")) {
        ; Enter code below.
        A_Clipboard := A_ComSpec ' /k ' . buildCommandString() . '> "' . readConfigFile("DOWNLOAD_LOG_FILE_LOCATION") .
        '"'
    }
}

F6::
{
    if (readConfigFile("booleanDebugMode")) {
        ; Enter code below.
    }
}

F7::
{
    if (readConfigFile("booleanDebugMode")) {
        ; Enter code below.
    }
}

/*
DEBUG SECTION END
-------------------------------------------------
*/
