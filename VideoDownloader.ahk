;@Ahk2Exe-SetCompanyName Made by LeoTN
;@Ahk2Exe-SetCopyright https://github.com/LeoTN/yt-dlp-autohotkey-gui/blob/main/LICENSE
;@Ahk2Exe-SetDescription VideoDownloader
;@Ahk2Exe-SetMainIcon library\assets\icons\1.ico
;@Ahk2Exe-SetName VideoDownloader
; Define the version information based on the content of the text file.
;@Ahk2Exe-Obey U_productVersion, = FileExist("%A_ScriptDir%\compiler\version.txt") ? Trim(FileRead("%A_ScriptDir%\compiler\version.txt")) : "v0.0.0.1"
;@Ahk2Exe-SetProductVersion %U_productVersion%
;@Ahk2Exe-Obey U_fileVersion, U_fileVersion := LTrim("%U_productVersion%"`,"v")
;@Ahk2Exe-SetFileVersion %U_fileVersion%

#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

; Imports important functions and variables.
; Sets the directory for all following files.
#Include "includes\"
#Include "Acc.ahk"
#Include "ColorButton.ahk"
#Include "ConfigurationFile.ahk"
#Include "Functions.ahk"
#Include "HelpGUI.ahk"
#Include "Hotkeys.ahk"
#Include "SettingsGUI.ahk"
#Include "Setup.ahk"
#Include "Tutorials.ahk"
#Include "UpdateGUI.ahk"
#Include "VideoListGUI.ahk"

onInit()

onInit() {
    global applicationRegistryDirectory := "HKCU\SOFTWARE\LeoTN\VideoDownloader"
    ; This folder will contain all other files.
    if (A_IsCompiled) {
        global applicationMainDirectory := A_ScriptDir . "\VideoDownloader"
    }
    else {
        global applicationMainDirectory := A_ScriptDir . "\library"
    }

    ; Determines the location of the application's configuration file.
    global configFileLocation := applicationMainDirectory . "\VideoDownloader.ini"

    global assetDirectory := applicationMainDirectory . "\assets"

    global ffmpegDirectory := assetDirectory . "\ffmpeg"
    global ffmpegFileLocation := ffmpegDirectory . "\ffmpeg.exe"

    global iconDirectory := assetDirectory . "\icons"
    global iconFileLocation := iconDirectory . "\video_downloader_icons.dll"
    global GUIBackgroundImageLocation := iconDirectory . "\video_list_gui_background.png"

    global psScriptDirectory := assetDirectory . "\scripts"
    global psUpdateScriptLocation := psScriptDirectory . "\checkForAvailableUpdates.ps1"
    global psRunYTDLPExecutableLocation := psScriptDirectory . "\runYTDLPExecutableWithRedirectedStdout.ps1"

    global YTDLPDirectory := assetDirectory . "\yt-dlp"
    global YTDLPFileLocation := YTDLPDirectory . "\yt-dlp.exe"

    ; When this value is true, certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := RegRead(applicationRegistryDirectory, "booleanFirstTimeLaunch", false)
    ; The version of this application. For example "v1.2.3.4".
    global versionFullName := getCorrectScriptVersion()

    ; Determine the available download formats and subtitle options.
    global desiredDownloadFormatArray := [
        ; Video formats.
        "Automatically choose best video format", "mp4", "webm", "avi", "flv", "mkv", "mov",
        ; Audio formats.
        "Automatically choose best audio format", "mp3", "wav", "m4a", "flac", "opus", "vorbis"
    ]
    global desiredSubtitleArray := [
        "Do not download subtitles", "Embed all available subtitles"
    ]

    if (FileExist(iconFileLocation)) {
        TraySetIcon(iconFileLocation, 1, true)
    }
    ; Clears the existing tray menu elements.
    A_TrayMenu.Delete()
    ; Adds a tray menu point to open the video list GUI.
    A_TrayMenu.Add("Video List", (*) => hotkey_openVideoListGUI())
    A_TrayMenu.Add("Settings", (*) => menu_openSettingsGUI())
    A_TrayMenu.Add()
    A_TrayMenu.Add("Restart", (*) => menu_restartApplication())
    A_TrayMenu.Add("Exit", (*) => menu_exitApplication())
    A_TrayMenu.Add("About", (*) => menu_openHelpGUI())
    ; When clicking on the tray icon twice, this will make sure, that the video list GUI is shown to the user.
    A_TrayMenu.Default := "Video List"

    /*
    INCLUDED COMPONENTS INIT FUNCTIONS
    -------------------------------------------------
    */

    ; Basically checks if all required files and folders are present.
    setup_onInit()
    ; Checks and loads the config file.
    configurationFile_onInit()
    ; Currently has no purpose.
    functions_onInit()
    ; Initializes the hotkeys.
    hotkeys_onInit()
    ; Creates the help GUI.
    helpGUI_onInit()
    ; Creates the video list GUI.
    videoListGUI_onInit()
    ; Creates the settings GUI.
    settingsGUI_onInit()
    ; Initializes the tutorials for the help GUI.
    tutorials_onInit()
    ; Checks for available updates (depending on the user's choice regarding updates).
    updateGUI_onInit()

    /*
    INCLUDED COMPONENTS INIT FUNCTIONS END
    -------------------------------------------------
    */

    if (readConfigFile("DISPLAY_STARTUP_NOTIFICATION")) {
        displayTrayTip("VideoDownloader launched.", "VideoDownloader - Status")
    }
    ; Shows a small tutorial to guide the user.
    if (readConfigFile("ASK_FOR_TUTORIAL")) {
        applicationTutorial()
    }
    ; Disables the firstTimeLaunch at the end of the first run.
    if (booleanFirstTimeLaunch) {
        RegWrite(false, "REG_DWORD", applicationRegistryDirectory, "booleanFirstTimeLaunch")
    }
}
