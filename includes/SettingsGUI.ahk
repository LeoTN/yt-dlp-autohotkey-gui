#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

settingsGUI_onInit() {
    global booleanUnsavedDirectoryChangesExist := false
    global booleanUnsavedPlaylistRangeIndexChangesExist := false
    global booleanUnsavedHotkeyChangesExist := false
    global booleanUnsavedHotkeyEnabledChangesExist := false

    createSettingsGUI()
    initializeCheckboxLinkedConfigFileEntryMap()
    initializeSettingsGUIDirectoryDDLEntryMap()
    initializeSettingsGUIHotkeyDDLEntryMap()
    importConfigFileValuesIntoSettingsGUI()

    if (!A_IsCompiled) {
        ; Certain options are unavailable with an uncompiled version of VideoDownloader.
        settingsGUIEnableAutoStartCheckbox.Opt("+Disabled")
        settingsGUICheckForUpdatesAtLaunchCheckbox.Opt("+Disabled")
        settingsGUIUpdateToBetaVersionsCheckbox.Opt("+Disabled")
        settingsGUIUpdateCheckForUpdatesButton.Opt("+Disabled")
    }
    ; Set the autostart according to the config file.
    if (readConfigFile("START_WITH_WINDOWS")) {
        setAutoStart(true)
    }
    else {
        setAutoStart(false)
    }
}

