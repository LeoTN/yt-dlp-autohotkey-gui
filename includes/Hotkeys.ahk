hotkeys_onInit() {
    /*
    The non debug hotkeys will be initialized by the initializeSettingsGUIHotkeyDDLEntryMap() function
    which creates the required SettingsGUIHotkeyDDLEntry objects.
    */
    ; Sometimes the debug hotkeys might be needed.
    if (!readConfigFile("ENABLE_DEBUG_HOTKEYS")) {
        return
    }
    try {
        registerDebugHotkeys()
    }
    catch as error {
        displayErrorMessage(error)
    }
}

registerDebugHotkeys() {
    Hotkey("F5", (*) => hotkey_debug_1(), "On")
    Hotkey("F6", (*) => hotkey_debug_2(), "On")
    Hotkey("F7", (*) => hotkey_debug_3(), "On")
    Hotkey("F8", (*) => hotkey_debug_4(), "On")
}

/*
HOTKEY FUNCTION SECTION
-------------------------------------------------
Add functions that will be called by hotkeys below.
*/

; Starts the video download process. Same as pressing the download button in the video list GUI.
hotkey_startDownload() {
    handleVideoListGUI_downloadStartButton_onClick("", "")
}

; Extracts the video URL from the browser search bar.
hotkey_extractVideoURLFromSearchBar() {
    A_Clipboard := ""
    Send("^{l}")
    Sleep(150)
    Send("^{c}")
    if (!ClipWait(0.5)) {
        MsgBox("No URL detected.", "VD - Missing URL", "O Iconi T1")
        return
    }
    clipboardContent := A_Clipboard
    Sleep(150)
    Send("{Escape}")
    Send("{Escape}")
    if (!checkIfStringIsAValidURL(clipboardContent)) {
        MsgBox("No URL detected.", "VD - Missing URL", "O Iconi T1")
        return
    }
    ; Extracts the video meta data and checks if it is already in the video list.
    resultArray := createVideoListViewEntry(clipboardContent)
    if (resultArray[1] == "_result_video_already_in_list") {
        MsgBox(resultArray[2] . "`n`nis already in the video list.", "VD - Duplicate URL", "O Iconi T2")
        return
    }
}

/*
Tries to extract the URL from any browser element currently under the mouse cursor.
For example when the user hovers over a video thumbnail on YouTube.
*/
hotkey_extractVideoURLUnderMouseCursor() {
    url := getBrowserURLUnderMouseCursor()
    if (!checkIfStringIsAValidURL(url)) {
        MsgBox("No URL detected.", "VD - Missing URL", "O Iconi T1")
        return
    }
    ; Extracts the video meta data and checks if it is already in the video list.
    resultArray := createVideoListViewEntry(url)
    if (resultArray[1] == "_result_video_already_in_list") {
        MsgBox(resultArray[2] . "`n`nis already in the video list.", "VD - Duplicate URL", "O Iconi T2")
        return
    }
    /*
    Basically a support function for hotkey_extractVideoURLUnderMouseCursor().
    @returns [String] The URL from the browser element under the mouse cursor.
    Otherwise the returned value will be a status string indicating that no URL was found.
    */
    getBrowserURLUnderMouseCursor() {
        ; These three variables contain the matching values for each role type.
        role_Shortcut := 30
        role_Text := 42
        role_Group := 20
        ; Get the video element.
        videoElementAccOrigin := Acc.ElementFromPoint()
        try
        {
            ; Looks for the URL in the originally selected element.
            videoElement := videoElementAccOrigin.FindElement({ Role: role_Shortcut, not: { Value: "" } })
            videoURL := videoElement.Value
            ; The "/@" is located in the youtube channel link which the user might accidentally select.
            if (checkIfStringIsAValidURL(videoURL) && !InStr(videoURL, "/@")) {
                return videoURL
            }
        }
        try
        {
            ; Looks for the URL in the originally selected element.
            videoElementValue := videoElementAccOrigin.Normalize({ Role: role_Text, not: { Value: "" } })
            videoURL := videoElementValue.Value
            ; The "/@" is located in the youtube channel link which the user might accidentally select.
            if (checkIfStringIsAValidURL(videoURL) && !InStr(videoURL, "/@")) {
                return videoURL
            }
        }
        /*
        This is usually required when the user hoveres over the video thumbnail. Therefore we try to go one or two
        steps back and identify the video this way.
        */
        try {
            elementChildren := videoElementAccOrigin.Children
            ; This means the selected thumbnail element has no children.
            if (!elementChildren.Has(1)) {
                targetParentNode := videoElementAccOrigin.Parent.Parent
            }
            else {
                targetParentNode := videoElementAccOrigin.Parent
            }
            targetChildNode := targetParentNode.FindElement({ Role: role_Shortcut, State: "5242880", not: { Value: "" } })
            videoURL := targetChildNode.Value
            ; The "/@" is located in the youtube channel link which the user might accidentally select.
            if (checkIfStringIsAValidURL(videoURL) && !InStr(videoURL, "/@")) {
                return videoURL
            }
        }
        return "_result_no_url_found"
    }
}

