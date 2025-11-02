setup_onInit() {
    checkIfMSISetupIsRequired()
    createRequiredFolders()
    ; Checks the system for other already running instances of this application.
    findAlreadyRunningVDInstance()
    ; Putting this behind the setup checks prevents issues when files are missing.
    createSetupGUI()
    if (!checkIfFFmpegOrYTDLPSetupIsRequired()) {
        return
    }
    ; The application won't continue until the required dependencies are present.
    setupGUI.Show("AutoSize")
    setupGUI.Flash()
    WinWaitClose("ahk_id " . setupGUI.Hwnd)
    ; The video list GUI is usually not present at this moment so we don't need to save it's state.
    Reload()
    ; Makes sure that the old instance exits right away after the reload command has been issued.
    ExitApp()
}

createSetupGUI() {
    global
    setupGUI := Gui("+AlwaysOnTop +OwnDialogs", "VideoDownloader - Dependency Setup")
    setupGUI.MarginX := 0
    setupGUI.MarginY := 0
    ; Add a background image to the GUI.
    setupGUI.Add("Picture", "x0 y0 w320 h-1 +Center", GUIBackgroundImageLocation)
    setupGUIDependencyText := setupGUI.Add("Text", "xp+10 yp+5 w300 R2 +BackgroundTrans",
        "Required Executable Dependencies")
    setupGUIDependencyText.SetFont("s12 bold")

    setupGUIYTDLPCheckbox := setupGUI.Add("CheckBox", "yp+25 w150 R1.5 +Border", "yt-dlp")
    setupGUIYTDLPCheckbox.SetFont("bold")

    setupGUIFFmpegCheckbox := setupGUI.Add("CheckBox", "xp+150 w150 R1.5 +Border", "FFmpeg")
    setupGUIFFmpegCheckbox.SetFont("bold")

    setupGUIFFplayCheckbox := setupGUI.Add("CheckBox", "xp-150 yp+20 w150 R1.5 +Border", "FFplay")
    setupGUIFFplayCheckbox.SetFont("bold")

    setupGUIFFprobeCheckbox := setupGUI.Add("CheckBox", "xp+150 w150 R1.5 +Border", "FFprobe")
    setupGUIFFprobeCheckbox.SetFont("bold")

    setupGUIDeleteAllDependenciesButton := setupGUI.Add("Button", "xp-150 yp+120 w140 R2", "Delete Dependencies")
    setButtonIcon(setupGUIDeleteAllDependenciesButton, iconFileLocation, 7) ; ICON_DLL_USED_HERE
    setupGUIStartAndCompleteSetupButton := setupGUI.Add("Button", "xp+160 w140 R2 +Default", "Start Installation")
    setButtonIcon(setupGUIStartAndCompleteSetupButton, iconFileLocation, 25) ; ICON_DLL_USED_HERE
    setupGUIUseOwnExecutablesText := setupGUI.Add("Text", "xp-160 yp+45 w300 h30 +BackgroundTrans +Center",
        "I want to use my own executables")
    setupGUIUseOwnExecutablesText.SetFont("s10 underline cBlue")

    setupGUISetupProgressBar := setupGUI.Add("Progress", "xp-120 x0 yp+24 w320")
    setupGUIStatusBar := setupGUI.Add("StatusBar", "-Theme BackgroundSilver")
    setupGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    setupGUIStatusBar.SetText("Please start the setup process")

    ; When the window is closed without installing the required dependencies, the application must exit.
    setupGUI.OnEvent("Close", handleSetupGUI_setupGUI_onClose)
    ; This does not allow the user to change the value of the checkbox.
    setupGUIYTDLPCheckbox.OnEvent("Click", (*) => setupGUIYTDLPCheckbox.Value := !setupGUIYTDLPCheckbox.Value)
    setupGUIFFmpegCheckbox.OnEvent("Click", (*) => setupGUIFFmpegCheckbox.Value := !setupGUIFFmpegCheckbox.Value)
    setupGUIFFplayCheckbox.OnEvent("Click", (*) => setupGUIFFplayCheckbox.Value := !setupGUIFFplayCheckbox.Value)
    setupGUIFFprobeCheckbox.OnEvent("Click", (*) => setupGUIFFprobeCheckbox.Value := !setupGUIFFprobeCheckbox.Value)
    ; This allows the user to use their own executables.
    setupGUIYTDLPCheckbox.OnEvent("DoubleClick", handleSetupGUI_setupGUIYTDLPCheckbox_onDoubleClick)
    setupGUIFFmpegCheckbox.OnEvent("DoubleClick", handleSetupGUI_setupGUIFFmpegCheckboxes_onDoubleClick)
    setupGUIFFplayCheckbox.OnEvent("DoubleClick", handleSetupGUI_setupGUIFFmpegCheckboxes_onDoubleClick)
    setupGUIFFprobeCheckbox.OnEvent("DoubleClick", handleSetupGUI_setupGUIFFmpegCheckboxes_onDoubleClick)
    ; Download or delete the dependencies.
    setupGUIDeleteAllDependenciesButton.OnEvent("Click", handleSetupGUI_setupGUIDeleteAllDependenciesButton_onClick)
    setupGUIUseOwnExecutablesText.OnEvent("Click", handleSetupGUI_setupGUIUseOwnExecutablesText_onClick)
    updateDependencyCheckboxes()
    updateSetupButton()
}

