#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

setup_onInit() {
    ; Checks the system for other already running instances of this application.
    findAlreadyRunningVDInstance("VideoDownloader.exe")
    createRequiredFolders()
    checkIfMSISetupIsRequired()
    ; Putting this behind the setup checks prevents issues when files are missing.
    createSetupGUI()
    ; The application won't continue until the required dependencies are installed or the GUI is closed.
    while (checkIfFFmpegOrYTDLPSetupIsRequired()) {
        setupGUI.Show("AutoSize")
        Sleep(2000)
    }
}

createSetupGUI() {
    global
    setupGUI := Gui("+AlwaysOnTop", "VideoDownloader - Dependency Setup")
    setupGUI.MarginX := 0
    setupGUI.MarginY := 0
    ; Add a background image to the GUI.
    setupGUI.Add("Picture", "x0 y0 w320 h-1 +Center", GUIBackgroundImageLocation)
    dependencyText := setupGUI.Add("Text", "xp+10 yp+5 wp-20 R2 +BackgroundTrans",
        "Required Dependencies")
    dependencyText.SetFont("s12 bold")

    ffmpegCheckbox := setupGUI.Add("CheckBox", "yp+25 wp R1.5 +Border", "FFmpeg")
    ffmpegCheckbox.SetFont("bold")

    YTDLPCheckbox := setupGUI.Add("CheckBox", "yp+20 wp R1.5 +Border", "yt-dlp")
    YTDLPCheckbox.SetFont("bold")
    updateDependencyCheckboxes()

    cancelSetupButton := setupGUI.Add("Button", "yp+120 w140 R2", "Cancel")
    startSetupButton := setupGUI.Add("Button", "xp+160 w140 R2 +Default", "Install Dependencies")

    setupProgressBar := setupGUI.Add("Progress", "xp-120 x0 yp+50 w320")
    setupGUIStatusBar := setupGUI.Add("StatusBar", "-Theme BackgroundSilver")
    setupGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    setupGUIStatusBar.SetText("Please start the setup process")

    ; When the window is closed without installing the required dependencies, the application must exit.
    setupGUI.OnEvent("Close", (*) => exitApplicationWithNotification(true))
    ; This does not allow the user to change the value of the checkbox.
    ffmpegCheckbox.OnEvent("Click", (*) => ffmpegCheckbox.Value := !ffmpegCheckbox.Value)
    ; This does not allow the user to change the value of the checkbox.
    YTDLPCheckbox.OnEvent("Click", (*) => YTDLPCheckbox.Value := !YTDLPCheckbox.Value)
    cancelSetupButton.OnEvent("Click", (*) => exitApplicationWithNotification(true))
    startSetupButton.OnEvent("Click", (*) => handleSetupGUI_startSetupButton_onClick())
}

updateDependencyCheckboxes() {
    ffmpegCheckbox.Value := getFFmpegInstallionStatus()
    if (ffmpegCheckbox.Value) {
        ffmpegCheckbox.Text := "FFmpeg installed"
        ffmpegCheckbox.Opt("BackgroundGreen")
    }
    else {
        ffmpegCheckbox.Text := "FFmpeg not installed"
        ffmpegCheckbox.Opt("BackgroundRed")
    }
    YTDLPCheckbox.Value := getYTDLPInstallionStatus()
    if (YTDLPCheckbox.Value) {
        YTDLPCheckbox.Text := "yt-dlp installed"
        YTDLPCheckbox.Opt("BackgroundGreen")
    }
    else {
        YTDLPCheckbox.Text := "yt-dlp not installed"
        YTDLPCheckbox.Opt("BackgroundRed")
    }
}

; Creates all folders in case they do not exist.
createRequiredFolders() {
    requiredFolders := [
        applicationMainDirectory,
        assetDirectory,
        ffmpegDirectory,
        iconDirectory,
        YTDLPDirectory,
        psScriptDirectory
    ]
    for (i, requiredFolder in requiredFolders) {
        if (!DirExist(requiredFolder)) {
            DirCreate(requiredFolder)
        }
    }
}

; Checks if all required files are present. In case a file is missing, the application will exit after informing the user.
checkIfMSISetupIsRequired() {
    requiredFiles := [
        psUpdateScriptLocation,
        psRunYTDLPExecutableLocation,
        GUIBackgroundImageLocation,
        iconFileLocation
    ]
    for (i, requiredFile in requiredFiles) {
        if (!FileExist(requiredFile)) {
            MsgBox("The file [" . requiredFile .
                "] is missing.`n`nPlease reinstall or repair the software using the .MSI installer.",
                "VideoDownloader - Reinstallation required",
                "Icon! 262144")
            exitApplicationWithNotification(true)
        }
    }
}

