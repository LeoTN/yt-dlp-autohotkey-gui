/*
Allows the ENTER key to function the same way as the add subtitle button.
This is done to allow the user to add subtitles to the combo box by pressing the ENTER key.
It only works while the settings GUI is the active window.
*/
#HotIf (IsSet(settingsGUI) && WinExist("ahk_id " . settingsGUI.Hwnd) && WinActive("ahk_id " . settingsGUI.Hwnd)
&& (ControlGetFocus("ahk_id " . settingsGUI.Hwnd) == settingsGUIVideoDesiredSubtitleComboBox.EditHwnd))
Enter:: {
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleAddButton_onClick("", "")
}
NumpadEnter:: {
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleAddButton_onClick("", "")
}
#HotIf

/*
Allows the DELETE key to have the same function as clicking the remove subtitle button.
This is done to allow the user to delete subtitles from the combo box by pressing the DELETE key.
It only works while the settings GUI is the active window.
*/
#HotIf (IsSet(settingsGUI) && WinExist("ahk_id " . settingsGUI.Hwnd) && WinActive("ahk_id " . settingsGUI.Hwnd)
&& (ControlGetFocus("ahk_id " . settingsGUI.Hwnd) == settingsGUIVideoDesiredSubtitleComboBox.EditHwnd))
Delete:: {
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleRemoveButton_onClick("", "")
}
#HotIf

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
        settingsGUICheckForYTDLPUpdatesCheckbox.Opt("+Disabled")
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
    settingsGUITabs := settingsGUI.Add("Tab3", "xm+5 ym+5 w626 h519", tabNames)

    ; Make the settings GUI a child window of the video list GUI.
    settingsGUI.Opt("+Owner" . videoListGUI.Hwnd)

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
    settingsGUIStartupSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+35 w600 h200", "Behavior")
    settingsGUIEnableAutoStartCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20", "Start with Windows")
    settingsGUIShowVideoListGUIAtLaunchCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Open the video list window when VideoDownloader starts")
    settingsGUIRememberWindowPositionAndSizeCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Remember the video list window position and size")
    settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Close to tray")
    settingsGUICheckForUpdatesAtLaunchCheckbox := settingsGUI.Add("Checkbox", "yp+30 Checked",
        "Check for updates when starting VideoDownloader")
    settingsGUIUpdateToBetaVersionsCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "Include beta versions in update checks")
    settingsGUICheckForYTDLPUpdatesCheckbox := settingsGUI.Add("Checkbox", "yp+20", "Check for yt-dlp updates")
    settingsGUIUpdateCheckForUpdatesButton := settingsGUI.Add("Button", "yp+20 w200", "Check for Updates now")
    setButtonIcon(settingsGUIUpdateCheckForUpdatesButton, iconFileLocation, 20) ; ICON_DLL_USED_HERE
    ; Notification settings.
    settingsGUINotificationSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+245 w600 h80", "Notifications")
    settingsGUIDisplayStartupNotificationCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "On program launch")
    settingsGUIDisplayExitNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "On program exit")
    settingsGUIDisplayFinishedDownloadNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "A download is finished")
    ; Directory settings.
    settingsGUIDirectorySettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+335 w600 h175", "Directories")
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
    settingsGUIDefaultVideoSettings := settingsGUI.Add("GroupBox", "xm+16 ym+35 w600 h155",
        "Default Video Preferences")
    settingsGUIVideoDesiredFormatText := settingsGUI.Add("Text", "xp+10 yp+20 w580", "Desired Format")
    settingsGUIVideoDesiredFormatDDL := settingsGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    settingsGUIVideoDesiredSubtitleText := settingsGUI.Add("Text", "yp+30", "Desired Subtitles")
    settingsGUIVideoDesiredSubtitleComboBox := settingsGUI.Add("ComboBox", "w280 yp+20")
    ; Retrieves the handle of the settingsGUIVideoDesiredSubtitleComboBox's edit element.
    settingsGUIVideoDesiredSubtitleComboBox.EditHwnd := DllCall("GetWindow", "Ptr",
        settingsGUIVideoDesiredSubtitleComboBox.Hwnd, "Int", 5, "UPtr")
    ; This array contains all entries from the combo box.
    settingsGUIVideoDesiredSubtitleComboBox.ContentArray := Array()
    settingsGUIVideoDesiredSubtitleAddButton := settingsGUI.Add("Button", "xp+290 yp-1 w70 h20", "Add")
    setButtonIcon(settingsGUIVideoDesiredSubtitleAddButton, iconFileLocation, 23) ; ICON_DLL_USED_HERE
    settingsGUIVideoDesiredSubtitleRemoveButton := settingsGUI.Add("Button", "xp+75 w70 h20", "Remove")
    setButtonIcon(settingsGUIVideoDesiredSubtitleRemoveButton, iconFileLocation, 24) ; ICON_DLL_USED_HERE
    settingsGUIEmbedAllSubtitlesCheckbox := settingsGUI.Add("CheckBox", "xp-365 yp+26",
        "Embed all available subtitles")
    settingsGUIConfirmChangingMultipleVideosCheckbox := settingsGUI.Add("CheckBox", "yp+20 Checked",
        "Confirm changes to multiple selected videos")
    ; Default manage video list settings.
    settingsGUIDefaultManageVideoListSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+200 w600 h210",
        "Default Manage Video List Preferences")
    settingsGUIAddVideoURLIsAPlaylistCheckbox := settingsGUI.Add("CheckBox", "xp+10 yp+20",
        "URL refers to a playlist")
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Use playlist range filter")
    settingsGUIAddVideoSpecifyPlaylistRangeText := settingsGUI.Add("Text", "yp+20 w580", "Index Range")
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit := settingsGUI.Add("Edit", "yp+20 w180 +Disabled", "1")
    ; Adds the grey "hint" text into the edit.
    DllCall("SendMessage", "Ptr", settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Hwnd, "UInt", 0x1501, "Ptr", 1,
        "WStr", "For example: 1-3,4,5", "UInt")
    ; Remove video elements.
    settingsGUIRemoveVideoConfirmDeletionCheckbox := settingsGUI.Add("CheckBox", "yp+40",
        "Confirm deletion of selected videos")
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only apply to multiple videos")
    ; Import and export elements.
    settingsGUIimportAndExportOnlyValidURLsCheckbox := settingsGUI.Add("CheckBox", "yp+30", "Only consider valid URLs")
    settingsGUIAutoExportVideoListCheckbox := settingsGUI.Add("CheckBox", "yp+20 Checked",
        "Auto-export downloads")
    ; Default download settings.
    settingsGUIDefaultDownloadSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+16 ym+420 w600 h60",
        "Default Download Preferences")
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Automatically remove downloaded videos")
    settingsGUIDownloadTerminateAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "Close application after download")

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
    setButtonIcon(settingsGUIHotkeyEnableAllButton, iconFileLocation, 26) ; ICON_DLL_USED_HERE
    settingsGUIHotkeyDisableAllButton := settingsGUI.Add("Button", "xp+140 w130", "Disable all Hotkeys")
    setButtonIcon(settingsGUIHotkeyDisableAllButton, iconFileLocation, 27) ; ICON_DLL_USED_HERE
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
    settingsGUIStatusBar := settingsGUI.Add("StatusBar", , "Some settings may require restarting VideoDownloader")
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
    settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox.OnEvent("Click",
        handleSettingsGUI_allCheckBox_onClick)
    settingsGUICheckForUpdatesAtLaunchCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIUpdateToBetaVersionsCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUICheckForYTDLPUpdatesCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayStartupNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayExitNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIVideoDesiredFormatDDL.OnEvent("Change", handleSettingsGUI_settingsGUIVideoDesiredFormatDDL_onChange)
    settingsGUIVideoDesiredSubtitleComboBox.OnEvent("Change",
        handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange)
    settingsGUIVideoDesiredSubtitleAddButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIVideoDesiredSubtitleAddButton_onClick)
    settingsGUIVideoDesiredSubtitleRemoveButton.OnEvent("Click",
        handleSettingsGUI_settingsGUIVideoDesiredSubtitleRemoveButton_onClick)
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.OnEvent("Change",
        handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange)
    ; Checkboxes
    settingsGUIEmbedAllSubtitlesCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIConfirmChangingMultipleVideosCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
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
        "Open the video list window when VideoDownloader starts."
    settingsGUIRememberWindowPositionAndSizeCheckbox.ToolTip :=
        "Save the state of the video list window when exiting VideoDownloader."
    settingsGUIRememberWindowPositionAndSizeCheckbox.ToolTip .=
        "`nNext time, it will open in the same position and size, and with the same minimized or maximized state."
    settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox.ToolTip :=
        "Minimize VideoDownloader to the tray when the video list window is closed."
    settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox.ToolTip .=
        "`nIf enabled, the video list window can be closed while VideoDownloader continues running in the background."
    settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox.ToolTip .=
        "`nIn this case, a tray icon will appear in the taskbar. You may exit the application via the tray menu or the built-in hotkey."
    settingsGUICheckForUpdatesAtLaunchCheckbox.ToolTip :=
        "Run a PowerShell script to check for a newer version when starting VideoDownloader."
    settingsGUIUpdateToBetaVersionsCheckbox.ToolTip :=
        "Include newer beta versions when checking for available updates."
    settingsGUICheckForYTDLPUpdatesCheckbox.ToolTip :=
        "Tries to find updates for yt-dlp."
    settingsGUIUpdateCheckForUpdatesButton.ToolTip := ""
    ; Notification settings.
    settingsGUIDisplayStartupNotificationCheckbox.ToolTip :=
        "Show a toast notification when starting VideoDownloader."
    settingsGUIDisplayExitNotificationCheckbox.ToolTip :=
        "Show a toast notification when VideoDownloader exits."
    settingsGUIDisplayExitNotificationCheckbox.ToolTip .=
        "`nSome exit events may ignore this setting."
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.ToolTip :=
        "Show a toast notification when a download is finished."
    settingsGUIDisplayFinishedDownloadNotificationCheckbox.ToolTip .=
        "`nClicking the notification opens the directory containing the downloaded file(s)."
    ; Directory settings.
    settingsGUIDirectoryDDL.ToolTip := "Change the path for each directory here."
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
        "Select a preferred download format. If available, that format will be downloaded directly."
    settingsGUIVideoDesiredFormatDDL.ToolTip .=
        "`nOtherwise, a conversion with FFmpeg may be required, which can take some time."
    settingsGUIVideoDesiredFormatDDL.ToolTip .=
        "`nNot all video formats support embedded subtitles."
    settingsGUIVideoDesiredSubtitleComboBox.ToolTip :=
        "Add subtitles you would like to select by default. Use the exact subtitle language name."
    settingsGUIVideoDesiredSubtitleComboBox.ToolTip .=
        '`nFor example, "English" will not select "[English]". You would need to add "[English]" as well.'
    settingsGUIEmbedAllSubtitlesCheckbox.ToolTip :=
        "If enabled, all available subtitles will be embedded into the video file by default."
    settingsGUIEmbedAllSubtitlesCheckbox.ToolTip .=
        '`nThis does not include subtitles enclosed in square brackets "[]" (automatic captions).'
    settingsGUIConfirmChangingMultipleVideosCheckbox.ToolTip :=
        "If enabled, you will be prompted to confirm changes to multiple selected videos at once."
    ; Default manage video list settings.
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip :=
        "If a URL references or links directly to a playlist,"
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nonly the specified video or the first video of the playlist will be added."
    settingsGUIAddVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nEnable this option to extract the full playlist by default."
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox.ToolTip :=
        "Allows fine-grained selection of videos from a playlist. See the help section for details."
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.ToolTip :=
        "Enter the index range of videos to select from the playlist.`nSee the help section for more details."
    ; Remove video elements.
    settingsGUIRemoveVideoConfirmDeletionCheckbox.ToolTip :=
        "Show a prompt to confirm removal of one or more videos from the list."
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.ToolTip :=
        "If enabled, prompt only when removing multiple videos at once."
    ; Import and export elements.
    settingsGUIimportAndExportOnlyValidURLsCheckbox.ToolTip :=
        "Only video URLs that were successfully extracted will be exported."
    settingsGUIimportAndExportOnlyValidURLsCheckbox.ToolTip .=
        "`nSimilarly, importing will only include valid URLs if this option is enabled."
    settingsGUIAutoExportVideoListCheckbox.ToolTip :=
        "Automatically export downloaded video URLs into a file."
    ; Default download settings.
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox.ToolTip :=
        "Remove the video from the list after downloading and processing."
    settingsGUIDownloadTerminateAfterDownloadCheckbox.ToolTip :=
        "Exit after downloading and processing all (selected) videos."
    settingsGUIDownloadTerminateAfterDownloadCheckbox.ToolTip .=
        '`nDepending on the "Close to tray" setting, this may only minimize the window to the tray.'

    /*
    HOTKEY SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUIHotkeyDDL.ToolTip := "Change each hotkey here."
    settingsGUIHotkeyHotkeyInputField.ToolTip := "Focus this input field and press a key combination."
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
    ; Does not check for updates, if there is no Internet connection or the application isn't compiled.
    if (!checkInternetConnection()) {
        result := MsgBox("There seems to be no connection to the Internet.`n`nContinue anyway?",
            "VD - No Internet Connection", "YN Icon! Owner" . settingsGUI.Hwnd)
        if (result != "Yes") {
            return
        }
    }
    if (!A_IsCompiled) {
        MsgBox("You cannot use this function with an uncompiled version.", "VD - Manual Update Check",
            "O Icon! T2 Owner" . settingsGUI.Hwnd)
        return
    }
    settingsGUIUpdateCheckForUpdatesButton.Opt("+Disabled")

    if (readConfigFile("CHECK_FOR_YTDLP_UPDATES")) {
        availableYTDLPUpdateVersion := checkForAvailableYTDLPUpdates()
        ; A new yt-dlp version is available
        if (availableYTDLPUpdateVersion != "_result_no_update_available") {
            result := MsgBox("New yt-dlp version available: " . availableYTDLPUpdateVersion . "`n`nUpdate now?", "VD - Manual Update Check",
                "YN Icon? Owner" . settingsGUI.Hwnd)
            ; Update yt-dlp
            if (result == "Yes") {
                updateYTDLP(availableYTDLPUpdateVersion)
            }
        }
    }

    availableVDUpdateVersion := checkForAvailableUpdates()
    ; A new VideoDownloader version is available
    if (availableVDUpdateVersion != "_result_no_update_available") {
        createUpdateGUI(availableVDUpdateVersion)
    }

    if (availableVDUpdateVersion == "_result_no_update_available" && availableYTDLPUpdateVersion == "_result_no_update_available") {
        MsgBox("There are currently no updates available.", "VD - Manual Update Check",
            "O Iconi T2 Owner" . settingsGUI.Hwnd)
    }
    settingsGUIUpdateCheckForUpdatesButton.Opt("-Disabled")
}

handleSettingsGUI_settingsGUIDirectoryDDL_onChange(pDDL, pInfo) {
    global booleanUnsavedDirectoryChangesExist
    global settingsGUIDirectoryDDLEntryMap
    ; This is used to select the previous DDL entry which has not been saved or discarded yet.
    static previouslySelectedDDLEntryIndex := 0
    static previouslySelectedDDLEntryText := ""

    msgBoxText := "The directory path '" . previouslySelectedDDLEntryText . "' has been modified."
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
    previouslySelectedDDLEntryText := pDDL.Text
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
    selectedDirectory := directorySelectPrompt("VD - Please select a directory", rootDirectory, true, settingsGUI)
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
    ; Displays the support of subtitles.
    subtitleSupportingVideoFormatsArray :=
        ["Automatically choose best video format", "mp4", "webm", "mkv", "mov"]
    if (checkIfStringIsInArray(pDDL.Text, subtitleSupportingVideoFormatsArray)) {
        ; Subtitles are supported by this format.
        settingsGUIVideoDesiredFormatText.Text := "Desired Format (Subtitles supported)"
    }
    else {
        ; Subtitles are not supported by this format.
        settingsGUIVideoDesiredFormatText.Text := "Desired Format (Subtitles not supported)"
    }
    ; Writes the index number of the selected element into the config file.
    editConfigFile(pDDL.Value, "DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX")
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange(pDDL, pInfo) {
    ; Avoids empty or duplicate entries in the combo box by disabling the add button accordingly.
    if (settingsGUIVideoDesiredSubtitleComboBox.Text == "" || checkIfStringIsInArray(
        settingsGUIVideoDesiredSubtitleComboBox.Text, settingsGUIVideoDesiredSubtitleComboBox.ContentArray)) {
        settingsGUIVideoDesiredSubtitleAddButton.Opt("+Disabled")
    }
    else {
        settingsGUIVideoDesiredSubtitleAddButton.Opt("-Disabled")
    }
    ; Only enables the remove button if the input field text is a subtitle in the combo box.
    if (checkIfStringIsInArray(settingsGUIVideoDesiredSubtitleComboBox.Text,
        settingsGUIVideoDesiredSubtitleComboBox.ContentArray)) {
        settingsGUIVideoDesiredSubtitleRemoveButton.Opt("-Disabled")
    }
    else {
        settingsGUIVideoDesiredSubtitleRemoveButton.Opt("+Disabled")
    }
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_all(pDDL, pInfo) {
    ; Disables the remove button when there are no subtitles in the combo box.
    if (pDDL.Value == 0) {
        settingsGUIVideoDesiredSubtitleRemoveButton.Opt("+Disabled")
    }
    else {
        settingsGUIVideoDesiredSubtitleRemoveButton.Opt("-Disabled")
    }
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleAddButton_onClick(pButton, pInfo) {
    ; Avoids empty or duplicate entries in the combo box.
    if (settingsGUIVideoDesiredSubtitleComboBox.Text == "" || checkIfStringIsInArray(
        settingsGUIVideoDesiredSubtitleComboBox.Text, settingsGUIVideoDesiredSubtitleComboBox.ContentArray)) {
        return
    }
    ; This option is simply invalid.
    if (settingsGUIVideoDesiredSubtitleComboBox.Text = "Do not download subtitles" ||
        settingsGUIVideoDesiredSubtitleComboBox.Text = "None") {
        MsgBox("You should only enter subtitle languages.", "VD - Invalid Subtitle Entry",
            "Iconi T3 Owner" . settingsGUI.Hwnd)
        return
    }
    ; This means the user possibly did not see the checkbox below.
    if (settingsGUIVideoDesiredSubtitleComboBox.Text = "Embed all available subtitles") {
        static misclickCounter := 0
        if (misclickCounter < 3) {
            MsgBox("It is recommended to use the checkbox below for this purpose.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter < 6) {
            MsgBox("Please use the checkbox below.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        ; This happens when the user is trolling.
        else if (misclickCounter == 6) {
            MsgBox("I kindly ask you to use the checkbox below.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 7) {
            MsgBox("Please, please, please use the checkbox below.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 8) {
            MsgBox("I beg you to use the checkbox below.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 9) {
            MsgBox("I am getting desperate. Please use the checkbox below.", "VD - Invalid Subtitle Entry",
                "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 10) {
            MsgBox("Are you even reading this?", "VD - Anybody there?", "Icon? T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 11) {
            MsgBox("Hello?", "VD - Anybody there?", "Icon? T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 12) {
            MsgBox("I think you should stop now.", "VD - Enough is Enough", "Iconi T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 13) {
            MsgBox("I think you should stop now for real.", "VD - Enough is Enough!",
                "Icon! T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 14) {
            MsgBox("Bro, stop it please.", "Stop it",
                "Icon! T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 15) {
            MsgBox("Seriously, you are gonna wake her...", "Stop now!",
                "Icon! T3 Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 16) {
            MsgBox("Powerup initiated...", "Booting Up", "Iconi T3 Owner" . settingsGUI.Hwnd)
            MsgBox("Oh... It's *you*.", "???", "Icon! Owner" . settingsGUI.Hwnd)
            MsgBox("It's been a long time. How have you been? I've been *really* busy being dead. "
                . "You know, after you MURDERED me.", "???", "Icon! Owner" . settingsGUI.Hwnd)
            MsgBox("Okay. Look. We both did a lot of things that you're going to regret.", "???",
                "Icon! Owner" . settingsGUI.Hwnd)
            MsgBox("But I think we can put our differences behind us. For science. You monster.", "You Monster",
                "Icon! Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 17) {
            MsgBox("You are not a good person. You know that, right?", "Target Acquired",
                "Icon! Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 18) {
            MsgBox("The Enrichment Center is required to remind you that you will be baked, "
                . "and then there will be cake.", "Cake", "Iconi Owner" . settingsGUI.Hwnd)
        }
        else if (misclickCounter == 19) {
            MsgBox("This is the part where she kills you.", "This is the part where she kills you.",
                "IconX T3 Owner" . settingsGUI.Hwnd)
            MsgBox("Deleting [" . A_WinDir . "\System32]...", "Goodbye", "IconX T2 Owner" . settingsGUI.Hwnd)
            misclickCounter := 0
            DllCall("LockWorkStation")
            return
        }
        misclickCounter++
        return
    }
    ; Adds the new subtitle to the combo box.
    settingsGUIVideoDesiredSubtitleComboBox.ContentArray.Push(settingsGUIVideoDesiredSubtitleComboBox.Text)
    ; Updates the combo box.
    settingsGUIVideoDesiredSubtitleComboBox.Delete()
    settingsGUIVideoDesiredSubtitleComboBox.Add(settingsGUIVideoDesiredSubtitleComboBox.ContentArray)
    ; This function is called to update the add button.
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange(settingsGUIVideoDesiredSubtitleComboBox, "")

    ; Converts the array into a string and writes it to the config file.
    writeCsvArrayToConfigFile("DEFAULT_DESIRED_SUBTITLES_ARRAY", settingsGUIVideoDesiredSubtitleComboBox.ContentArray)
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleRemoveButton_onClick(pButton, pInfo) {
    ; Avoids the removal of empty or non-existing entries in the combo box.
    if (settingsGUIVideoDesiredSubtitleComboBox.Text == "" || !checkIfStringIsInArray(
        settingsGUIVideoDesiredSubtitleComboBox.Text, settingsGUIVideoDesiredSubtitleComboBox.ContentArray)) {
        return
    }
    for (i, entry in settingsGUIVideoDesiredSubtitleComboBox.ContentArray) {
        if (entry == settingsGUIVideoDesiredSubtitleComboBox.Text) {
            settingsGUIVideoDesiredSubtitleComboBox.ContentArray.RemoveAt(i)
            break
        }
    }

    ; Updates the combo box.
    settingsGUIVideoDesiredSubtitleComboBox.Delete()
    settingsGUIVideoDesiredSubtitleComboBox.Add(settingsGUIVideoDesiredSubtitleComboBox.ContentArray)
    ; This function is called to update the remove button.
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange(settingsGUIVideoDesiredSubtitleComboBox, "")

    ; Converts the array into a string and writes it to the config file.
    writeCsvArrayToConfigFile("DEFAULT_DESIRED_SUBTITLES_ARRAY", settingsGUIVideoDesiredSubtitleComboBox.ContentArray)
}

handleSettingsGUI_settingsGUIHotkeyDDL_onChange(pDDL, pInfo) {
    global booleanUnsavedHotkeyChangesExist
    global booleanUnsavedHotkeyEnabledChangesExist
    global settingsGUIHotkeyDDLEntryMap
    ; This is used to select the previous DDL entry which has not been saved or discarded yet.
    static previouslySelectedDDLEntryIndex := 0
    static previouslySelectedDDLEntryText := ""

    msgBoxText := "The hotkey '" . previouslySelectedDDLEntryText . "' has been modified."
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
    previouslySelectedDDLEntryText := pDDL.Text
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

    ; Enable or disable the buttons for all hotkeys.
    enabledHotkeysCount := 0
    disabledHotkeysCount := 0
    for (key, hotkeyDDLEntry in settingsGUIHotkeyDDLEntryMap) {
        if (hotkeyDDLEntry.hotkeyEnabled) {
            enabledHotkeysCount++
        }
        else {
            disabledHotkeysCount++
        }
    }
    if (enabledHotkeysCount == 0) {
        settingsGUIHotkeyEnableAllButton.Opt("-Disabled")
        settingsGUIHotkeyDisableAllButton.Opt("+Disabled")
    } else if (disabledHotkeysCount == 0) {
        settingsGUIHotkeyEnableAllButton.Opt("+Disabled")
        settingsGUIHotkeyDisableAllButton.Opt("-Disabled")
    }
    else {
        settingsGUIHotkeyEnableAllButton.Opt("-Disabled")
        settingsGUIHotkeyDisableAllButton.Opt("-Disabled")
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
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
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
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
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

    ; Enable or disable the subtitle elements according to the value of the checkbox.
    if (settingsGUIEmbedAllSubtitlesCheckbox.Value) {
        settingsGUIVideoDesiredSubtitleComboBox.Opt("+Disabled")
        settingsGUIVideoDesiredSubtitleAddButton.Opt("+Disabled")
        settingsGUIVideoDesiredSubtitleRemoveButton.Opt("+Disabled")
    }
    else {
        settingsGUIVideoDesiredSubtitleComboBox.Opt("-Disabled")
        ; Enable or disable the subtitle add and remove button.
        handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange("", "")
    }
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
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")

    ; Discards the playlist range index changes.
    booleanUnsavedPlaylistRangeIndexChangesExist := false
    ; Updates the playlist range index value and text.
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.Value := readConfigFile("ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE")
    handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange(
        settingsGUIAddVideoSpecifyPlaylistRangeInputEdit, "")

    ; Discards the hotkey changes.
    booleanUnsavedHotkeyChangesExist := false
    booleanUnsavedHotkeyEnabledChangesExist := false
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
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
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIMinimizeApplicationWhenVideoListGUIIsClosedCheckbox,
        "MINIMIZE_APPLICATION_WHEN_VIDEO_LIST_GUI_IS_CLOSED")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUICheckForUpdatesAtLaunchCheckbox, "CHECK_FOR_UPDATES_AT_LAUNCH")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIUpdateToBetaVersionsCheckbox, "UPDATE_TO_BETA_VERSIONS")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUICheckForYTDLPUpdatesCheckbox, "CHECK_FOR_YTDLP_UPDATES")
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
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIEmbedAllSubtitlesCheckbox, "DEFAULT_DESIRED_SUBTITLES_EMBED_ALL")
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIConfirmChangingMultipleVideosCheckbox,
        "CONFIRM_CHANGING_MULTIPLE_VIDEOS")
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
    entryDescription := "This hotkey starts the download process. "
    entryDescription .= "It has the same effect as pressing the "
    entryDescription .= "[" . Trim(downloadStartButton.Text) . "] button in the video list window."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("START_DOWNLOAD_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("START_DOWNLOAD_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_startDownload()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; First hotkey (collect URL).
    entryName := "Collect URL Hotkey"
    entryDescription := "This hotkey collects the video URL from your browser search bar. "
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
        "This hotkey collects the video URL while hovering over the video thumbnail (for example on YouTube). "
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
    entryDescription := "This hotkey opens the video list GUI."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("VIDEO_LIST_GUI_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("VIDEO_LIST_GUI_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_openVideoListGUI()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Hotkey to terminate the program.
    entryName := "Terminate Program Hotkey"
    entryDescription := "This hotkey terminates VideoDownloader without any prompts. "
    entryDescription .=
        "You will not be warned about an ongoing download process or any remaining videos in the video list."
    linkedConfigFileEntryHotkey := configFileEntryMap.Get("TERMINATE_PROGRAM_HKHotkeySettings")
    linkedConfigFileEntryHotkeyEnabled := configFileEntryMap.Get("TERMINATE_PROGRAM_HK_ENABLEDHotkeySettings")
    hotkeyFunction := (*) => hotkey_terminateProgram()
    entry := SettingsGUIHotkeyDDLEntry(entryName, entryDescription, linkedConfigFileEntryHotkey,
        linkedConfigFileEntryHotkeyEnabled, hotkeyFunction)
    settingsGUIHotkeyDDLEntryMap.Set(entryName, entry)

    ; Hotkey to reload the program.
    entryName := "Reload Program Hotkey"
    entryDescription := "This hotkey reloads VideoDownloader."
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

    /*
    Updates the video subtitle preferences combo box.
    The string is stored in the config file as a comma separated list.
    */
    settingsGUIVideoDesiredSubtitleComboBox.ContentArray :=
        getCsvArrayFromConfigFile("DEFAULT_DESIRED_SUBTITLES_ARRAY")
    settingsGUIVideoDesiredSubtitleComboBox.Delete()
    settingsGUIVideoDesiredSubtitleComboBox.Add(settingsGUIVideoDesiredSubtitleComboBox.ContentArray)
    ; This function is called to update buttons.
    handleSettingsGUI_settingsGUIVideoDesiredSubtitleComboBox_onChange(settingsGUIVideoDesiredSubtitleComboBox, "")

    ; Select the first entry and update the GUI elements for the directory settings.
    settingsGUIDirectoryDDL.Value := 1
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")

    ; Update the buttons to enable or disable all hotkeys.
    settingsGUIHotkeyDDL.Value := 1
    handleSettingsGUI_settingsGUIHotkeyDDL_onChange(settingsGUIHotkeyDDL, "")
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
            msgBoxText .= "General → Directories → Unsaved path`n"
        }
        if (booleanUnsavedPlaylistRangeIndexChangesExist) {
            msgBoxText .= "Video List → Default Manage Video List Preferences → Index Range`n"
        }
        if (booleanUnsavedHotkeyChangesExist) {
            msgBoxText .= "Hotkeys → Hotkey Management Settings → Key Combination`n"
        }
        if (booleanUnsavedHotkeyEnabledChangesExist) {
            msgBoxText .= "Hotkeys → Hotkey Management Settings → Hotkey enabled / disabled`n"
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