handleSetupGUI_setupGUI_onClose(pGUI) {
    global ytdlpVersion
    if (checkIfFFmpegOrYTDLPSetupIsRequired()) {
        exitApplicationWithNotification(true)
    }
    ; Update the internal yt-dlp version after a (possible) update.
    ytdlpVersion := getCorrectYTDLPVersion()
    createHelpGUI_updateAbout()
}

handleSetupGUI_setupGUIYTDLPCheckbox_onDoubleClick(pCheckbox, pInfo) {
    global ytdlpDirectory

    filter := "yt-dlp (yt-dlp.exe)"
    fileArray := fileSelectPrompt("VD - Please select the yt-dlp executable file",
        ytdlpDirectory, filter, setupGUI)
    if (fileArray.Length == 0) {
        return
    }

    SplitPath(fileArray[1], &outName, &outDir)
    if (outName != "yt-dlp.exe" || ytdlpDirectory == outDir) {
        return
    }
    FileCopy(fileArray[1], ytdlpDirectory, true)
    updateDependencyCheckboxes()
    updateSetupButton()
}

handleSetupGUI_setupGUIFFmpegCheckboxes_onDoubleClick(pCheckbox, pInfo) {
    global ffmpegDirectory

    filter := "FFmpeg (ffmpeg.exe; ffplay.exe; ffprobe.exe)"
    fileArray := fileSelectPrompt("VD - Please select the FFmpeg executable file(s)",
        ffmpegDirectory, filter, setupGUI, true)
    if (fileArray.Length == 0) {
        return
    }

    relevantFiles := ["ffmpeg.exe", "ffplay.exe", "ffprobe.exe"]
    for (file in fileArray) {
        SplitPath(file, &outName, &outDir)
        ; Checks if the selected file is a FFmpeg file or the source and destination are the same.
        if ((!checkIfStringIsInArray(outName, relevantFiles, false)) || ffmpegDirectory == outDir) {
            continue
        }
        FileCopy(file, ffmpegDirectory, true)
    }
    updateDependencyCheckboxes()
    updateSetupButton()
}

