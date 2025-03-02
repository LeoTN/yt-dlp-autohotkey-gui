;@Ahk2Exe-SetCompanyName Made by LeoTN
;@Ahk2Exe-SetCopyright Licence available on my GitHub project (https://github.com/LeoTN/yt-dlp-autohotkey-gui)
;@Ahk2Exe-SetDescription VideoDownloader
;@Ahk2Exe-SetMainIcon library\assets\icons\green_arrow_icon.ico

#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "Acc.ahk"
#Include "ConfigFileManager.ahk"
#Include "DownloadOptionsGUI.ahk"
#Include "FileManager.ahk"
#Include "HotKeys & Methods.ahk"
#Include "MainGUI.ahk"
#Include "Setup.ahk"

onInit()

onInit() {
    ; When this value is true, certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := false

    global scriptRegistryDirectory := "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader"
    ; This folder will contain all other files.
    global scriptMainDirectory := A_ScriptDir . "\VideoDownloader"
    ; Working directory for downloads, settings and presets.
    global scriptWorkingDirectory := scriptMainDirectory ; REMOVE ADD OPTION TO CHANGE

    global assetDirectory := scriptMainDirectory . "\assets"

    global ffmpegDirectory := assetDirectory . "\ffmpeg"
    global ffmpegFileLocation := ffmpegDirectory . "\ffmpeg.exe"

    global iconDirectory := assetDirectory . "\icons"
    global scriptIconLocation := iconDirectory . "\green_arrow_icon.ico"
    global mainGUIBackGroundLocation := iconDirectory . "\main_gui_background.png"

    global psScriptDirectory := assetDirectory . "\scripts"
    global psUpdateScriptLocation := psScriptDirectory . "\checkForAvailableUpdates.ps1"
    global downloadOptionsGUITooltipFileLocation := psScriptDirectory . "\DownloadOptionsGUITooltips.exe"
    global psDownloadProgressVisualizerLocation := psScriptDirectory . "\downloadProgressVisualizer.ps1"

    global YTDLPDirectory := assetDirectory . "\yt-dlp"
    global YTDLPFileLocation := YTDLPDirectory . "\yt-dlp.exe"

    try
    {
        TraySetIcon(scriptIconLocation)
    }
    ; Basically checks if all required files and folders are present.
    setup_onInit()

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