createSettingsGUI() {
    global
    settingsGUI := Gui("+OwnDialogs", "VD - Settings")
    ; Explicitly set the background color to avoid an issue with the ColorButton library.
    settingsGUI.BackColor := "f0f0f0"
    settingsGUI.MarginX := -5
    settingsGUI.MarginY := -5
    ; The space is intentional as it increases the tab size.
    local tabNames := ["   General   ", "   Video List   ", "   Hotkeys   "]
    settingsGUITabs := settingsGUI.Add("Tab3", "xm+5 ym+5 w626 h479", tabNames)

    /*
    ********************************************************************************************************************
    This section creates all the GUI control elements and event handlers.
    ********************************************************************************************************************
    */
    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(1)
    ; Application behavior settings.
    settingsGUIStartupSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+35 w600 h160", "Behavior")
    settingsGUIEnableAutoStartCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20", "Start with Windows")
    settingsGUIShowVideoListGUIAtLaunchCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Open the video list window at the start")
    settingsGUIRememberWindowPositionAndSizeCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Remember the video list window position and size")
    settingsGUICheckForUpdatesAtLaunchCheckbox := settingsGUI.Add("Checkbox", "yp+30 Checked",
        "Check for updates at the start")
    settingsGUIUpdateToBetaVersionsCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "I want to receive beta versions")
    settingsGUIUpdateCheckForUpdatesButton := settingsGUI.Add("Button", "yp+20 w200", "Check for Updates now")
    ; Notification settings.
    settingsGUINotificationSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+205 w600 h80", "Notifications")
    settingsGUIDisplayStartupNotificationCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Program launch")
    settingsGUIDisplayExitNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked", "Program exit")
    settingsGUIDisplayFinishedDownloadNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Download finished")
    ; Directory settings.
    settingsGUIDirectorySettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+295 w600 h175", "Directories")
    settingsGUIDirectoryDDL := settingsGUI.Add("DropDownList", "xp+10 yp+20 w580")
    settingsGUIDirectoryDescriptionEdit := settingsGUI.Add("Edit", "yp+30 w580 h40 -WantReturn +ReadOnly",
        "Please select a directory above.")
    ; A separator line.
    settingsGUIDirectoryHeadLineSeparatorLineProgressBar := settingsGUI.Add("Progress", "yp+50 w580 h5 cSilver")
    settingsGUIDirectoryHeadLineSeparatorLineProgressBar.Value := 100
    settingsGUIDirectoryInputEdit := settingsGUI.Add("Edit", "yp+15 w555 R1 -WantReturn +ReadOnly")
    settingsGUISelectDirectoryButton := settingsGUI.Add("Button", "xp+560 yp+1 w20 h20", "...")
    settingsGUISelectDirectoryButton.SetColor("ced4da", "000000", -1, "808080")
    settingsGUIDirectorySaveChangesButton := settingsGUI.Add("Button", "xp-560 yp+29 w187 +Disabled", "Save Changes")
    settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIDirectoryDiscardChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Discard Changes")
    settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    settingsGUIDirectoryResetChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Reset to Default")
    settingsGUIDirectoryResetChangesButton.SetColor("ffe8a1", "000000", -1, "808080")

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(2)
    ; Default video settings.
    settingsGUIDefaultVideoSettings := settingsGUI.Add("GroupBox", "xm+16 ym+35 w600 h120",
        "Default Video Preferences")
    settingsGUIVideoDesiredFormatText := settingsGUI.Add("Text", "xp+10 yp+20", "Desired Format")
    settingsGUIVideoDesiredFormatDDL := settingsGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    settingsGUIVideoDesiredSubtitleText := settingsGUI.Add("Text", "yp+30", "Desired Subtitle")
    settingsGUIVideoDesiredSubtitleDDL := settingsGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    ; Default manage video list settings.
    settingsGUIDefaultManageVideoListSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+165 w600 h210",
        "Default Manage Video List Preferences")
    settingsGUIAddVideoURLIsAPlaylistCheckbox := settingsGUI.Add("CheckBox", "xp+10 yp+20",
        "Add videos from a playlist")
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only add videos in a specific range")
    settingsGUIAddVideoSpecifyPlaylistRangeText := settingsGUI.Add("Text", "yp+20 w580", "Index Range")
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit := settingsGUI.Add("Edit", "yp+20 w180 +Disabled", "1")
    ; Remove video elements.
    settingsGUIRemoveVideoConfirmDeletionCheckbox := settingsGUI.Add("CheckBox", "yp+40",
        "Confirm deletion of selected videos")
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only multiple videos")
    ; Import and export elements.
    settingsGUIimportAndExportOnlyValidURLsCheckbox := settingsGUI.Add("CheckBox", "yp+30", "Only consider valid URLs")
    settingsGUIAutoExportVideoListCheckbox := settingsGUI.Add("CheckBox", "yp+20 Checked", "Auto export downloads")
    ; Default download settings.
    settingsGUIDefaultDownloadSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+385 w600 h60",
        "Default Download Preferences")
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Automatically remove downloaded videos")
    settingsGUIDownloadTerminateAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "Terminate after download")

    /*
    HOTKEY SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(3)
    settingsGUIHotkeysSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+35 w600 h175",
        "Hotkey Management Settings")
    settingsGUIHotkeyDDL := settingsGUI.Add("DropDownList", "xp+10 yp+20 w300")
    settingsGUIHotkeyText := settingsGUI.Add("Text", "yp+30", "Key Combination")
    settingsGUIHotkeyHotkeyInputField := settingsGUI.Add("Hotkey", "yp+20 w300")
    settingsGUIHotkeyDescriptionEdit := settingsGUI.Add("Edit", "xp+310 yp-50 w270 h71 -WantReturn +ReadOnly",
        "Please select a hotkey.")
    settingsGUIHotkeyEnabledRadio := settingsGUI.Add("Radio", "xp-310 yp+90", "Hotkey enabled")
    settingsGUIHotkeyDisabledRadio := settingsGUI.Add("Radio", "xp+150", "Hotkey disabled")
    settingsGUIHotkeyEnableAllButton := settingsGUI.Add("Button", "xp+160 yp-5 w130", "Enable all Hotkeys")
    settingsGUIHotkeyDisableAllButton := settingsGUI.Add("Button", "xp+140 w130", "Disable all Hotkeys")
    ; A separator line.
    settingsGUIHotkeyHeadLineSeparatorLineProgressBar := settingsGUI.Add("Progress", "xp-450 yp+30 w580 h5 cSilver")
    settingsGUIHotkeyHeadLineSeparatorLineProgressBar.Value := 100
    settingsGUIHotkeySaveChangesButton := settingsGUI.Add("Button", "yp+10 w187 +Disabled", "Save Changes")
    settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIHotkeyDiscardChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Discard Changes")
    settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    settingsGUIHotkeyResetChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Reset to Default")
    settingsGUIHotkeyResetChangesButton.SetColor("ffe8a1", "000000", -1, "808080")
    ; Status bar.
    settingsGUIStatusBar := settingsGUI.Add("StatusBar", , "Some settings might require a restart of VideoDownloader")
    settingsGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE

    ; Adds the event handlers for the settings GUI.
    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIUpdateCheckForUpdatesButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIUpdateCheckForUpdatesButton_onClick)
    settingsGUIDirectoryDDL.OnEvent("Change", handleSettingsGUI_settingsGUIDirectoryDDL_onChange)
    settingsGUISelectDirectoryButton.OnEvent("Click", handleSettingsGUI_settingsGUISelectDirectoryButton_onClick)
    settingsGUIDirectorySaveChangesButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIDirectorySaveChangesButton_onClick)
    settingsGUIDirectoryDiscardChangesButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIDirectoryDiscardChangesButton_onClick)
    settingsGUIDirectoryResetChangesButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIDirectoryResetChangesButton_onClick)
    ; Ckeckboxes
    settingsGUIEnableAutoStartCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIShowVideoListGUIAtLaunchCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIRememberWindowPositionAndSizeCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUICheckForUpdatesAtLaunchCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIUpdateToBetaVersionsCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayStartupNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayExitNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIVideoDesiredFormatDDL.OnEvent("Change", handleSettingsGUI_settingsGUIVideoDesiredFormatDDL_onChange)
    settingsGUIVideoDesiredSubtitleDDL.OnEvent("Change", handleSettingsGUI_settingsGUIVideoDesiredSubtitleDDL_onChange)
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.OnEvent("Change",
        handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange)
    ; Checkboxes
    settingsGUIAddVideoURLIsAPlaylistCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIRemoveVideoConfirmDeletionCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.OnEvent("Click",
        handleSettingsGUI_allCheckBox_onClick)
    settingsGUIimportAndExportOnlyValidURLsCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIAutoExportVideoListCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDownloadTerminateAfterDownloadCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)

    /*
    HOTKEY SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIHotkeyDDL.OnEvent("Change", handleSettingsGUI_settingsGUIHotkeyDDL_onChange)
    settingsGUIHotkeyHotkeyInputField.OnEvent("Change", handleSettingsGUI_settingsGUIHotkeyHotkeyInputField_onChange)
    settingsGUIHotkeyEnabledRadio.OnEvent("Click", handleSettingsGUI_allHotkeyRadio_onChange)
    settingsGUIHotkeyDisabledRadio.OnEvent("Click", handleSettingsGUI_allHotkeyRadio_onChange)
    settingsGUIHotkeyEnableAllButton.OnEvent("Click", handleSettingsGUI_settingsGUIHotkeyEnableAllButton_onClick)
    settingsGUIHotkeyDisableAllButton.OnEvent("Click", handleSettingsGUI_settingsGUIHotkeyDisableAllButton_onClick)
    settingsGUIHotkeySaveChangesButton.OnEvent("Click", handleSettingsGUI_settingsGUIHotkeySaveChangesButton_onClick)
    settingsGUIHotkeyDiscardChangesButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIHotkeyDiscardChangesButton_onClick)
    settingsGUIHotkeyResetChangesButton.OnEvent("Click", handleSettingsGUI_settingsGUIHotkeyResetChangesButton_onClick)
    ; Checks for any unsaved changes when closing the settings window.
    settingsGUI.OnEvent("Close", handleSettingsGUI_settingsGUI_onClose)

    /*
    ********************************************************************************************************************
    This section creates all GUI element tooltips.
    ********************************************************************************************************************
    */
    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    ; Application behavior settings.
    settingsGUIShowVideoListGUIAtLaunchCheckbox.ToolTip :=
        "Opens the video list window when VideoDownloader is launched."
    settingsGUIRememberWindowPositionAndSizeCheckbox.ToolTip :=
        "The state of the video list window will be saved when exiting VideoDownloader."
    settingsGUIRememberWindowPositionAndSizeCheckbox.ToolTip .=
        "`nNext time, it will be opened in the same position, size and minimized or maximized."
    settingsGUICheckForUpdatesAtLaunchCheckbox.ToolTip :=
        "Starts a PowerShell script to check for a later version when starting VideoDownloader."
    settingsGUIUpdateToBetaVersionsCheckbox.ToolTip :=
        "Newer beta versions will be considered as available updates."
    settingsGUIUpdateCheckForUpdatesButton.ToolTip := ""
    ; Notification settings.
    settingsGUIDisplayStartupNotificationCheckbox.ToolTip :=
        "Shows a toast notification when starting VideoDownloader."
    settingsGUIDisplayExitNotificationCheckbox.ToolTip :=
        "Shows a toast notification when VideoDownloader exits."
    settingsGUIDisplayExitNotificationCheckbox.ToolTip .=
        "`nSome exit events ignore this setting."
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.ToolTip :=
        "Shows a toast notification when finishing a download process."
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.ToolTip .=
        "`nClicking on this notification opens the directory containing the downloaded file(s)."
    ; Directory settings.
    settingsGUIDirectoryDDL.ToolTip := "You can change the path of each directory here."
    settingsGUIDirectoryDescriptionEdit.ToolTip := ""
    settingsGUIDirectoryInputEdit.ToolTip := ""
    settingsGUISelectDirectoryButton.ToolTip := ""
    settingsGUIDirectorySaveChangesButton.ToolTip := ""
    settingsGUIDirectoryDiscardChangesButton.ToolTip := ""
    settingsGUIDirectoryResetChangesButton.ToolTip := ""

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    ; Default video settings.
    settingsGUIVideoDesiredFormatDDL.ToolTip :=
        "Select a preferred download format. If available, the selected format will be downloaded directly."
    settingsGUIVideoDesiredFormatDDL.ToolTip .=
        "`nOtherwise a conversion with FFmpeg might be required which can take some time."
    settingsGUIVideoDesiredSubtitleDDL.ToolTip :=
        "More available subtitle options might be added in the future."
    ; Default manage video list settings.
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip :=
        "If a URL contains a reference or is itself a link to a playlist,"
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nonly the video specified in the URL or the very first video of the playlist will be added to the list."
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nEnable this option to instead download the complete playlist by default."
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox.ToolTip :=
        "Allows for a fine grained selection of videos from the playlist. See the help section for more information."
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.ToolTip :=
        "Enter the index range to select the videos from the playlist.`nMore information can be found in the help section."
    ; Remove video elements.
    settingsGUIRemoveVideoConfirmDeletionCheckbox.ToolTip :=
        "Shows a prompt to confirm the removal of one or more videos from the list."
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.ToolTip :=
        "If enabled, will only prompt to confirm the removal of multiple videos at once."
    ; Import and export elements.
    settingsGUIimportAndExportOnlyValidURLsCheckbox.ToolTip :=
        "Only video URLs that have been successfully extracted will be exported."
    settingsGUIimportAndExportOnlyValidURLsCheckbox.ToolTip .=
        "`nThe same goes for the import function which only imports valid URLs in case this checkbox is enabled."
    settingsGUIAutoExportVideoListCheckbox.ToolTip :=
        "Automatically exports the downloaded video URLs into a file."
    ; Default download settings.
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox.ToolTip :=
        "Removes the video from the list after downloading and processing it."
    settingsGUIDownloadTerminateAfterDownloadCheckbox.ToolTip :=
        "Closes VideoDownloader after downloading and processing all (selected) videos."

    /*
    HOTKEY SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIHotkeyDDL.ToolTip := "You can change each hotkey here."
    settingsGUIHotkeyHotkeyInputField.ToolTip := "Focus this input field an press a key combination."
    settingsGUIHotkeyDescriptionEdit.ToolTip := ""
    settingsGUIHotkeyEnabledRadio.ToolTip := "Enable the selected hotkey."
    settingsGUIHotkeyDisabledRadio.ToolTip := "Disable the selected hotkey."
    settingsGUIHotkeyEnableAllButton.ToolTip := ""
    settingsGUIHotkeyDisableAllButton.ToolTip := ""
    settingsGUIHotkeySaveChangesButton.ToolTip := ""
    settingsGUIHotkeyDiscardChangesButton.ToolTip := ""
    settingsGUIHotkeyResetChangesButton.ToolTip := ""
}

handleSettingsGUI_settingsGUIUpdateCheckForUpdatesButton_onClick(pButton, pInfo) {
    settingsGUIUpdateCheckForUpdatesButton.Opt("+Disabled")
    ; Does not check for updates, if there is no Internet connection or the application isn't compiled.
    if (!checkInternetConnection()) {
        MsgBox("There seems to be no connection to the Internet.", "VD - Manual Update Check", "O Icon! 262144 T2")
    }
    else if (!A_IsCompiled) {
        MsgBox("You cannot use this function with an uncompiled version.", "VD - Manual Update Check",
            "O Icon! 262144 T2")
    }
    else {
        availableUpdateVersion := checkForAvailableUpdates()
        if (availableUpdateVersion == "_result_no_update_available") {
            MsgBox("There are currently no updates available.", "VD - Manual Update Check", "O Iconi 262144 T2")
        }
        else {
            createUpdateGUI(availableUpdateVersion)
        }
    }
    settingsGUIUpdateCheckForUpdatesButton.Opt("-Disabled")
}

handleSettingsGUI_settingsGUIDirectoryDDL_onChange(pDDL, pInfo) {
    global booleanUnsavedDirectoryChangesExist
    global settingsGUIDirectoryDDLEntryMap
    ; This is used to select the previous DDL entry which has not been saved or discarded yet.
    static previouslySelectedDDLEntryIndex

    msgBoxText := "The directory path has been modified."
    msgBoxText .= "`n`nContinue without saving?"
    ; Checks for any unsaved changes.
    if (booleanUnsavedDirectoryChangesExist && !askUserToDiscardUnsavedChanges(msgBoxText)) {
        ; Selects the previously selected DDL entry.
        pDDL.Value := previouslySelectedDDLEntryIndex
        return
    }
    else {
        booleanUnsavedDirectoryChangesExist := false
        settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
        settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
        settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }

    previouslySelectedDDLEntryIndex := pDDL.Value
    selectedDirectoryDDLEntry := settingsGUIDirectoryDDLEntryMap.Get(pDDL.Text)
    ; Update the corresponding GUI elements.
    settingsGUIDirectoryDescriptionEdit.Value := selectedDirectoryDDLEntry.entryDescription
    settingsGUIDirectoryInputEdit.Value := selectedDirectoryDDLEntry.directory
    ; Enables the button to reset the directory to default.
    if (selectedDirectoryDDLEntry.directory != selectedDirectoryDDLEntry.defaultDirectory) {
        settingsGUIDirectoryResetChangesButton.Opt("-Disabled")
        settingsGUIDirectoryResetChangesButton.SetColor("ffc107", "000000", -1, "808080")
    }
    else {
        settingsGUIDirectoryResetChangesButton.Opt("+Disabled")
        settingsGUIDirectoryResetChangesButton.SetColor("ffe8a1", "000000", -1, "808080")
    }
}

handleSettingsGUI_settingsGUISelectDirectoryButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist

    if (DirExist(settingsGUIDirectoryInputEdit.Value)) {
        rootDirectory := settingsGUIDirectoryInputEdit.Value
    }
    else {
        rootDirectory := A_ScriptDir
    }
    selectedDirectory := directorySelectPrompt("VD - Please select a directory", rootDirectory, true)
    if (selectedDirectory != "_result_no_directory_selected") {
        previousDirectory := settingsGUIDirectoryInputEdit.Value
        settingsGUIDirectoryInputEdit.Value := selectedDirectory
        ; Enables the button to save or discard the changes if the selected directory differs from the previous one.
        if (settingsGUIDirectoryInputEdit.Value != previousDirectory) {
            booleanUnsavedDirectoryChangesExist := true
            settingsGUIDirectorySaveChangesButton.Opt("-Disabled")
            settingsGUIDirectorySaveChangesButton.SetColor("28a745", "000000", -1, "808080")
            settingsGUIDirectoryDiscardChangesButton.Opt("-Disabled")
            settingsGUIDirectoryDiscardChangesButton.SetColor("dc3545", "000000", -1, "808080")
        }
    }
}

handleSettingsGUI_settingsGUIDirectorySaveChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist := false

    selectedDirectoryDDLEntry := settingsGUIDirectoryDDLEntryMap.Get(settingsGUIDirectoryDDL.Text)
    selectedDirectoryDDLEntry.changeDirectory(settingsGUIDirectoryInputEdit.Value)
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    ; Disables the save and discard button.
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIDirectoryDiscardChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist := false

    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    ; Disables the save and discard button.
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIDirectoryResetChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist := false

    selectedDirectoryDDLEntry := settingsGUIDirectoryDDLEntryMap.Get(settingsGUIDirectoryDDL.Text)
    selectedDirectoryDDLEntry.resetDirectory()
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    ; Disables the save and discard button.
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIVideoDesiredFormatDDL_onChange(pDDL, pInfo) {
    ; Writes the index number of the selected element into the config file.
    editConfigFile(settingsGUIVideoDesiredFormatDDL.Value, "DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX")
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleDDL_onChange(pDDL, pInfo) {
    ; Writes the index number of the selected element into the config file.
    editConfigFile(settingsGUIVideoDesiredSubtitleDDL.Value, "DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX")
}

handleSettingsGUI_settingsGUIHotkeyDDL_onChange(pDDL, pInfo) {
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist
    global settingsGUIHotkeyDDLEntryMap
    ; This is used to select the previous DDL entry which has not been saved or discarded yet.
    static previouslySelectedDDLEntryIndex

    msgBoxText := "The hotkey has been modified."
    msgBoxText .= "`n`nContinue without saving?"
    ; Checks for any unsaved changes.
    if ((booleanUnsavedHotkeyChangesExist || booleanUnsavedHotkeyEnabledChangesExist)
    && !askUserToDiscardUnsavedChanges(msgBoxText)) {
        ; Selects the previously selected DDL entry.
        pDDL.Value := previouslySelectedDDLEntryIndex
        return
    }
    else {
        booleanUnsavedHotkeyChangesExist := false
        booleanUnsavedHotkeyEnabledChangesExist := false
        settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }

    previouslySelectedDDLEntryIndex := pDDL.Value
    selectedHotkeyDDLEntry := settingsGUIHotkeyDDLEntryMap.Get(pDDL.Text)
    ; Update the corresponding GUI elements.
    settingsGUIHotkeyDescriptionEdit.Value := selectedHotkeyDDLEntry.entryDescription
    settingsGUIHotkeyHotkeyInputField.Value := selectedHotkeyDDLEntry.hotkey
    ; Enable one of the two radio elements.
    if (selectedHotkeyDDLEntry.hotkeyEnabled) {
        settingsGUIHotkeyEnabledRadio.Value := true
    }
    else {
        settingsGUIHotkeyDisabledRadio.Value := true
    }
    ; Enables the button to reset the hotkey to default.
    if ((selectedHotkeyDDLEntry.hotkey != selectedHotkeyDDLEntry.defaultHotkey) ||
    (selectedHotkeyDDLEntry.hotkeyEnabled != selectedHotkeyDDLEntry.defaultHotkeyEnabled)) {
        settingsGUIHotkeyResetChangesButton.Opt("-Disabled")
        settingsGUIHotkeyResetChangesButton.SetColor("ffc107", "000000", -1, "808080")
    }
    else {
        settingsGUIHotkeyResetChangesButton.Opt("+Disabled")
        settingsGUIHotkeyResetChangesButton.SetColor("ffe8a1", "000000", -1, "808080")
    }
}

handleSettingsGUI_settingsGUIHotkeyHotkeyInputField_onChange(pHotkey, pInfo) {
    global booleanUnsavedHotkeyChangesExist

    ; This means there is no hotkey entry selected at the moment.
    if (settingsGUIHotkeyDDL.Value == 0) {
        return
    }
    selectedHotkeyDDLEntry := settingsGUIHotkeyDDLEntryMap.Get(settingsGUIHotkeyDDL.Text)
    ; Checks if the user made changes to the hotkey.
    if (pHotkey.Value != selectedHotkeyDDLEntry.hotkey) {
        booleanUnsavedHotkeyChangesExist := true
        settingsGUIHotkeySaveChangesButton.Opt("-Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("28a745", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("-Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("dc3545", "000000", -1, "808080")
    }
    else {
        booleanUnsavedHotkeyChangesExist := false
        settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }

}

; This function will be called when one of the two hotkey radio elements is checked or unchecked.
handleSettingsGUI_allHotkeyRadio_onChange(pRadio, pInfo) {
    global booleanUnsavedHotkeyEnabledChangesExist

    ; This means there is no hotkey entry selected at the moment.
    if (settingsGUIHotkeyDDL.Value == 0) {
        return
    }
    selectedHotkeyDDLEntry := settingsGUIHotkeyDDLEntryMap.Get(settingsGUIHotkeyDDL.Text)
    ; Checks if the user made changes to the hotkey enabled status.
    if (settingsGUIHotkeyEnabledRadio.Value != selectedHotkeyDDLEntry.hotkeyEnabled) {
        booleanUnsavedHotkeyEnabledChangesExist := true
        settingsGUIHotkeySaveChangesButton.Opt("-Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("28a745", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("-Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("dc3545", "000000", -1, "808080")
    }
    else {
        booleanUnsavedHotkeyEnabledChangesExist := false
        settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }
}

handleSettingsGUI_settingsGUIHotkeyEnableAllButton_onClick(pButton, pInfo) {
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist
    global settingsGUIHotkeyDDLEntryMap

    msgBoxText := "The hotkey has been modified."
    msgBoxText .= "`n`nContinue without saving?"
    ; Checks for any unsaved changes.
    if (booleanUnsavedHotkeyChangesExist || booleanUnsavedHotkeyEnabledChangesExist
        && !askUserToDiscardUnsavedChanges(msgBoxText)) {
        ; Do not discard the unsaved changes.
        return
    }
    else {
        booleanUnsavedHotkeyChangesExist := false
        booleanUnsavedHotkeyEnabledChangesExist := false
        settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }

    ; Enables all hotkeys.
    for (key, hotkeyEntry in settingsGUIHotkeyDDLEntryMap) {
        hotkeyEntry.changeHotkeyEnabled(true)
    }
    ; This makes sure that there is a selected entry.
    if (settingsGUIHotkeyDDL.Value != 0) {
        ; This function is called to update the corresponding GUI elements.
        handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    }
}

handleSettingsGUI_settingsGUIHotkeyDisableAllButton_onClick(pButton, pInfo) {
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist
    global settingsGUIHotkeyDDLEntryMap

    msgBoxText := "The hotkey has been modified."
    msgBoxText .= "`n`nContinue without saving?"
    ; Checks for any unsaved changes.
    if (booleanUnsavedHotkeyChangesExist || booleanUnsavedHotkeyEnabledChangesExist
        && !askUserToDiscardUnsavedChanges(msgBoxText)) {
        ; Do not discard the unsaved changes.
        return
    }
    else {
        booleanUnsavedHotkeyChangesExist := false
        booleanUnsavedHotkeyEnabledChangesExist := false
        settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
        settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
        settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
        settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    }

    ; Disables all hotkeys.
    for (key, hotkeyEntry in settingsGUIHotkeyDDLEntryMap) {
        hotkeyEntry.changeHotkeyEnabled(false)
    }
    ; This makes sure that there is a selected entry.
    if (settingsGUIHotkeyDDL.Value != 0) {
        ; This function is called to update the corresponding GUI elements.
        handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    }
}

handleSettingsGUI_settingsGUIHotkeySaveChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedHotkeyChangesExist := false
    global booleanUnsavedHotkeyEnabledChangesExist := false

    selectedHotkeyDDLEntry := settingsGUIHotkeyDDLEntryMap.Get(settingsGUIHotkeyDDL.Text)
    selectedHotkeyDDLEntry.changeHotkey(settingsGUIHotkeyHotkeyInputField.Value)
    selectedHotkeyDDLEntry.changeHotkeyEnabled(settingsGUIHotkeyEnabledRadio.Value)
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    ; Disables the save and discard button.
    settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
    settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
    settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIHotkeyDiscardChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedHotkeyChangesExist := false
    global booleanUnsavedHotkeyEnabledChangesExist := false

    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    ; Disables the save and discard button.
    settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
    settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
    settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIHotkeyResetChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedHotkeyChangesExist := false
    global booleanUnsavedHotkeyEnabledChangesExist := false

    selectedHotkeyDDLEntry := settingsGUIHotkeyDDLEntryMap.Get(settingsGUIHotkeyDDL.Text)
    selectedHotkeyDDLEntry.resetHotkey()
    selectedHotkeyDDLEntry.resetHotkeyEnabled()

    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    ; Disables the save and discard button.
    settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
    settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
    settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange(pEdit, pInfo) {
    global booleanUnsavedPlaylistRangeIndexChangesExist

    ; Displays an inidicator in the text to show the validity status.
    if (checkIfStringIsValidPlaylistIndexRange(pEdit.Value)) {
        settingsGUIAddVideoSpecifyPlaylistRangeText.Text := "Index Range (valid)"
        ; Writes the value to the config file.
        editConfigFile(pEdit.Value, "ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE")
        booleanUnsavedPlaylistRangeIndexChangesExist := false
    }
    else {
        settingsGUIAddVideoSpecifyPlaylistRangeText.Text := "Index Range (invalid)"
        booleanUnsavedPlaylistRangeIndexChangesExist := true
    }
}

/*
This function will be called when any checkbox is checked or unchecked.
It writes the value of the clicked checkbox to the config file and enables or disables certain checkboxes
depending on the activation status of others.
*/
handleSettingsGUI_allCheckBox_onClick(pCheckBox, pInfo) {
    global checkboxLinkedConfigFileEntryMap

    changeConfigFile(pCheckBox)

    ; Enable or disable certain checkboxes according to the value of other checkboxes.
    if (settingsGUIAddVideoURLIsAPlaylistCheckbox.Value) {
        settingsGUIAddVideoURLUsePlaylistRangeCheckbox.Opt("-Disabled")
    }
    else {
        settingsGUIAddVideoURLUsePlaylistRangeCheckbox.Opt("+Disabled")
        settingsGUIAddVideoURLUsePlaylistRangeCheckbox.Value := false
        changeConfigFile(settingsGUIAddVideoURLUsePlaylistRangeCheckbox)
    }
    if (settingsGUIAddVideoURLUsePlaylistRangeCheckbox.Value) {
        settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Opt("-Disabled")
    }
    else {
        settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Opt("+Disabled")
    }
    ; Remove video elements.
    if (settingsGUIRemoveVideoConfirmDeletionCheckbox.Value) {
        settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.Opt("-Disabled")
    }
    ; Disable the checkbox below and uncheck it.
    else {
        settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.Opt("+Disabled")
        settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value := false
        changeConfigFile(settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox)
    }

    ; This function will write the value of the given checkbox into the matching config file entry.
    changeConfigFile(pCheckbox) {
        if (checkboxLinkedConfigFileEntryMap.Has(pCheckBox)) {
            configFileEntryKey := checkboxLinkedConfigFileEntryMap.Get(pCheckBox)
            ; Writes the boolean value of the checkbox to the config file.
            editConfigFile(pCheckBox.Value, configFileEntryKey)
        }
        else {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] The following checkbox is not linked with a config file entry [" .
                pCheckBox.Text . "]", "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        }
    }

    ; Applies the changes made to the auto start configuration.
    if (pCheckBox.Text == "Start with Windows") {
        ; Set the autostart according to the config file.
        if (readConfigFile("START_WITH_WINDOWS")) {
            setAutoStart(true)
        }
        else {
            setAutoStart(false)
        }
    }
}

handleSettingsGUI_settingsGUI_onClose(pGUI) {
    global booleanUnsavedDirectoryChangesExist
    global booleanUnsavedPlaylistRangeIndexChangesExist
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist

    ; Checks for any unsaved changes.
    if (!askUserToDiscardUnsavedChanges()) {
        ; This stops the GUI from closing.
        return true
    }

    ; Discards the directory changes.
    booleanUnsavedDirectoryChangesExist := false
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectorySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
    ; This makes sure that there is a selected entry.
    if (settingsGUIDirectoryDDL.Value != 0) {
        handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    }

    ; Discards the playlist range index changes.
    booleanUnsavedPlaylistRangeIndexChangesExist := false
    ; Updates the playlist range index value and text.
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Value := readConfigFile("ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE")
    handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange(
        settingsGUIAddVideoSpecifyPlaylistRangeInputEdit, "")

    ; Discards the hotkey changes.
    booleanUnsavedHotkeyChangesExist := false
    booleanUnsavedHotkeyEnabledChangesExist := false
    ; This makes sure that there is a selected entry.
    if (settingsGUIHotkeyDDL.Value != 0) {
        handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
    }
    settingsGUIHotkeySaveChangesButton.Opt("+Disabled")
    settingsGUIHotkeySaveChangesButton.SetColor("94d3a2", "000000", -1, "808080")
    settingsGUIHotkeyDiscardChangesButton.Opt("+Disabled")
    settingsGUIHotkeyDiscardChangesButton.SetColor("e6a4aa", "000000", -1, "808080")
}

initializeCheckboxLinkedConfigFileEntryMap() {
    ; Each relevant config file entry name will be matched with the corresponding checkbox.
    global checkboxLinkedConfigFileEntryMap := Map()

    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    ; Application behavior settings.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIEnableAutoStartCheckbox, "START_WITH_WINDOWS")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIShowVideoListGUIAtLaunchCheckbox, "SHOW_VIDEO_LIST_GUI_ON_LAUNCH")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIRememberWindowPositionAndSizeCheckbox,
        "REMEMBER_LAST_VIDEO_LIST_GUI_POSITION_AND_SIZE")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUICheckForUpdatesAtLaunchCheckbox, "CHECK_FOR_UPDATES_AT_LAUNCH")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIUpdateToBetaVersionsCheckbox, "UPDATE_TO_BETA_VERSIONS")
    ; Notification settings.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIDisplayStartupNotificationCheckbox, "DISPLAY_STARTUP_NOTIFICATION")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIDisplayExitNotificationCheckbox, "DISPLAY_EXIT_NOTIFICATION")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIDisplayFinishedDownloadNotificationCheckbox,
        "DISPLAY_FINISHED_DOWNLOAD_NOTIFICATION")

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    ; Default manage video list settings.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIAddVideoURLIsAPlaylistCheckbox, "ADD_VIDEO_URL_IS_A_PLAYLIST")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIAddVideoURLUsePlaylistRangeCheckbox,
        "ADD_VIDEO_URL_USE_PLAYLIST_RANGE")
    ; Remove video elements.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIRemoveVideoConfirmDeletionCheckbox,
        "REMOVE_VIDEO_CONFIRM_DELETION")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox,
        "REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED")
    ; Import and export elements.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIimportAndExportOnlyValidURLsCheckbox,
        "IMPORT_AND_EXPORT_ONLY_VALID_URLS")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIAutoExportVideoListCheckbox, "AUTO_EXPORT_VIDEO_LIST")
    ; Default download settings.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIDownloadRemoveVideosAfterDownloadCheckbox,
        "REMOVE_VIDEOS_AFTER_DOWNLOAD")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIDownloadTerminateAfterDownloadCheckbox, "TERMINATE_AFTER_DOWNLOAD")
}