/*
Installs all required dependencies and updates the GUI accordingly.
Existing files will not be overwritten.
*/
handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_1(pButton, pInfo) {
    global ytdlpDirectory
    global ffmpegDirectory

    if (!checkInternetConnection()) {
        result := MsgBox("There seems to be no connection to the Internet.`n`nContinue anyway?",
            "VD - No Internet Connection", "YN Icon! Owner" . setupGUI.Hwnd)
        if (result != "Yes") {
            return
        }
    }

    pButton.Opt("+Disabled")
    ; Installs the dependencies and updates the GUI accordingly.
    if (getFFmpegInstallionStatus() && getFFplayInstallionStatus() && getFFprobeInstallionStatus()) {
        setupGUIStatusBar.SetText("FFmpeg downloaded")
        setupGUISetupProgressBar.Value += 50
    }
    else {
        installFFmpeg()
    }
    updateDependencyCheckboxes()
    if (getYTDLPInstallionStatus()) {
        setupGUIStatusBar.SetText("yt-dlp downloaded")
        setupGUISetupProgressBar.Value += 50
    }
    else {
        installYTDLP()
    }
    updateDependencyCheckboxes()
    setupGUIStatusBar.SetText("Setup completed")
    Sleep(2000)
    if (WinExist("ahk_id " . setupGUI.Hwnd)) {
        WinClose()
    }
}

; Finishes the setup.
handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_2(pButton, pInfo) {
    ; Checks if all files are present.
    if (checkIfFFmpegOrYTDLPSetupIsRequired()) {
        updateDependencyCheckboxes()
        updateSetupButton()
        setupGUIStatusBar.SetText("Could not complete setup. Not required all files are present")
        return
    }
    setupGUIStatusBar.SetText("Setup completed")
    if (WinExist("ahk_id " . setupGUI.Hwnd)) {
        WinClose()
    }
}

handleSetupGUI_setupGUIDeleteAllDependenciesButton_onClick(pButton, pInfo) {
    result := MsgBox("All existing dependencies will be deleted.`n`nContinue?",
        "VD - Delete All Dependencies", "Icon! YN Owner" . setupGUI.Hwnd)
    if (result != "Yes") {
        return
    }
    ; Deletes all dependency files.
    deleteAllDependencyFiles()
    updateDependencyCheckboxes()
    updateSetupButton()
}

; Allows the user to use their own yt-dlp and FFmpeg executables.
handleSetupGUI_setupGUIUseOwnExecutablesText_onClick(pText, pInfo) {
    global ytdlpDirectory
    global ffmpegDirectory

    msgText := "It is possible to use your own FFmpeg and yt-dlp executable files "
    msgText .= "instead of the recommended ones. Double-click any of the 4 boxes "
    msgText .= "to select your custom executables. They will be copied into a VideoDownloader sub folder."
    msgText .= "`n`nBe warned, this could potentially cause other issues!"
    msgText .= "`n`nRequired files in the FFmpeg directory"
    msgText .= "`n→ ffmpeg.exe`n→ ffplay.exe`n→ ffprobe.exe"
    msgText .= "`n`nRequired files in the yt-dlp directory"
    msgText .= "`n→ yt-dlp.exe"
    msgTitle := "VD - Use Custom FFmpeg and yt-dlp Executables"
    MsgBox(msgText, msgTitle, "Icon! 262144")
}

deleteAllDependencyFiles() {
    global ffmpegDirectory
    global ytdlpFileLocation

    ; Delete all existing FFmpeg files.
    relevantFiles := ["ffmpeg.exe", "ffplay.exe", "ffprobe.exe"]
    for (relevantFile in relevantFiles) {
        relevantFilePath := ffmpegDirectory . "\" . relevantFile
        if (FileExist(relevantFilePath)) {
            FileDelete(relevantFilePath)
        }
    }
    ; Delete the yt-dlp file.
    if (FileExist(ytdlpFileLocation)) {
        FileDelete(ytdlpFileLocation)
    }
}

