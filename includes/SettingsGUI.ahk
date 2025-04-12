#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

createSettingsGUI() {
    global
    settingsGUI := Gui("+AlwaysOnTop", "VD - Settings (currently partially non functional)") ; REMOVE ALWAYSONTOP
    ; The space is intentional as it increases the tab size.
    local tabNames := ["   General   ", "   Video List (WIP)   ", "   Hotkeys (WIP)   "] ; REMOVE
    settingsGUITabs := settingsGUI.Add("Tab3", , tabNames)
    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(1)
    ; Update settings.
    settingsGUIUpdateSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+30 w600 h90", "Update")
    settingsGUICheckForUpdatesAtLaunchCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Check for updates at the start")
    settingsGUIUpdateToBetaVersionsCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "I want to receive beta versions")
    settingsGUIUpdateCheckForUpdatesButton := settingsGUI.Add("Button", "yp+20 w200", "Check for Updates now")
    ; Notification settings.
    settingsGUINotificationSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+130 w600 h80", "Notifications")
    settingsGUIDisplayStartupNotificationCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Program launch")
    settingsGUIDisplayExitNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked", "Program exit")
    settingsGUIDisplayFinishedDownloadNotificationCheckbox := settingsGUI.Add("Checkbox", "yp+20 Checked",
        "Download finished")
    ; Directory settings.
    settingsGUIDirectorySettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+220 w600 h175", "Directories")
    settingsGUIDirectoryDDL := settingsGUI.Add("DropDownList", "xp+10 yp+20 w580")
    settingsGUIDirectoryDescriptionEdit := settingsGUI.Add("Edit", "yp+30 w580 h40 -WantReturn +ReadOnly",
        "No description available.")
    ; A separator line.
    customMsgBoxGUIHeadLineSeparatorLineProgressBar := settingsGUI.Add("Progress", "yp+50 w580 h5 cSilver")
    customMsgBoxGUIHeadLineSeparatorLineProgressBar.Value := 100
    settingsGUIDirectoryInputEdit := settingsGUI.Add("Edit", "yp+15 w555 R1 -WantReturn +ReadOnly")
    settingsGUISelectDirectoryButton := settingsGUI.Add("Button", "xp+560 yp+1 w20 h20", "...")
    settingsGUIDirectorySaveChangesButton := settingsGUI.Add("Button", "xp-560 yp+29 w187 +Disabled", "Save Changes")
    settingsGUIDirectoryDiscardChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Discard Changes")
    settingsGUIDirectoryResetChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Reset to Default")

    /*
    VIDEO LIST SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(2)
    ; Default video settings.
    settingsGUIDefaultVideoSettings := settingsGUI.Add("GroupBox", "xm+10 ym+30 w600 h180",
        "Default Video Preferences")
    settingsGUIVideoDesiredFormatText := settingsGUI.Add("Text", "xp+10 yp+20", "Desired Format")
    settingsGUIVideoDesiredFormatDDL := settingsGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    settingsGUIVideoDesiredSubtitleText := settingsGUI.Add("Text", "yp+30", "Desired Subtitle")
    settingsGUIVideoDesiredSubtitleDDL := settingsGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    settingsGUIVideoAdvancedDownloadSettingsText := settingsGUI.Add("Text", "yp+30 w580 h40",
        "Advanced Download Settings")
    settingsGUIVideoAdvancedDownloadSettingsText.SetFont("bold s12")
    settingsGUIVideoAdvancedDownloadSettingsPlaceHolderText := settingsGUI.Add("Text", "yp+20", "Not implemented yet.") ; REMOVE
    ; Default manage video list settings.
    settingsGUIDefaultManageVideoListSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+220 w600 h210",
        "Default Manage Video List Preferences")
    settingsGUIAddVideoURLIsAPlaylistCheckbox := settingsGUI.Add("CheckBox", "xp+10 yp+20",
        "Add videos from a playlist")
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only add videos in a specific range")
    settingsGUIAddVideoSpecifyPlaylistRangeText := settingsGUI.Add("Text", "yp+20", "Index Range")
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit := settingsGUI.Add("Edit", "yp+20 w100 +Disabled", "1")
    ; Remove video elements.
    settingsGUIRemoveVideoConfirmDeletionCheckbox := settingsGUI.Add("CheckBox", "yp+40",
        "Confirm deletion of selected videos")
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox := settingsGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only multiple videos")
    ; Import and export elements.
    settingsGUIExportOnlyValidURLsCheckbox := settingsGUI.Add("CheckBox", "yp+30", "Only consider valid URLs")
    settingsGUIAutoExportVideoListCheckbox := settingsGUI.Add("CheckBox", "yp+20 Checked", "Auto export downloads")
    ; Default download settings.
    settingsGUIDefaultDownloadSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+440 w600 h60",
        "Default Download Preferences")
    settingsGUIDownloadRemoveVideosAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "xp+10 yp+20 Checked",
        "Automatically remove downloaded videos")
    settingsGUIDownloadTerminateAfterDownloadCheckbox := settingsGUI.Add("Checkbox", "yp+20",
        "Terminate application after download")

    /*
    HOTKEY SETTINGS TAB
    -------------------------------------------------
    */
    settingsGUITabs.UseTab(3)
    settingsGUIHotkeysSettingsGroupBox := settingsGUI.Add("GroupBox", "xm+10 ym+30 w600 h175",
        "Hotkey Management Settings")
    settingsGUIHotkeyDDL := settingsGUI.Add("DropDownList", "xp+10 yp+20 w300")
    settingsGUIHotkeyText := settingsGUI.Add("Text", "yp+30", "Key Combination")
    settingsGUIHotkeyHotkeyInputField := settingsGUI.Add("Hotkey", "yp+20 w300")
    settingsGUIHotkeyDescriptionEdit := settingsGUI.Add("Edit", "xp+310 yp-50 w270 h71 -WantReturn +ReadOnly",
        "No description available.")
    settingsGUIHotkeyEnabledRadio := settingsGUI.Add("Radio", "xp-310 yp+90", "Hotkey enabled")
    settingsGUIHotkeyDisabledRadio := settingsGUI.Add("Radio", "xp+150", "Hotkey disabled")
    settingsGUIHotkeyEnableAllButton := settingsGUI.Add("Button", "xp+160 yp-5 w130", "Enable all Hotkeys")
    settingsGUIHotkeyDisableAllButton := settingsGUI.Add("Button", "xp+140 w130", "Disable all Hotkeys")
    ; A separator line.
    customMsgBoxGUIHeadLineSeparatorLineProgressBar := settingsGUI.Add("Progress", "xp-450 yp+30 w580 h5 cSilver")
    customMsgBoxGUIHeadLineSeparatorLineProgressBar.Value := 100
    settingsGUIHotkeySaveChangesButton := settingsGUI.Add("Button", "yp+10 w187 +Disabled", "Save Changes")
    settingsGUIHotkeyDiscardChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Discard Changes")
    settingsGUIHotkeyResetChangesButton := settingsGUI.Add("Button", "xp+197 w187 +Disabled", "Reset to Default")

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
    ; Checkboxes
    settingsGUIAddVideoURLIsAPlaylistCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIAddVideoURLUsePlaylistRangeCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIAddVideoSpecifyPlaylistRangeInputEdit.OnEvent("Change",
        handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange)
    settingsGUIRemoveVideoConfirmDeletionCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
    settingsGUIRemoveVideoConfirmOnlyWhenMultipleSelectedCheckbox.OnEvent("Click",
        handleSettingsGUI_allCheckBox_onClick)
    settingsGUIExportOnlyValidURLsCheckbox.OnEvent("Click", handleSettingsGUI_allCheckBox_onClick)
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
}