initializeSettingsGUIDirectoryDDLEntryMap() {
    global configFileEntryMap
    global settingsGUIDirectoryDDLEntryMap := Map()

    ; Create the directory entries and add them to the map.
    entryName := "Default Download Directory"
    entryDescription := "All downloads will be saved into this directory by default."
    linkedConfigFileEntry := configFileEntryMap.Get("DEFAULT_DOWNLOAD_DIRECTORYDirectoryPaths")
    entry := SettingsGUIDirectoryDDLEntry(entryName, entryDescription, linkedConfigFileEntry)
    settingsGUIDirectoryDDLEntryMap.Set(entryName, entry)

    entryName := "Temp Directory"
    entryDescription :=
        "This directory will be used to store temporary files. For example, during video extraction, the metadata is cached there."
    linkedConfigFileEntry := configFileEntryMap.Get("TEMP_DIRECTORYDirectoryPaths")
    entry := SettingsGUIDirectoryDDLEntry(entryName, entryDescription, linkedConfigFileEntry)
    settingsGUIDirectoryDDLEntryMap.Set(entryName, entry)

    entryName := "Temp Download Directory"
    entryDescription :=
        "This directory will be used to store the files during download before they are moved to their final destination."
    linkedConfigFileEntry := configFileEntryMap.Get("TEMP_DOWNLOAD_DIRECTORYDirectoryPaths")
    entry := SettingsGUIDirectoryDDLEntry(entryName, entryDescription, linkedConfigFileEntry)
    settingsGUIDirectoryDDLEntryMap.Set(entryName, entry)

    ; Fill the drop down list with the directory entry names.
    ddlContentArray := Array()
    for (entryName, value in settingsGUIDirectoryDDLEntryMap) {
        ddlContentArray.Push(entryName)
    }
    settingsGUIDirectoryDDL.Add(ddlContentArray)
}

