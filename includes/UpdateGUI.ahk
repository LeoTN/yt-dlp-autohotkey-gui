#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

updateGUI_onInit() {
    /*
    The script won't check for updates if it is disabled in the config file
    or the script has been launched for the very first time.
    */
    if (!readConfigFile("CHECK_FOR_UPDATES_AT_LAUNCH") || booleanFirstTimeLaunch) {
        return
    }
    availableUpdateVersion := checkForAvailableUpdates()
    if (availableUpdateVersion == "_result_no_update_available") {
        return
    }
    createUpdateGUI(availableUpdateVersion)
}

/*
Creates the user inface which asks the user to confirm the update.
@param pUpdateVersion [String] The version of the update or rather the complete tag name.
*/
createUpdateGUI(pUpdateVersion) {
    ; Required information for the update GUI.
    updatePatchNotesURL := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/tag/" . pUpdateVersion
    msiDownloadURL := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/download/"
        . pUpdateVersion . "/VideoDownloader_" . pUpdateVersion . "_Installer.msi"

    global updateGUI := Gui(, "VideoDownloader - Update")
    updateGUIUpdateText := updateGUI.Add("Text", "w320 R3 Center", "Update Available - [" . pUpdateVersion . "]")
    updateGUIUpdateText.SetFont("bold s12")

    updateGUIPatchNotesLink := updateGUI.Add("Text", "yp+40 w320 R2 Center", "Patch Notes")
    updateGUIPatchNotesLink.SetFont("s10 underline cBlue")
    updateGUIPatchNotesLink.OnEvent("Click", (*) => Run(updatePatchNotesURL))

    updateGUIDownloadMSIButton := updateGUI.Add("Button", "yp+30 xp+50 w100 R2", "Download MSI Installer")
    updateGUIDownloadMSIButton.OnEvent("Click", (*) => handleUpdateGUI_downloadMSIButton(msiDownloadURL))

    updateGUINoUpdateButton := updateGUI.Add("Button", "xp+110 w100 R2", "No Thanks")
    updateGUINoUpdateButton.OnEvent("Click", (*) => updateGUI.Destroy())

    updateGUI.Show()
}

handleUpdateGUI_downloadMSIButton(pMSIDownloadURL) {
    Run(pMSIDownloadURL)
    backupDirectory := A_ScriptDir . "\VideoDownloader_old_version_backups"

    result := MsgBox(
        "This instance of VideoDownloader will exit now.`n`nSimply run the installer and follow the instructions."
        "`n`nIt is recommended to use the same installation directory as the previous version. " .
        "Otherwise you have to manually move the config files to the new location."
        "`n`nA backup of the old version will be created at`n[" . backupDirectory . "].",
        "VideoDownloader - Update Process", "OC Icon! 262144")

    ; Exits the script if the user confirms.
    if (result == "OK") {
        backupOldVersionFiles(backupDirectory)
    }
}