settingsGUI_onInit() {
    global booleanUnsavedDirectoryChangesExist := false

    createSettingsGUI()
    initializeCheckboxLinkedConfigFileEntryMap()
    initializeSettingsGUIDirectoryDDLEntryMap()
    importConfigFileValuesIntoSettingsGUI()
}

handleSettingsGUI_settingsGUIUpdateCheckForUpdatesButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIDirectoryDDL_onChange(pDDL, pInfo) {
    global booleanUnsavedDirectoryChangesExist
    global settingsGUIDirectoryDDLEntryMap
    ; This is used to select the previous DDL entry which has not been saved or discarded yet.
    static previouslySelectedDDLEntryIndex

    if (booleanUnsavedDirectoryChangesExist) {
        result := MsgBox("There are unsaved changes.`n`nContinue?", "VD - Unsaved Changes", "YN Icon! 262144")
        if (result != "Yes") {
            ; Selects the previously selected DDL entry.
            pDDL.Value := previouslySelectedDDLEntryIndex
            return
        }
        booleanUnsavedDirectoryChangesExist := false
        settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
        settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
    }

    previouslySelectedDDLEntryIndex := pDDL.Value
    selectedDirectoryDDLEntry := settingsGUIDirectoryDDLEntryMap.Get(pDDL.Text)
    ; Update the corresponding GUI elements.
    settingsGUIDirectoryDescriptionEdit.Value := selectedDirectoryDDLEntry.entryDescription
    settingsGUIDirectoryInputEdit.Value := selectedDirectoryDDLEntry.directory
    ; Enables the button to reset the directory to default.
    if (selectedDirectoryDDLEntry.directory != selectedDirectoryDDLEntry.defaultDirectory) {
        settingsGUIDirectoryResetChangesButton.Opt("-Disabled")
    }
    else {
        settingsGUIDirectoryResetChangesButton.Opt("+Disabled")
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
    selectedDirectory := directorySelectPrompt("VD - Please select a directory", rootDirectory)
    if (selectedDirectory != "_result_no_directory_selected") {
        previousDirectory := settingsGUIDirectoryInputEdit.Value
        settingsGUIDirectoryInputEdit.Value := selectedDirectory
        ; Enables the button to save or discard the changes if the selected directory differs from the previous one.
        if (settingsGUIDirectoryInputEdit.Value != previousDirectory) {
            booleanUnsavedDirectoryChangesExist := true
            settingsGUIDirectorySaveChangesButton.Opt("-Disabled")
            settingsGUIDirectoryDiscardChangesButton.Opt("-Disabled")
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
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
}

handleSettingsGUI_settingsGUIDirectoryDiscardChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist := false

    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    ; Disables the save and discard button.
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
}

handleSettingsGUI_settingsGUIDirectoryResetChangesButton_onClick(pButton, pInfo) {
    global booleanUnsavedDirectoryChangesExist := false

    selectedDirectoryDDLEntry := settingsGUIDirectoryDDLEntryMap.Get(settingsGUIDirectoryDDL.Text)
    selectedDirectoryDDLEntry.resetDirectory()
    ; This function is called to update the corresponding GUI elements.
    handleSettingsGUI_settingsGUIDirectoryDDL_onChange(settingsGUIDirectoryDDL, "")
    ; Disables the save and discard button.
    settingsGUIDirectorySaveChangesButton.Opt("+Disabled")
    settingsGUIDirectoryDiscardChangesButton.Opt("+Disabled")
}

handleSettingsGUI_settingsGUIVideoDesiredFormatDDL_onChange(pDDL, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIVideoDesiredSubtitleDDL_onChange(pDDL, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyDDL_onChange(pDDL, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyHotkeyInputField_onChange(pHotkey, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

; This function will be called when one of the two hotkey radio elements is checked or unchecked.
handleSettingsGUI_allHotkeyRadio_onChange(pRadio, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyEnableAllButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyDisableAllButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeySaveChangesButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyDiscardChangesButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIHotkeyResetChangesButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleSettingsGUI_settingsGUIAddVideoSpecifyPlaylistRangeInputEdit_onChange(pEdit, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
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
}

initializeCheckboxLinkedConfigFileEntryMap() {
    ; Each relevant config file entry name will be matched with the corresponding checkbox.
    global checkboxLinkedConfigFileEntryMap := Map()

    /*
    GENERAL SETTINGS TAB
    -------------------------------------------------
    */
    ; Update settings.
    checkboxLinkedConfigFileEntryMap.Set(settingsGUICheckForUpdatesAtLaunchCheckbox,
        "CHECK_FOR_UPDATES_AT_LAUNCH")
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
    checkboxLinkedConfigFileEntryMap.Set(settingsGUIExportOnlyValidURLsCheckbox, "EXPORT_ONLY_VALID_URLS")
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

; Imports the config file content and sets the controls' values accordingly.
importConfigFileValuesIntoSettingsGUI() {
    global checkboxLinkedConfigFileEntryMap

    ; Checkboxes.
    for (checkbox, linkedConfigEntryKey in checkboxLinkedConfigFileEntryMap) {
        checkbox.Value := readConfigFile(linkedConfigEntryKey)
    }
    /*
    Calls the handleSettingsGUI_allCheckBox_onClick() function to enable or disable the checkboxes correctly.
    It doesn't matter which checkbox object we pass to the function in this case.
    */
    handleSettingsGUI_allCheckBox_onClick(settingsGUICheckForUpdatesAtLaunchCheckbox, "")
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