; Changes the setup start button text and action depending on the setup state.
updateSetupButton() {
    global iconFileLocation

    if (checkIfFFmpegOrYTDLPSetupIsRequired()) {
        setupGUIStartAndCompleteSetupButton.Text := "Start Installation"
        setupGUIStartAndCompleteSetupButton.ToolTip := "Existing files will not be overwritten."
        setButtonIcon(setupGUIStartAndCompleteSetupButton, iconFileLocation, 25) ; ICON_DLL_USED_HERE
        ; Disable the old event function.
        setupGUIStartAndCompleteSetupButton.OnEvent("Click",
            handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_2, 0)
        ; Enable the new event function.
        setupGUIStartAndCompleteSetupButton.OnEvent("Click",
            handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_1, 1)
    }
    else {
        setupGUIStartAndCompleteSetupButton.Text := "Complete Setup"
        setupGUIStartAndCompleteSetupButton.ToolTip := "Finish the setup process."
        setButtonIcon(setupGUIStartAndCompleteSetupButton, iconFileLocation, 20) ; ICON_DLL_USED_HERE
        ; Disable the old event function.
        setupGUIStartAndCompleteSetupButton.OnEvent("Click",
            handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_1, 0)
        ; Enable the new event function.
        setupGUIStartAndCompleteSetupButton.OnEvent("Click",
            handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_2, 1)
    }
}

updateDependencyCheckboxes() {
    setupGUIYTDLPCheckbox.Value := getYTDLPInstallionStatus()
    if (setupGUIYTDLPCheckbox.Value) {
        setupGUIYTDLPCheckbox.Text := "yt-dlp found"
        setupGUIYTDLPCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIYTDLPCheckbox.Text := "yt-dlp not found"
        setupGUIYTDLPCheckbox.Opt("BackgroundRed")
    }

    setupGUIFFmpegCheckbox.Value := getFFmpegInstallionStatus()
    if (setupGUIFFmpegCheckbox.Value) {
        setupGUIFFmpegCheckbox.Text := "FFmpeg found"
        setupGUIFFmpegCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIFFmpegCheckbox.Text := "FFmpeg not found"
        setupGUIFFmpegCheckbox.Opt("BackgroundRed")
    }

    setupGUIFFplayCheckbox.Value := getFFplayInstallionStatus()
    if (setupGUIFFplayCheckbox.Value) {
        setupGUIFFplayCheckbox.Text := "FFplay found"
        setupGUIFFplayCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIFFplayCheckbox.Text := "FFplay not found"
        setupGUIFFplayCheckbox.Opt("BackgroundRed")
    }

    setupGUIFFprobeCheckbox.Value := getFFprobeInstallionStatus()
    if (setupGUIFFprobeCheckbox.Value) {
        setupGUIFFprobeCheckbox.Text := "FFprobe found"
        setupGUIFFprobeCheckbox.Opt("BackgroundGreen")
    }
    else {
        setupGUIFFprobeCheckbox.Text := "FFprobe not found"
        setupGUIFFprobeCheckbox.Opt("BackgroundRed")
    }

    ; Disables the button to delete all dependencies when there is no executable present at all.
    if (!setupGUIYTDLPCheckbox.Value && !setupGUIFFmpegCheckbox.Value && !setupGUIFFplayCheckbox.Value
        && !setupGUIFFprobeCheckbox.Value) {
        setupGUIDeleteAllDependenciesButton.Opt("+Disabled")
    }
    else {
        setupGUIDeleteAllDependenciesButton.Opt("-Disabled")
    }
}

