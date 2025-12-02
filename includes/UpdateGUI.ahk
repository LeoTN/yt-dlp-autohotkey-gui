updateGUI_onInit() {
    /*
    The application won't check for updates, if the option is disabled in the config file,
    has been launched for the very first time, is not compiled or there is no Internet connection.
    */
    if (!readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH") || booleanFirstTimeLaunch || !A_IsCompiled
    || !checkInternetConnection()) {
        return
    }

    if (readConfigFile("CHECK_FOR_YTDLP_UPDATES")) {
        availableYTDLPUpdateVersion := checkForAvailableYTDLPUpdates()
        ; Add a small reminder "pop-up menu" to update yt-dlp
        if (availableYTDLPUpdateVersion != "_result_no_update_available") {
            allMenus.Add("&Update yt-dlp → " . availableYTDLPUpdateVersion, (*) => updateYTDLP(availableYTDLPUpdateVersion))
            allMenus.SetIcon("&Update yt-dlp → " . availableYTDLPUpdateVersion, iconFileLocation, 31) ; ICON_DLL_USED_HERE
            ; Makes sure the icon loads correctly
            allMenus.Enable("&Update yt-dlp → " . availableYTDLPUpdateVersion)
        }
    }

    availableVDUpdateVersion := checkForAvailableUpdates()
    if (availableVDUpdateVersion == "_result_no_update_available") {
        return
    }
    createUpdateGUI(availableVDUpdateVersion)
}

/*
Creates the user inface which asks the user to confirm the update.
@param pUpdateVersion [String] The version of the update or rather the complete tag name.
*/
createUpdateGUI(pUpdateVersion) {
    global versionFullName

    ; Only creates the update GUI once.
    if (IsSet(updateGUI)) {
        updateGUI.Destroy()
    }
    ; Required information for the update GUI.
    updatePatchNotesURL := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/tag/" . pUpdateVersion
    compareVersionsURL := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/compare/"
        . versionFullName . "..." . pUpdateVersion
    msiDownloadURL := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/download/"
        . pUpdateVersion . "/VideoDownloader_" . pUpdateVersion . "_Installer.msi"

    global updateGUI := Gui("+AlwaysOnTop", "VideoDownloader - Update")

    updateGUIUpdateText := updateGUI.Add("Text", "w320 R3 Center", "Update Available → " . pUpdateVersion)
    updateGUIUpdateText.SetFont("bold s12")

    updateGUIPatchNotesLink := updateGUI.Add("Text", "yp+40 w320 R2 Center", "Patch Notes")
    updateGUIPatchNotesLink.SetFont("s10 underline cBlue")
    updateGUIPatchNotesLink.OnEvent("Click", (*) => Run(updatePatchNotesURL))

    /*
    Comparing versions is only possible for these scenarios:
        stable -> stable
        stable -> beta
    */
    if (!RegExMatch(versionFullName, "b\d+$")) {
        updateGUICompareVersionsLink := updateGUI.Add("Text", "yp+30 w320 R2 Center", "Compare Versions")
        updateGUICompareVersionsLink.SetFont("s10 underline cBlue")
        updateGUICompareVersionsLink.OnEvent("Click", (*) => Run(compareVersionsURL))
    }

    updateGUIDownloadMSIButton := updateGUI.Add("Button", "yp+30 xp+50 w100 R2", "Download MSI Installer")
    updateGUIDownloadMSIButton.OnEvent("Click", (*) => handleUpdateGUI_downloadMSIButton_onClick(msiDownloadURL))

    updateGUINoUpdateButton := updateGUI.Add("Button", "xp+110 w100 R2", "No Thanks")
    updateGUINoUpdateButton.OnEvent("Click", (*) => updateGUI.Destroy())

    if (IsSet(videoListGUI) && WinExist("ahk_id " . videoListGUI.Hwnd)) {
        showGUIRelativeToOtherGUI(videoListGUI, updateGUI, "MiddleCenter", "AutoSize")
        return
    }
    updateGUI.Show("AutoSize")
}

handleUpdateGUI_downloadMSIButton_onClick(pMSIDownloadURL) {
    Run(pMSIDownloadURL)
    backupDirectory := A_ScriptDir . "\VideoDownloader_old_version_backups"

    result := MsgBox(
        "This instance of VideoDownloader will exit now.`n`nSimply run the installer and follow the instructions."
        "`n`nIt is recommended to use the same installation directory as the previous version. " .
        "Otherwise you have to manually move the config files to the new location."
        "`n`nA backup of the old version will be created at`n'" . backupDirectory . "'.",
        "VideoDownloader - Update Process", "OC Icon! 262144")

    ; Exits the application if the user confirms.
    if (result == "OK") {
        backupOldVersionFiles(backupDirectory)
    }
}
