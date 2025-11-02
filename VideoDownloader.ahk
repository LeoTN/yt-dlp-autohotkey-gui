;@Ahk2Exe-SetCompanyName Made by LeoTN
;@Ahk2Exe-SetCopyright https://github.com/LeoTN/yt-dlp-autohotkey-gui/blob/main/LICENSE
;@Ahk2Exe-SetDescription VideoDownloader
;@Ahk2Exe-SetMainIcon library\assets\icons\1.ico
;@Ahk2Exe-SetName VideoDownloader
; Define the version information based on the content of the text file.
;@Ahk2Exe-Obey U_productVersion, = FileExist("%A_ScriptDir%\compiler\currentVersion.txt") ? RegExReplace(FileRead("%A_ScriptDir%\compiler\currentVersion.txt")`, "[\r\n]") : "v0.0.0.1"
;@Ahk2Exe-SetProductVersion %U_productVersion%
;@Ahk2Exe-Obey U_fileVersion, U_fileVersion := RTrim(LTrim("%U_productVersion%"`, "v")`, "-beta")
;@Ahk2Exe-SetFileVersion %U_fileVersion%

; Import relevant functions and variables.
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

#SingleInstance Off

; Close any running instance of this script when a new one starts (non-compiled only).
;@Ahk2Exe-IgnoreBegin
#SingleInstance Force
;@Ahk2Exe-IgnoreEnd

#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

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

    global iconDirectory := assetDirectory . "\icons"
    global iconFileLocation := iconDirectory . "\video_downloader_icons.dll"
    global GUIBackgroundImageLocation := iconDirectory . "\video_list_gui_background.png"

    global psScriptDirectory := assetDirectory . "\scripts"
    global psUpdateScriptLocation := psScriptDirectory . "\checkForAvailableUpdates.ps1"
    global psRunYTDLPExecutableLocation := psScriptDirectory . "\runYTDLPExecutableWithRedirectedStdout.ps1"

    global ytdlpDirectory := assetDirectory . "\yt-dlp"
    global ytdlpFileLocation := ytdlpDirectory . "\yt-dlp.exe"

    ; When this value is true, certain functions will behave differently and do not show unnecessary prompts.
    global booleanFirstTimeLaunch := RegRead(applicationRegistryDirectory, "booleanFirstTimeLaunch", false)
    ; The version of this application. For example "v1.2.3.4".
    global versionFullName := getCorrectScriptVersion()
    ; The version of the yt-dlp executable. For example "2025.10.22.0".
    global ytdlpVersion := getCorrectYTDLPVersion()

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

    ; Basically checks if all required files and folders are present.
    setup_onInit()

    if (FileExist(iconFileLocation)) {
        TraySetIcon(iconFileLocation, 1, true)
    }
    A_IconTip := "VideoDownloader by LeoTN"
    ; Clears the existing tray menu elements.
    A_TrayMenu.Delete()
    ; Adds a tray menu point to open the video list GUI.
    A_TrayMenu.Add("Video List", (*) => hotkey_openVideoListGUI())
    A_TrayMenu.SetIcon("Video List", iconFileLocation, 22) ; ICON_DLL_USED_HERE
    A_TrayMenu.Add("Settings", (*) => menu_openSettingsGUI())
    A_TrayMenu.SetIcon("Settings", iconFileLocation, 6) ; ICON_DLL_USED_HERE
    A_TrayMenu.Add()
    A_TrayMenu.Add("Restart", (*) => menu_restartApplication())
    A_TrayMenu.SetIcon("Restart", iconFileLocation, 8) ; ICON_DLL_USED_HERE
    A_TrayMenu.Add("Exit", (*) => menu_exitApplication())
    A_TrayMenu.SetIcon("Exit", iconFileLocation, 15) ; ICON_DLL_USED_HERE
    A_TrayMenu.Add()
    A_TrayMenu.Add("About", (*) => menu_openHelpGUI())
    A_TrayMenu.SetIcon("About", iconFileLocation, 14) ; ICON_DLL_USED_HERE
    ; Shows the video list GUI when the tray icon is clicked twice.
    A_TrayMenu.Default := "Video List"

    /*
    INCLUDED COMPONENTS INIT FUNCTIONS
    -------------------------------------------------
    */

    ; Registers important events for all GUIs and toast notifications.
    functions_onInit()
    ; Checks and loads the config file.
    configurationFile_onInit()
    ; Initializes the hotkeys.
    hotkeys_onInit()
    ; Creates the video list GUI.
    videoListGUI_onInit()
    ; Creates the help GUI.
    helpGUI_onInit()
    ; Creates the settings GUI.
    settingsGUI_onInit()
    ; Initializes the tutorials for the help GUI.
    tutorials_onInit()
    ; Checks for available updates (depending on the user's choice regarding updates) without interrupting the flow of the main code.
    SetTimer(updateGUI_onInit, -1)

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