; Hotkey support function to open the video list GUI.
hotkey_openVideoListGUI() {
    try
    {
        static flipflop := false
        if (!WinExist("ahk_id " . videoListGUI.Hwnd)) {
            videoListGUI.Show()
            flipflop := false
        }
        else if (!flipflop && WinActive("ahk_id " . videoListGUI.Hwnd)) {
            videoListGUI.Hide()
            flipflop := true
        }
        else {
            WinActivate("ahk_id " . videoListGUI.Hwnd)
        }
    }
    catch as error {
        displayErrorMessage(error)
    }
}

hotkey_terminateProgram() {
    terminateApplicationPrompt()
}

hotkey_reloadProgram() {
    reloadApplicationPrompt()
}

/*
HOTKEY FUNCTION SECTION END
-------------------------------------------------
*/

/*
DEBUG HOTKEY FUNCTION SECTION
-------------------------------------------------
*/

hotkey_debug_1() {
    MsgBox("This debug hotkey is currently not used.", "VD - WIP", "O Iconi 262144 T1")
}

hotkey_debug_2() {
    MsgBox("This debug hotkey is currently not used.", "VD - WIP", "O Iconi 262144 T1")
}

hotkey_debug_3() {
    booleanIsConnected := checkInternetConnection()
    MsgBox("[" . A_ThisFunc . "()] [INFO] Internet Connection Status: " . booleanIsConnected .
        "`nDebug hotkey 3 executed.", "VideoDownloader - [" . A_ThisFunc . "()]", "Iconi 262144")
}

hotkey_debug_4() {
    saveCurrentVideoListGUIStateToConfigFile()
    MsgBox("[" . A_ThisFunc . "()] [INFO] Debug hotkey 4 executed.",
        "VideoDownloader - [" . A_ThisFunc . "()]", "Iconi 262144 T1")
}

/*
DEBUG HOTKEY FUNCTION SECTION END
-------------------------------------------------
*/

/*
MENU FUNCTION SECTION
-------------------------------------------------
*/

; File menu items.

; Opens the config file.
menu_openConfigFile() {
    global configFileLocation

    try
    {
        if (FileExist(configFileLocation)) {
            Run(configFileLocation)
        }
        else {
            createDefaultConfigFile()
        }
    }
    catch as error {
        displayErrorMessage(error, "This error is rare.")
    }
}

; Reset the current config file to default.
menu_resetConfigFile() {
    result := MsgBox(
        "Do you really want to reset the config file?`n`nYou need to restart VideoDownloader for the changes to take effect."
        "`n`nA backup of the old file will be created.",
        "VD - Reset Config File", "YN Icon! Owner" . videoListGUI.Hwnd)
    if (result == "Yes") {
        createDefaultConfigFile()
        reloadApplicationPrompt()
    }
}

; Import another (old) config file.
menu_importConfigFile() {
    global applicationMainDirectory

    oldConfigFileLocation := fileSelectPrompt("VD - Please select a config file to import", applicationMainDirectory,
        "*.ini", videoListGUI)
    if (oldConfigFileLocation.Has(1)) {
        importOldConfigFile(oldConfigFileLocation[1])
    }
}

; Export the current config file.
menu_exportConfigFile() {
    ; We use the current time stamp to generate a unique name for the exported file.
    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    exportConfigFileDefaultLocation := A_MyDocuments . "\" . currentTime . "_VD_exported_config_file.ini"
    exportConfigFileLocation := fileSavePrompt("VD - Please select a save location for the config file",
        exportConfigFileDefaultLocation, ".ini", videoListGUI)
    if (exportConfigFileLocation != "_result_no_file_save_location_selected") {
        exportConfigFile(exportConfigFileLocation)
    }
}

; Directory menu items.

; Opens the default download directory in the explorer.
menu_openDefaultDownloadDirectory() {
    downloadDirectory := readConfigFile("DEFAULT_DOWNLOAD_DIRECTORY")
    openDirectoryInExplorer(downloadDirectory)
}

