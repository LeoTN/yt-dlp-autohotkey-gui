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
#Include "ConfigFile.ahk"
#Include "Functions.ahk"
#Include "HelpGUI.ahk"
#Include "Hotkeys.ahk"
#Include "Setup.ahk"
#Include "Tutorials.ahk"
#Include "UpdateGUI.ahk"
#Include "VideoListGUI.ahk"

onInit()

onInit() {
    global scriptRegistryDirectory := "HKCU\SOFTWARE\LeoTN\VideoDownloader"
    ; This folder will contain all other files.
    global scriptMainDirectory := A_ScriptDir . "\VideoDownloader"
    ; Working directory for downloads, settings and presets.
    global scriptWorkingDirectory := scriptMainDirectory ; REMOVE [ADD OPTION TO CHANGE]

    global assetDirectory := scriptMainDirectory . "\assets"

    global ffmpegDirectory := assetDirectory . "\ffmpeg"
    global ffmpegFileLocation := ffmpegDirectory . "\ffmpeg.exe"

    global iconDirectory := assetDirectory . "\icons"
    global scriptIconLocation := iconDirectory . "\green_arrow_icon.ico"
    global GUIBackgroundImageLocation := iconDirectory . "\main_gui_background.png"

    global psScriptDirectory := assetDirectory . "\scripts"
    global psUpdateScriptLocation := psScriptDirectory . "\checkForAvailableUpdates.ps1"
    global psDownloadProgressVisualizerLocation := psScriptDirectory . "\downloadProgressVisualizer.ps1"
    global psRunYTDLPExecutableLocation := psScriptDirectory . "\runYTDLPExecutableWithRedirectedStdout.ps1"

    global YTDLPDirectory := assetDirectory . "\yt-dlp"
    global YTDLPFileLocation := YTDLPDirectory . "\yt-dlp.exe"

    ; When this value is true, certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := RegRead(scriptRegistryDirectory, "booleanFirstTimeLaunch", false)
    ; The version of this script. For example "v1.2.3.4".
    global versionFullName := getCorrectScriptVersionFromRegistry()

    try
    {
        TraySetIcon(scriptIconLocation)
    }
    catch as error {
        displayErrorMessage(error, "This is not a fatal error.", , 10000)
    }

    /*
    INCLUDED COMPONENTS INIT FUNCTIONS
    -------------------------------------------------
    */

    ; Basically checks if all required files and folders are present.
    setup_onInit()
    ; Checks the config file.
    configFile_onInit()
    ; Currently has no purpose.
    functions_onInit()
    ; Initializes the hotkeys.
    hotkeys_onInit()
    ; Creates the help GUI.
    helpGUI_onInit()
    ; Initializes the tutorials for the help GUI.
    tutorials_onInit()
    ; Creates the video list GUI.
    videoListGUI_onInit()
    ; Checks for available updates (depending on the user's choice regarding updates).
    updateGUI_onInit()

    /*
    INCLUDED COMPONENTS INIT FUNCTIONS END
    -------------------------------------------------
    */

    ; Shows a small tutorial to guide the user.
    if (readConfigFile("ASK_FOR_TUTORIAL")) {
        ; scriptTutorial() ; REMOVE [TEMPORARILY DISABLED UNTIL TUTORIAL REWORK]
    }
    ; Disables the firstTimeLaunch at the end of the first run.
    if (booleanFirstTimeLaunch) {
        RegWrite(false, "REG_DWORD", scriptRegistryDirectory, "booleanFirstTimeLaunch")
    }
}