initializeSettingsGUIHotkeyDDLEntryMap() {
    global configFileEntryMap
    global settingsGUIHotkeyDDLEntryMap := Map()

    ; Create the hotkey entries and add them to the map.

    ; Main hotkey (start download).
    entryName := "Start Download Hotkey"
    entryDescription := "This hotkey will start the download process. "
    entryDescription .= "It has the same effect as pressing the "
    entryDescription .= "[" . downloadStartButton.Text . "] button in the video list window."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("START_DOWNLOAD_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("START_DOWNLOAD_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_startDownload()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; First hotkey (collect URL).
    entryName := "Collect URL Hotkey"
    entryDescription := "This hotkey will collect the video URL from your browser search bar. "
    entryDescription .= "Your browser must be the active window for this to work."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("URL_COLLECT_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("URL_COLLECT_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_extractVideoURLFromSearchBar()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Second hotkey (collect URL from video thumbnail).
    entryName := "Collect URL from Thumbnail Hotkey"
    entryDescription :=
        "This hotkey will collect the video URL while hovering over the video thumbnail (for example on YouTube). "
    entryDescription .= "Your browser must be the active window for this to work. "
    entryDescription .= "The hotkey won't work most of the time because it is still experimental."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("THUMBNAIL_URL_COLLECT_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("THUMBNAIL_URL_COLLECT_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_extractVideoURLUnderMouseCursor()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Hotkey to open the video list GUI.
    entryName := "Open Video List GUI Hotkey"
    entryDescription := "This hotkey will open the video list GUI."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("VIDEO_LIST_GUI_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("VIDEO_LIST_GUI_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_openVideoListGUI()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Hotkey to terminate the program.
    entryName := "Terminate Program Hotkey"
    entryDescription := "This hotkey will terminate VideoDownloader."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("TERMINATE_PROGRAM_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("TERMINATE_PROGRAM_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_terminateProgram()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Hotkey to reload the program.
    entryName := "Reload Program Hotkey"
    entryDescription := "This hotkey will reload VideoDownloader."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("RELOAD_PROGRAM_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("RELOAD_PROGRAM_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_reloadProgram()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Fill the drop down list with the hotkey entry names.
    ddlContentArray := Array()
    for (entryName, value in settingsGUIHotkeyDDLEntryMap) {
        ddlContentArray.Push(entryName)
    }
    settingsGUIHotkeyDDL.Add(ddlContentArray)

    ; Makes the settings and help GUI the child window of the video list GUI.
    settingsGUI.Opt("+Owner" . videoListGUI.Hwnd)
    helpGUI.Opt("+Owner" . videoListGUI.Hwnd)
}

; Imports the config file content and sets the controls' values accordingly.
importConfigFileValuesIntoSettingsGUI() {
    global desiredDownloadFormatArray
    global desiredSubtitleArray
    global checkboxLinkedConfigFileEntryMap

    ; Checkboxes.
    for (checkbox, linkedConfigEntryKey in checkboxLinkedConfigFileEntryMap) {
        if (readConfigFile(linkedConfigEntryKey)) {
            checkbox.Value := true
        }
        else {
            checkbox.Value := false
        }
    }
    /*
    Calls the handleSettingsGUI_allCheckBox_onClick() function to enable or disable the checkboxes correctly.
    It doesn't matter which checkbox object we pass to the function in this case.
    */
    handleSettingsGUI_allCheckBox_onClick(settingsGUICheckForUpdatesAtLaunchCheckbox, "")

    ; Updates the playlist range index value and text.
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Value := readConfigFile("ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE")
    handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange(
        settingsGUIAddVideoSpecifyPlaylistRangeInputEdit, "")

    ; Updates the video format preferences DDL.
    settingsGUIVideoDesiredFormatDDL.Delete()
    settingsGUIVideoDesiredFormatDDL.Add(desiredDownloadFormatArray)
    selectedIndex := readConfigFile("DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX")
    settingsGUIVideoDesiredFormatDDL.Value := selectedIndex
    ; Updates the video subtitle preferences DDL.
    settingsGUIVideoDesiredSubtitleDDL.Delete()
    settingsGUIVideoDesiredSubtitleDDL.Add(desiredSubtitleArray)
    selectedIndex := readConfigFile("DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX")
    settingsGUIVideoDesiredSubtitleDDL.Value := selectedIndex
}

/*
Checks for any unsaved changes in the settings GUI and asks the user if they would like to discard the changes or not.
@param pMsgBoxText [String] An optional text for the MsgBox. If omitted, the function will list all unsaved changes.
@returns [boolean] True, if the user wants to continue without saving the changes (or there are no unsaved changes). False otherwise.
*/
askUserToDiscardUnsavedChanges(pMsgBoxText?) {
    global booleanUnsavedDirectoryChangesExist
    global booleanUnsavedPlaylistRangeIndexChangesExist
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist

    if (!booleanUnsavedDirectoryChangesExist && !booleanUnsavedPlaylistRangeIndexChangesExist &&
        !booleanUnsavedHotkeyChangesExist && !booleanUnsavedHotkeyEnabledChangesExist) {
        ; This means there are no unsaved changes.
        return true
    }

    if (IsSet(pMsgBoxText)) {
        msgBoxText := pMsgBoxText
    }
    else {
        ; Creates a report with all settings with unsaved changes.
        msgBoxText := "The following settings contain unsaved changes:`n`n"
        if (booleanUnsavedDirectoryChangesExist) {
            msgBoxText .= "Directory Settings`n"
        }
        if (booleanUnsavedPlaylistRangeIndexChangesExist) {
            msgBoxText .= "Playlist Range Index`n"
        }
        if (booleanUnsavedHotkeyChangesExist) {
            msgBoxText .= "Hotkey Combination`n"
        }
        if (booleanUnsavedHotkeyEnabledChangesExist) {
            msgBoxText .= "Hotkey Enabled`n"
        }
        msgBoxText .= "`nContinue without saving?"
    }

    result := MsgBox(msgBoxText, "VD - Unsaved Changes", "YN Icon! Owner" . settingsGUI.Hwnd)
    if (result != "Yes") {
        ; This means the user does not want to continue without saving.
        return false
    }
    ; This means the user wants to continue without saving.
    return true
}

/*
This object will be used to display the directory information in the settings GUI.
@param pEntryName [String] The name of the directory, for example "Default Download Directory".
@param pEntryDescription [String] The description of the directory.
@param pLinkedConfigFileEntry [ConfigFileEntry] A config file entry object which is used to change the path in the config file.
*/
class SettingsGUIDirectoryDDLEntry {
    __New(pEntryName, pEntryDescription, pLinkedConfigFileEntry) {
        if (!IsObject(pLinkedConfigFileEntry) || !pLinkedConfigFileEntry.HasOwnProp("valueType") ||
        pLinkedConfigFileEntry.valueType != "directory") {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid linked config file entry received.",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            return
        }

        this.entryName := pEntryName
        this.entryDescription := pEntryDescription
        this.linkedConfigFileEntry := pLinkedConfigFileEntry
        ; Loads the directory from the config file.
        this.directory := pLinkedConfigFileEntry.value
        this.defaultDirectory := pLinkedConfigFileEntry.defaultValue
    }
    changeDirectory(pNewDirectory) {
        this.directory := pNewDirectory
        this.linkedConfigFileEntry.changeValue(pNewDirectory)
    }
    resetDirectory() {
        this.directory := this.defaultDirectory
        this.linkedConfigFileEntry.changeValue(this.defaultDirectory)
    }
}

/*
This object will be used to display the hotkey information in the settings GUI.
@param pEntryName [String] The name of the hotkey.
@param pEntryDescription [String] The description of the hotkey.
@param pLinkedConfigFileEntryHotkey [ConfigFileEntry] A config file entry object which is used to change the hotkey in the config file.
@param pLinkedConfigFileEntryHotkeyEnabled [ConfigFileEntry] A config file entry object which is used to change the hotkey enabled status in the config file.
@param pHotkeyFunction [Function] The function which will be called when the hotkey is pressed. Must be in the following format:
    (*) => functionName()
*/
class SettingsGUIHotkeyDDLEntry {
    __New(pEntryName, pEntryDescription, pLinkedConfigFileEntryHotkey, pLinkedConfigFileEntryHotkeyEnabled,
        pHotkeyFunction) {
        this.entryName := pEntryName
        this.entryDescription := pEntryDescription
        this.linkedConfigFileEntryHotkey := pLinkedConfigFileEntryHotkey
        this.linkedConfigFileEntryHotkeyEnabled := pLinkedConfigFileEntryHotkeyEnabled
        this.hotkeyFunction := pHotkeyFunction
        ; Loads the hotkey from the config file.
        this.hotkey := pLinkedConfigFileEntryHotkey.value
        this.defaultHotkey := pLinkedConfigFileEntryHotkey.defaultValue
        this.hotkeyEnabled := pLinkedConfigFileEntryHotkeyEnabled.value
        this.defaultHotkeyEnabled := pLinkedConfigFileEntryHotkeyEnabled.defaultValue
        ; Enables the hotkey.
        if (this.hotkeyEnabled) {
            Hotkey(this.hotkey, this.hotkeyFunction, "On")
        }
        ; Disables the hotkey.
        else {
            Hotkey(this.hotkey, this.hotkeyFunction, "Off")
        }
    }
    changeHotkey(pNewHotkey) {
        this.hotkey := pNewHotkey
        this.linkedConfigFileEntryHotkey.changeValue(pNewHotkey)
    }
    resetHotkey() {
        this.hotkey := this.defaultHotkey
        this.linkedConfigFileEntryHotkey.changeValue(this.defaultHotkey)
    }
    changeHotkeyEnabled(pNewHotkeyEnabled) {
        this.hotkeyEnabled := pNewHotkeyEnabled
        this.linkedConfigFileEntryHotkeyEnabled.changeValue(pNewHotkeyEnabled)
        ; Enables the hotkey.
        if (this.hotkeyEnabled) {
            Hotkey(this.hotkey, this.hotkeyFunction, "On")
        }
        ; Disables the hotkey.
        else {
            Hotkey(this.hotkey, this.hotkeyFunction, "Off")
        }
    }
    resetHotkeyEnabled() {
        this.changeHotkeyEnabled(this.defaultHotkeyEnabled)
    }
}