; Creates all folders in case they do not exist.
createRequiredFolders() {
    requiredFolders := [
        applicationMainDirectory,
        assetDirectory,
        ffmpegDirectory,
        iconDirectory,
        ytdlpDirectory,
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
    global ffmpegDirectory

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
    setupGUIStatusBar.SetText("Downloading FFmpeg archive...")
    setupGUISetupProgressBar.Value += 20
    Download(ffmpegDownloadLink, downloadedFileLocation)
    ; Update the GUI.
    setupGUIStatusBar.SetText("Extracting FFmpeg archive...")
    setupGUISetupProgressBar.Value += 15
    RunWait('powershell.exe -Command "Expand-Archive -Path """' . downloadedFileLocation .
        '""" -DestinationPath """' .
        ffmpegDirectory . '""" -Force"', , "Hide")
    ; Update the GUI.
    setupGUIStatusBar.SetText("Moving FFmpeg files...")
    setupGUISetupProgressBar.Value += 10

    ; Moves all .EXE files from the extracted folder to the FFmpeg directory. Existing files will not be overwritten.
    relevantFiles := ["ffmpeg.exe", "ffplay.exe", "ffprobe.exe"]
    for (relevantFile in relevantFiles) {
        relevantFileSourcePath := ffmpegExecutablesDirectory . "\" . relevantFile
        relevantFileDestinationPath := ffmpegDirectory . "\" . relevantFile
        ; Do not overwrite existing files.
        if (!FileExist(relevantFileDestinationPath)) {
            FileMove(relevantFileSourcePath, relevantFileDestinationPath)
        }
    }
    ; Update the GUI.
    setupGUIStatusBar.SetText("Clean up...")
    setupGUISetupProgressBar.Value += 5
    ; Delete the downloaded .ZIP file and the extracted folder.
    FileDelete(downloadedFileLocation)
    DirDelete(ffmpegDirectory . "\" . downloadedFileNameWithoutExtension, true)
}

; Downloads the yt-dlp.exe from GitHub.
installYTDLP() {
    global ytdlpDirectory

    ; Define the file name and the file location.
    downloadedFileName := "yt-dlp.exe"
    downloadedFileLocation := ytdlpDirectory . "\" . downloadedFileName

    YTDLPDownloadLink := "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp.exe"
    ; Update the GUI.
    setupGUIStatusBar.SetText("Downloading yt-dlp...")
    setupGUISetupProgressBar.Value += 25
    ; The existing file will not be overwritten.
    if (!FileExist(downloadedFileLocation)) {
        Download(YTDLPDownloadLink, downloadedFileLocation)
    }
    ; Update the GUI.
    setupGUISetupProgressBar.Value += 25
}

/*
Checks if the FFmpeg and yt-dlp executables are present.
@returns [boolean] True, if the files are not present. False otherwise.
*/
checkIfFFmpegOrYTDLPSetupIsRequired() {
    if (!getYTDLPInstallionStatus() || !getFFmpegInstallionStatus() || !getFFplayInstallionStatus()
    || !getFFprobeInstallionStatus()) {
        return true
    }
    return false
}

/*
Checks if the FFmpeg executable is present.
@returns [boolean] True, if the FFmpeg executable is present. False otherwise.
*/
getFFmpegInstallionStatus() {
    global ffmpegDirectory

    if (!FileExist(ffmpegDirectory . "\ffmpeg.exe")) {
        return false
    }
    return true
}

/*
Checks if the FFplay executable is present.
@returns [boolean] True, if the FFplay executable is present. False otherwise.
*/
getFFplayInstallionStatus() {
    global ffmpegDirectory

    if (!FileExist(ffmpegDirectory . "\ffplay.exe")) {
        return false
    }
    return true
}

/*
Checks if the FFprobe executable is present.
@returns [boolean] True, if the FFprobe executable is present. False otherwise.
*/
getFFprobeInstallionStatus() {
    global ffmpegDirectory

    if (!FileExist(ffmpegDirectory . "\ffprobe.exe")) {
        return false
    }
    return true
}

/*
Checks if the yt-dlp executable is present.
@returns [boolean] True, if the yt-dlp executable is present. False otherwise.
*/
getYTDLPInstallionStatus() {
    global ytdlpDirectory

    if (!FileExist(ytdlpDirectory . "\yt-dlp.exe")) {
        return false
    }
    return true
}
