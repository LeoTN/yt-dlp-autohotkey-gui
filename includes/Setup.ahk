#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Window"

setup_onInit() {
    checkIfMSISetupIsRequired()
    ; Checks the system for other already running instances of this application.
    findAlreadyRunningVDInstance()
    createRequiredFolders()
    ; Putting this behind the setup checks prevents issues when files are missing.
    createSetupGUI()
    ; After installing the components, a reload is required.
    booleanSetupReloadRequired := false
    if (checkIfFFmpegOrYTDLPSetupIsRequired()) {
        booleanSetupReloadRequired := true
    }
    ; The application won't continue until the required dependencies are present or the GUI is closed.
    while (booleanSetupReloadRequired) {
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
    setupGUIDependencyText := setupGUI.Add("Text", "xp+10 yp+5 wp-20 R2 +BackgroundTrans",
        "Required Dependencies")
    setupGUIDependencyText.SetFont("s12 bold")

    setupGUIFFmpegCheckbox := setupGUI.Add("CheckBox", "yp+25 wp R1.5 +Border", "FFmpeg")
    setupGUIFFmpegCheckbox.SetFont("bold")

    setupGUIYTDLPCheckbox := setupGUI.Add("CheckBox", "yp+20 wp R1.5 +Border", "yt-dlp")
    setupGUIYTDLPCheckbox.SetFont("bold")
    updateDependencyCheckboxes()

    setupGUICancelSetupButton := setupGUI.Add("Button", "yp+120 w140 R2", "Cancel")
    setupGUIStartSetupButton := setupGUI.Add("Button", "xp+160 w140 R2 +Default", "Download Dependencies")
    setupGUIUseOwnExecutablesText := setupGUI.Add("Text", "xp-160 yp+45 w300 h30 +BackgroundTrans +Center",
        "I want to use my own executables")
    setupGUIUseOwnExecutablesText.SetFont("s10 underline cBlue")

    setupProgressBar := setupGUI.Add("Progress", "xp-120 x0 yp+24 w320")
    setupGUIStatusBar := setupGUI.Add("StatusBar", "-Theme BackgroundSilver")
    setupGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    setupGUIStatusBar.SetText("Please start the setup process")

    ; When the window is closed without installing the required dependencies, the application must exit.
    setupGUI.OnEvent("Close", (*) => exitApplicationWithNotification(true))
    ; This does not allow the user to change the value of the checkbox.
    setupGUIFFmpegCheckbox.OnEvent("Click", (*) => setupGUIFFmpegCheckbox.Value := !setupGUIFFmpegCheckbox.Value)
    ; This does not allow the user to change the value of the checkbox.
    setupGUIYTDLPCheckbox.OnEvent("Click", (*) => setupGUIYTDLPCheckbox.Value := !setupGUIYTDLPCheckbox.Value)
    setupGUICancelSetupButton.OnEvent("Click", (*) => exitApplicationWithNotification(true))
    setupGUIStartSetupButton.OnEvent("Click", handleSetupGUI_setupGUIStartSetupButton_onClick)
    setupGUIUseOwnExecutablesText.OnEvent("Click", handleSetupGUI_setupGUIUseOwnExecutablesText_onClick)
}

; Updates the GUI depending on the installation status of the dependencies.
handleSetupGUI_setupGUIStartSetupButton_onClick(pButton, pInfo) {
    if (!checkInternetConnection()) {
        result := MsgBox("There seems to be no connection to the Internet.`n`nContinue anyway?",
            "VD - No Internet Connection", "YN Icon! Owner" . setupGUI.Hwnd)
        if (result != "Yes") {
            return
        }
    }

    pButton.Opt("+Disabled")
    ; Installs the dependencies and updates the GUI accordingly.
    if (getFFmpegInstallionStatus()) {
        setupGUIStatusBar.SetText("FFmpeg downloaded")
        setupProgressBar.Value += 50
    }
    else {
        installFFmpeg()
    }
    updateDependencyCheckboxes()
    if (getYTDLPInstallionStatus()) {
        setupGUIStatusBar.SetText("yt-dlp downloaded")
        setupProgressBar.Value += 50
    }
    else {
        installYTDLP()
    }
    updateDependencyCheckboxes()
    setupGUIStatusBar.SetText("Setup completed")
    Sleep(2000)
    ; The video list GUI is usually not present at this moment so we don't need to save it's state.
    Reload()
}

; Allows the user to use their own yt-dlp and FFmpeg executables.
handleSetupGUI_setupGUIUseOwnExecutablesText_onClick(pText, pInfo) {
    global ffmpegDirectory
    global YTDLPDirectory

    msgText := "It is possible to use your own FFmpeg and yt-dlp executable files "
    msgText .= "instead of the recommended ones. Simply copy them into their respective directories."
    msgText .= "`n`nBe warned, this could potentially cause other issues!"
    msgText .= "`n`nRequired files in the FFmpeg directory"
    msgText .= "`n→ ffmpeg.exe`n→ ffplay.exe`n→ ffprobe.exe"
    msgText .= "`n`nRequired files in the yt-dlp directory"
    msgText .= "`n→ yt-dlp.exe"
    msgTitle := "VD - Use Custom FFmpeg and yt-dlp Executables"
    msgHeadLine := "Use Your Own FFmpeg and yt-dlp Executables"
    msgButton1 := "FFmpeg Directory"
    msgButton2 := "Refresh"
    msgButton3 := "yt-dlp Directory"
    result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true, setupGUI)
    ; Opens the FFmpeg directory.
    if (result == msgButton1) {
        openDirectoryInExplorer(ffmpegDirectory)
        handleSetupGUI_setupGUIUseOwnExecutablesText_onClick(pText, pInfo)
    }
    ; Reloads the application.
    if (result == msgButton2) {
        Reload()
    }
    ; Opens the yt-dlp directory.
    if (result == msgButton3) {
        openDirectoryInExplorer(YTDLPDirectory)
        handleSetupGUI_setupGUIUseOwnExecutablesText_onClick(pText, pInfo)
    }
}