; Updates the GUI depending on the installation status of the dependencies.
handleSetupGUI_startSetupButton_onClick() {
    startSetupButton.Opt("+Disabled")
    ; Installs the dependencies and updates the GUI accordingly.
    if (getFFmpegInstallionStatus()) {
        setupGUIStatusBar.SetText("FFmpeg installed")
        setupProgressBar.Value += 50
    }
    else {
        installFFmpeg()
    }
    updateDependencyCheckboxes()
    if (getYTDLPInstallionStatus()) {
        setupGUIStatusBar.SetText("yt-dlp installed")
        setupProgressBar.Value += 50
    }
    else {
        installYTDLP()
    }
    updateDependencyCheckboxes()
    setupGUIStatusBar.SetText("Setup completed")
    Sleep(2000)
    Reload()
}

; Downloads the FFmpeg executables optimized for yt-dlp.
installFFmpeg() {
    ; Define the file name and the file location.
    downloadedFileName := "ffmpeg-master-latest-win64-gpl.zip"
    downloadedFileLocation := ffmpegDirectory . "\" . downloadedFileName
    ; Specifies the target path where the .EXE files are stored.
    SplitPath(downloadedFileName, , , , &outNameNoExt)
    downloadedFileNameWithoutExtension := outNameNoExt
    ffmpegExecutablesDirectory := ffmpegDirectory . "\" . downloadedFileNameWithoutExtension . "\bin"

    ffmpegDownloadLink :=
        "https://github.com/yt-dlp/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip"
    ; Update the GUI.
    setupGUIStatusBar.SetText("Downloading FFmpeg files...")
    setupProgressBar.Value += 20
    Download(ffmpegDownloadLink, downloadedFileLocation)
    ; Update the GUI.
    setupGUIStatusBar.SetText("Extracting FFmpeg files...")
    setupProgressBar.Value += 15
    RunWait('powershell.exe -Command "Expand-Archive -Path """' . downloadedFileLocation .
        '""" -DestinationPath """' .
        ffmpegDirectory . '""" -Force"', , "Hide")
    ; Update the GUI.
    setupGUIStatusBar.SetText("Moving FFmpeg files...")
    setupProgressBar.Value += 10
    ; Moves all .EXE files from the extracted folder to the FFmpeg directory.
    FileMove(ffmpegExecutablesDirectory . "\*.exe", ffmpegDirectory, 1)
    ; Update the GUI.
    setupGUIStatusBar.SetText("Clean up...")
    setupProgressBar.Value += 5
    ; Delete the downloaded .ZIP file and the extracted folder.
    FileDelete(downloadedFileLocation)
    DirDelete(ffmpegDirectory . "\" . downloadedFileNameWithoutExtension, 1)
}

; Downloads the yt-dlp.exe from GitHub.
installYTDLP() {
    global YTDLPDirectory

    ; Define the file name and the file location.
    downloadedFileName := "yt-dlp.exe"
    downloadedFileLocation := YTDLPDirectory . "\" . downloadedFileName

    YTDLPDownloadLink := "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    ; Update the GUI.
    setupGUIStatusBar.SetText("Downloading yt-dlp...")
    setupProgressBar.Value += 25
    Download(YTDLPDownloadLink, downloadedFileLocation)
    ; Update the GUI.
    setupProgressBar.Value += 25
}

/*
Checks if the FFmpeg and yt-dlp executables are present.
@returns [boolean] True, if the files are not present. False otherwise.
*/
checkIfFFmpegOrYTDLPSetupIsRequired() {
    if (!getFFmpegInstallionStatus() || !getYTDLPInstallionStatus()) {
        return true
    }
    return false
}

/*
Checks if the FFmpeg executables are installed.
@returns [boolean] True if all FFmpeg executables are installed, false otherwise.
*/
getFFmpegInstallionStatus() {
    global ffmpegDirectory

    relevantFiles := ["ffmpeg.exe", "ffplay.exe", "ffprobe.exe"]
    for (i, file in relevantFiles) {
        if (!FileExist(ffmpegDirectory . "\" . file)) {
            return false
        }
    }
    return true
}

/*
Checks if yt-dlp is installed.
@returns [boolean] True if yt-dlp is installed, false otherwise.
*/
getYTDLPInstallionStatus() {
    global YTDLPDirectory

    if (!FileExist(YTDLPDirectory . "\yt-dlp.exe")) {
        return false
    }
    return true
}