; Opens the folder which contains the files from the latest download.
menu_openLatestDownloadDirectory() {
    global currentYTDLPActionObject

    if (DirExist(currentYTDLPActionObject.latestDownloadDirectory)) {
        openDirectoryInExplorer(currentYTDLPActionObject.latestDownloadDirectory)
    }
    else {
        MsgBox("Please download at least one file.", "VD - No Recent Download", "O Iconi T3 Owner" . videoListGUI.Hwnd)
    }
}

; Opens the default temp directory in the explorer.
menu_openDefaultTempDirectory() {
    tempDirectory := readConfigFile("TEMP_DIRECTORY")
    openDirectoryInExplorer(tempDirectory)
}

; Opens the default download temp directory in the explorer.
menu_openDefaultDownloadTempDirectory() {
    downloadTempDirectory := readConfigFile("TEMP_DOWNLOAD_DIRECTORY")
    openDirectoryInExplorer(downloadTempDirectory)
}

; Opens the application working directory in the explorer.
menu_openApplicationWorkingDirectory() {
    global applicationMainDirectory

    openDirectoryInExplorer(applicationMainDirectory)
}

; Actions menu items.

; Restart the program.
menu_restartApplication() {
    reloadApplicationPrompt()
}

; Exit the program.
menu_exitApplication() {
    ; Warning message when there is an active download running at the moment.
    if (currentYTDLPActionObject.booleanDownloadIsRunning) {
        result := MsgBox(
            "There is an active download running right now.`n`nDo you want to close VideoDownloader anyway?",
            "VD - Confirm Exit", "YN Icon! Owner" . videoListGUI.Hwnd)
    }
    ; This means there are no videos in the list view element.
    else if (videoListViewContentMap.Has("*****No videos added yet.*****")) {
        exitApplicationWithNotification()
    }
    ; Warning message when there are still videos in the list view element.
    else if (videoListViewContentMap.Count == 1) {
        result := MsgBox(
            "There is still one video in the video list.`n`nDo you want to close VideoDownloader anyway?",
            "VD - Confirm Exit", "YN Icon? Owner" . videoListGUI.Hwnd)
    }
    else if (videoListViewContentMap.Count > 1) {
        result := MsgBox(
            "There are still " . videoListViewContentMap.Count . " videos in the video list."
            "`n`nDo you want to close VideoDownloader anyway?", "VD - Confirm Exit",
            "YN Icon? Owner" . videoListGUI.Hwnd)
    }
    ; This means the user wants to close the application anyway.
    if (result == "Yes") {
        exitApplicationWithNotification()
    }
}

menu_openSetupGUI() {
    updateDependencyCheckboxes()
    updateSetupButton()
    if (!WinExist("ahk_id " . setupGUI.Hwnd)) {
        setupGUIStartAndCompleteSetupButton.Opt("-Disabled")
        setupGUIStatusBar.SetText("You may change the used executables now")
    }
    showGUIRelativeToOtherGUI(videoListGUI, setupGUI, "MiddleCenter", "AutoSize")
}

menu_updateDependencies() {
    result := MsgBox("All existing dependencies will be overwritten with the latest version.`n`nContinue?",
        "VD - Update Dependencies", "YN Iconi Owner" . videoListGUI.Hwnd)
    if (result != "Yes") {
        return
    }
    showGUIRelativeToOtherGUI(videoListGUI, setupGUI, "MiddleCenter", "AutoSize")
    deleteAllDependencyFiles()
    updateDependencyCheckboxes()
    updateSetupButton()
    setupGUISetupProgressBar.Value := 0
    handleSetupGUI_setupGUIStartAndCompleteSetupButton_onClick_1(setupGUIStartAndCompleteSetupButton, "")
}

; Open GUI items.

; Opens the settings GUI.
menu_openSettingsGUI() {
    /*
    Selects another tab element before returning to the original element
    to avoid an issue with "ghost" control elements from other tabs appearing in the current tab.
    */
    currentTabNumber := settingsGUITabs.Value
    maxTabNumber := 3
    selectTabNumber := (maxTabNumber - currentTabNumber) ? (maxTabNumber - currentTabNumber) : 1
    settingsGUITabs.Choose(selectTabNumber)
    ; Switches back to the original tab.
    settingsGUITabs.Choose(currentTabNumber)
    showGUIRelativeToOtherGUI(videoListGUI, settingsGUI, "MiddleCenter", "AutoSize")
}

; Opens the help GUI.
menu_openHelpGUI() {
    showGUIRelativeToOtherGUI(videoListGUI, helpGUI, "MiddleCenter", "AutoSize")
}

/*
MENU FUNCTION SECTION END
-------------------------------------------------
*/