updateDependencyCheckboxes() {
    setupGUIFFmpegCheckbox.Value := getFFmpegInstallionStatus()
    if (setupGUIFFmpegCheckbox.Value) {
        setupGUIFFmpegCheckbox.Text := "FFmpeg executables found"
        setupGUIFFmpegCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIFFmpegCheckbox.Text := "FFmpeg executables not found"
        setupGUIFFmpegCheckbox.Opt("BackgroundRed")
    }
    setupGUIYTDLPCheckbox.Value := getYTDLPInstallionStatus()
    if (setupGUIYTDLPCheckbox.Value) {
        setupGUIYTDLPCheckbox.Text := "yt-dlp executable found"
        setupGUIYTDLPCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIYTDLPCheckbox.Text := "yt-dlp executable not found"
        setupGUIYTDLPCheckbox.Opt("BackgroundRed")
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
    global applicationMainDirectory

    requiredFiles := [
        psUpdateScriptLocation,
        psRunYTDLPExecutableLocation,
        GUIBackgroundImageLocation,
        iconFileLocation
    ]
    for (i, requiredFile in requiredFiles) {
        if (FileExist(requiredFile)) {
            continue
        }
        ; This is most likely the case when the source code has been downloaded and the .AHK file has been compiled.
        if (A_IsCompiled && DirExist(A_ScriptDir . "\library")) {
            result := MsgBox(
                "It looks like you downloaded the source code and compiled the [VideoDownloader.ahk] file."
                "`n`nThe folder [library] needs to be renamed to [VideoDownloader]."
                "`n`nWould you like to do that now?", "VideoDownloader - Rename Library Folder", "YN Icon! 262144")
            if (result == "Yes") {
                ; Renames the folder.
                DirMove(A_ScriptDir . "\library", applicationMainDirectory, 2)
                Reload()
            }
        }
        else {
            MsgBox("The file [" . requiredFile .
                "] is missing.`n`nPlease reinstall or repair the software using the MSI installer.",
                "VideoDownloader - Reinstallation Required",
                "Icon! 262144")
        }
        exitApplicationWithNotification(true)
    }
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
Checks if the FFmpeg executables are present.
@returns [boolean] True, if all FFmpeg executables are present. False otherwise.
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
Checks if the yt-dlp executable is present.
@returns [boolean] True, if the yt-dlp executable is present. False otherwise.
*/
getYTDLPInstallionStatus() {
    global YTDLPDirectory

    if (!FileExist(YTDLPDirectory . "\yt-dlp.exe")) {
        return false
    }
    return true
}
