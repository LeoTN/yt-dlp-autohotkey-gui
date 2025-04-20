#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

/*
Allows the DELETE key to have the same function as clicking the remove video from list button.
This is done to allow the user to delete videos from the list by pressing the DELETE key.
It only works while the video list GUI is the active window.
*/
#HotIf (IsSet(videoListGUI) && WinExist("ahk_id " . videoListGUI.Hwnd) && WinActive("ahk_id " . videoListGUI.Hwnd))
Delete:: {
    handleVideoListGUI_removeVideoFromListButton_onClick("", "")
}
#HotIf

/*
Allows the ENTER key to function the same way as the add video to list button.
This makes adding a video URL more convenient as the user can simply press enter while focused on the URL input field.
Only works while the URL input field or the playlist range input field is focused.
*/
#HotIf (IsSet(videoListGUI) && WinExist("ahk_id " . videoListGUI.Hwnd) &&
((ControlGetFocus("ahk_id " . videoListGUI.Hwnd) == addVideoURLInputEdit.Hwnd ||
ControlGetFocus("ahk_id " . videoListGUI.Hwnd) == addVideoSpecifyPlaylistRangeInputEdit.Hwnd)))
Enter:: {
    handleVideoListGUI_addVideoToListButton_onClick("", "")
}
#HotIf

videoListGUI_onInit() {
    ; This object will be used to share data between different functions about currently ongoing yt-dlp processes.
    global currentYTDLPActionObject := Object()

    ; Download related variables.
    currentYTDLPActionObject.booleanDownloadIsRunning := false
    currentYTDLPActionObject.booleanCancelOneVideoDownload := false
    currentYTDLPActionObject.booleanCancelCompleteDownload := false
    currentYTDLPActionObject.currentlyDownloadedVideoTitle := ""
    currentYTDLPActionObject.alreadyDownloadedVideoAmount := 0
    currentYTDLPActionObject.completeVideoAmount := 0
    currentYTDLPActionObject.canceledDownloadVideoAmount := 0
    currentYTDLPActionObject.remainingVideos := 0
    currentYTDLPActionObject.downloadProcessYTDLPPID := 0
    currentYTDLPActionObject.latestDownloadDirectory := "_no_latest_directory_now"
    createVideoListGUI()
    importConfigFileValuesIntoVideoListGUI()
    if (readConfigFile("SHOW_VIDEO_LIST_GUI_ON_LAUNCH")) {
        hotkey_openVideoListGUI()
    }
}

createVideoListGUI() {
    global
    videoListGUI := Gui("+OwnDialogs", "VD - Video List")

    /*
    ********************************************************************************************************************
    This section creates all the GUI control elements and event handlers.
    ********************************************************************************************************************
    */
    ; Controlls that display the currently selected video.
    currentlySelectedVideoGroupBox := videoListGUI.Add("GroupBox", "w300 h390", "Currently Selected Video")
    videoTitleText := videoListGUI.Add("Text", "xp+10 yp+20 w280 R1 -Wrap", "Video Title")
    videoUploaderText := videoListGUI.Add("Text", "yp+20 w280 R1 -Wrap", "Uploader")
    videoDurationText := videoListGUI.Add("Text", "yp+20 w280 R1 -Wrap", "Duration")
    videoThumbnailImage := videoListGUI.Add("Picture", "w280 h157.5 yp+20 +AltSubmit", GUIBackgroundImageLocation)
    ; Controls that change the download settings for the video.
    videoDesiredFormatText := videoListGUI.Add("Text", "yp+172.5", "Desired Format")
    videoDesiredFormatDDL := videoListGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    videoDesiredSubtitleText := videoListGUI.Add("Text", "yp+30", "Desired Subtitle")
    videoDesiredSubtitleDDL := videoListGUI.Add("DropDownList", "w280 yp+20 Choose1", ["None"])
    videoAdvancedDownloadSettingsButton := videoListGUI.Add("Button", "w280 yp+30", "Advanced Download Settings")
    ; Video list controls.
    videoListSearchBarText := videoListGUI.Add("Text", "xm+310 ym", "Search the Video List")
    videoListSearchBarInputEdit := videoListGUI.Add("Edit", "yp+20 w300", "")
    videoListSearchBarInputClearButton := videoListGUI.Add("Button", "xp+305 yp+1 w20 h20", "X")
    videoListView := videoListGUI.Add("ListView", "xp-305 yp+29 w600  R20 +Grid", ["Title", "Uploader", "Duration"])
    ; Controls that belong to the video list.
    manageVideoListGroupBox := videoListGUI.Add("GroupBox", "w600 xm ym+400 h185", "Manage Video List")
    addVideoURLInputEdit := videoListGUI.Add("Edit", "xp+10 yp+20 w555 R1 -WantReturn")
    addVideoURLInputClearButton := videoListGUI.Add("Button", "xp+560 yp+1 w20 h20", "X")
    ; Add URL elements.
    addVideoToListButton := videoListGUI.Add("Button", "xp-560 yp+29 w200", "Add Video(s) to List")
    addVideoURLIsAPlaylistCheckbox := videoListGUI.Add("CheckBox", "xp+10 yp+30", "Add videos from a playlist")
    addVideoURLUsePlaylistRangeCheckbox := videoListGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only add videos in a specific range")
    addVideoSpecifyPlaylistRangeText := videoListGUI.Add("Text", "yp+20 w180", "Index Range")
    addVideoSpecifyPlaylistRangeInputEdit := videoListGUI.Add("Edit", "yp+20 w100 +Disabled", "1")
    ; Remove video elements.
    removeVideoFromListButton := videoListGUI.Add("Button", "xp+200 yp-90 w200", "Remove Video(s) from List")
    removeVideoConfirmDeletionCheckbox := videoListGUI.Add("CheckBox", "xp+10 yp+30",
        "Confirm deletion of selected videos")
    removeVideoConfirmOnlyWhenMultipleSelectedCheckbox := videoListGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only multiple videos")
    ; Import and export elements.
    importVideoListButton := videoListGUI.Add("Button", "xp+200 yp-50 w75", "Import")
    exportVideoListButton := videoListGUI.Add("Button", "yp xp+85 w75", "Export")
    exportOnlyValidURLsCheckbox := videoListGUI.Add("CheckBox", "xp-75 yp+30", "Only consider valid URLs")
    autoExportVideoListCheckbox := videoListGUI.Add("CheckBox", "yp+20 Checked", "Auto export downloads")
    ; Controls that are relevant for downloading the videos in the video list.
    downloadVideoGroupBox := videoListGUI.Add("GroupBox", "w300 xm+610 ym+400 h185", "Download")
    downloadStartButton := videoListGUI.Add("Button", "xp+10 yp+20 w135", "Start Download")
    downloadCancelButton := videoListGUI.Add("Button", "xp+145 yp w135", "Cancel Download")
    downloadRemoveVideosAfterDownloadCheckbox := videoListGUI.Add("Checkbox", "xp-135 yp+30 Checked",
        "Automatically remove downloaded videos")
    downloadTerminateAfterDownloadCheckbox := videoListGUI.Add("Checkbox", "yp+20",
        "Terminate after download")
    downloadSelectDownloadDirectoryText := videoListGUI.Add("Text", "xp-10 yp+20", "Download Directory")
    downloadSelectDownloadDirectoryInputEdit := videoListGUI.Add("Edit", "yp+20 w255 R1 -WantReturn +ReadOnly",
        "default")
    downloadSelectDownloadDirectoryButton := videoListGUI.Add("Button", "xp+260 yp+1 w20 h20", "...")
    downloadProgressText := videoListGUI.Add("Text", "xp-260 yp+29 w280", "Downloaded (0 / 0)")
    downloadProgressBar := videoListGUI.Add("Progress", "yp+20 w280")
    ; Status bar
    videoListGUIStatusBar := videoListGUI.Add("StatusBar", , "Add a video URL to start")
    videoListGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    videoListGUIStatusBar.loadingAnimationIsPlaying := false
    videoListGUIStatusBar.loadingAnimationCurrentStatusBarText := ""

    ; Adds the event handlers for the video list GUI.
    videoDesiredFormatDDL.OnEvent("Change", handleVideoListGUI_allCurrentlySelectedVideoElements_onChange)
    videoDesiredSubtitleDDL.OnEvent("Change", handleVideoListGUI_allCurrentlySelectedVideoElements_onChange)
    videoAdvancedDownloadSettingsButton.OnEvent("Click",
        handleVideoListGUI_videoAdvancedDownloadSettingsButton_onClick)
    ; Video list controls.
    videoListSearchBarInputEdit.OnEvent("Change", handleVideoListGUI_videoListSearchBarInputEdit_onChange)
    videoListSearchBarInputClearButton.OnEvent("Click", handleVideoListGUI_videoListSearchBarInputClearButton_onClick)
    ; Add URL elements.
    addVideoURLInputClearButton.OnEvent("Click", handleVideoListGUI_addVideoURLInputClearButton_onClick)
    addVideoToListButton.OnEvent("Click", handleVideoListGUI_addVideoToListButton_onClick)
    addVideoURLIsAPlaylistCheckbox.OnEvent("Click", handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick)
    addVideoURLUsePlaylistRangeCheckbox.OnEvent("Click",
        handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick)
    addVideoSpecifyPlaylistRangeInputEdit.OnEvent("Change",
        handleSettingsGUI_addVideoSpecifyPlaylistRangeInputEdit_onChange)
    ; Remove video elements.
    removeVideoFromListButton.OnEvent("Click", handleVideoListGUI_removeVideoFromListButton_onClick)
    removeVideoConfirmDeletionCheckbox.OnEvent("Click", handleVideoListGUI_removeVideoConfirmDeletionCheckbox_onClick)
    ; Import and export elements.
    importVideoListButton.OnEvent("Click", handleVideoListGUI_importVideoListButton_onClick)
    exportVideoListButton.OnEvent("Click", handleVideoListGUI_exportVideoListButton_onClick)
    ; Video list controls.
    videoListView.OnEvent("ItemSelect", handleVideoListGUI_videoListView_onItemSelect)
    ; Controls that are relevant for downloading the videos in the video list.
    downloadStartButton.OnEvent("Click", handleVideoListGUI_downloadStartButton_onClick)
    downloadCancelButton.OnEvent("Click", handleVideoListGUI_downloadCancelButton_onClick)
    downloadSelectDownloadDirectoryButton.OnEvent("Click",
        handleVideoListGUI_downloadSelectDownloadDirectoryButton_onClick)
    ; Enables the help button in the MsgBox which informs the user once they entered an incorrect playlist range index.
    OnMessage(0x0053, handleVideoListGUI_invalidPlaylistRangeIndexMsgBoxHelpButton)

    /*
    ********************************************************************************************************************
    This section creates all GUI element tooltips.
    ********************************************************************************************************************
    */
    ; Controls that change the download settings for the video.
    videoDesiredFormatDDL.ToolTip :=
        "Select a preferred download format. If available, the selected format will be downloaded directly."
    videoDesiredFormatDDL.ToolTip .=
        "`nOtherwise a conversion with FFmpeg might be required which can take some time."
    videoDesiredSubtitleDDL.ToolTip :=
        "More available subtitle options might be added in the future."
    videoAdvancedDownloadSettingsButton.ToolTip := ""
    ; Video list controls.
    videoListSearchBarInputEdit.ToolTip :=
        "You can also search a video with it's URL."
    videoListSearchBarInputClearButton.ToolTip := ""
    ; Controls that belong to the video list.
    addVideoURLInputEdit.ToolTip := ""
    addVideoURLInputClearButton.ToolTip := ""
    ; Add URL elements.
    addVideoToListButton.ToolTip := ""
    addVideoURLIsAPlaylistCheckbox.ToolTip :=
        "If a URL contains a reference or is itself a link to a playlist,"
    addVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nonly the video specified in the URL or the very first video of the playlist will be added to the list."
    addVideoURLIsAPlaylistCheckbox.ToolTip .=
        "`nEnable this option to instead download the complete playlist by default."
    addVideoURLUsePlaylistRangeCheckbox.ToolTip :=
        "Allows for a fine grained selection of videos from the playlist. See the help section for more information."
    addVideoSpecifyPlaylistRangeInputEdit.ToolTip :=
        "Enter the index range to select the videos from the playlist.`nMore information can be found in the help section."
    ; Remove video elements.
    removeVideoFromListButton.ToolTip := ""
    removeVideoConfirmDeletionCheckbox.ToolTip :=
        "Shows a prompt to confirm the removal of one or more videos from the list."
    removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.ToolTip :=
        "If enabled, will only prompt to confirm the removal of multiple videos at once."
    ; Import and export elements.
    importVideoListButton.ToolTip :=
        "Import a text file with video URLs. Each line must only contain one URL."
    exportVideoListButton.ToolTip :=
        "Export the URLs of all (selected) videos into a file."
    exportOnlyValidURLsCheckbox.ToolTip :=
        "Only video URLs that have been successfully extracted will be exported."
    autoExportVideoListCheckbox.ToolTip :=
        "Automatically exports the downloaded video URLs into a file."
    ; Controls that are relevant for downloading the videos in the video list.
    downloadStartButton.ToolTip :=
        "Start the download of all (selected) videos in the list."
    downloadCancelButton.ToolTip := ""
    downloadRemoveVideosAfterDownloadCheckbox.ToolTip :=
        "Removes the video from the list after downloading and processing it."
    downloadTerminateAfterDownloadCheckbox.ToolTip :=
        "Closes VideoDownloader after downloading and processing all (selected) videos."
    downloadSelectDownloadDirectoryInputEdit.ToolTip :=
        "Select a directory for the downloaded files."
    downloadSelectDownloadDirectoryInputEdit.ToolTip .=
        "`nOtherwise the default directory specified in the settings is used."
    downloadSelectDownloadDirectoryButton.ToolTip := ""

    /*
    ********************************************************************************************************************
    This section creates all the GUI menus.
    ********************************************************************************************************************
    */
    ; File menu items.
    configFileActionMenu := Menu()
    configFileActionMenu.Add("Open", (*) => menu_openConfigFile())
    configFileActionMenu.SetIcon("Open", iconFileLocation, 10) ; ICON_DLL_USED_HERE
    configFileActionMenu.Add("Reset", (*) => menu_resetConfigFile())
    configFileActionMenu.SetIcon("Reset", iconFileLocation, 5) ; ICON_DLL_USED_HERE
    configFileActionMenu.Add("Import", (*) => menu_importConfigFile())
    configFileActionMenu.SetIcon("Import", iconFileLocation, 2) ; ICON_DLL_USED_HERE
    configFileActionMenu.Add("Export", (*) => menu_exportConfigFile())
    configFileActionMenu.SetIcon("Export", iconFileLocation, 17) ; ICON_DLL_USED_HERE

    fileSelectionMenu := Menu()
    fileSelectionMenu.Add("Config File", configFileActionMenu)
    fileSelectionMenu.SetIcon("Config File", iconFileLocation, 16) ; ICON_DLL_USED_HERE

    ; Directory menu items.
    directorySelectionMenu := Menu()
    directorySelectionMenu.Add("Default Download", (*) => menu_openDefaultDownloadDirectory())
    directorySelectionMenu.SetIcon("Default Download", iconFileLocation, 11) ; ICON_DLL_USED_HERE
    directorySelectionMenu.Add("Latest Download", (*) => menu_openLatestDownloadDirectory())
    directorySelectionMenu.SetIcon("Latest Download", iconFileLocation, 13) ; ICON_DLL_USED_HERE
    directorySelectionMenu.Add()
    directorySelectionMenu.Add("Temp", (*) => menu_openDefaultTempDirectory())
    directorySelectionMenu.SetIcon("Temp", iconFileLocation, 7) ; ICON_DLL_USED_HERE
    directorySelectionMenu.Add("Download Temp", (*) => menu_openDefaultDownloadTempDirectory())
    directorySelectionMenu.SetIcon("Download Temp", iconFileLocation, 4) ; ICON_DLL_USED_HERE
    directorySelectionMenu.Add("Working Directory", (*) => menu_openApplicationWorkingDirectory())
    directorySelectionMenu.SetIcon("Working Directory", iconFileLocation, 3) ; ICON_DLL_USED_HERE

    ; Actions menu items.
    applicationActionsMenu := Menu()
    applicationActionsMenu.Add("Restart Application", (*) => menu_restartApplication())
    applicationActionsMenu.SetIcon("Restart Application", iconFileLocation, 8) ; ICON_DLL_USED_HERE
    applicationActionsMenu.Add("Exit Application", (*) => menu_exitApplication())
    applicationActionsMenu.SetIcon("Exit Application", iconFileLocation, 15) ; ICON_DLL_USED_HERE

    allMenus := MenuBar()
    allMenus.Add("&File", fileSelectionMenu)
    allMenus.SetIcon("&File", iconFileLocation, 19) ; ICON_DLL_USED_HERE
    allMenus.Add("&Directory", directorySelectionMenu)
    allMenus.SetIcon("&Directory", iconFileLocation, 18) ; ICON_DLL_USED_HERE
    allMenus.Add("&Actions", applicationActionsMenu)
    allMenus.SetIcon("&Actions", iconFileLocation, 12) ; ICON_DLL_USED_HERE
    allMenus.Add("&Settings", (*) => menu_openSettingsGUI())
    allMenus.SetIcon("&Settings", iconFileLocation, 6) ; ICON_DLL_USED_HERE
    allMenus.Add("&Help", (*) => menu_openHelpGUI())
    allMenus.SetIcon("&Help", iconFileLocation, 14) ; ICON_DLL_USED_HERE
    videoListGUI.MenuBar := allMenus

    ; Add a temporary video list view element. When removing it, there will be the no entries entry.
    tmpVideoMetaDataObject := Object()
    tmpVideoMetaDataObject.VIDEO_TITLE := ""
    tmpVideoMetaDataObject.VIDEO_ID := ""
    tmpVideoMetaDataObject.VIDEO_URL := ""
    tmpVideoMetaDataObject.VIDEO_UPLOADER := ""
    tmpVideoMetaDataObject.VIDEO_UPLOADER_URL := ""
    tmpVideoMetaDataObject.VIDEO_DURATION_STRING := ""
    tmpVideoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := ""
    tmpEntry := VideoListViewEntry(tmpVideoMetaDataObject, false)
    tmpEntry.removeEntryFromVideoListViewContentMap()

    ; Makes the settings and help GUI the child window of the video list GUI.
    settingsGUI.Opt("+Owner" . videoListGUI.Hwnd)
    helpGUI.Opt("+Owner" . videoListGUI.Hwnd)
}

handleVideoListGUI_allCurrentlySelectedVideoElements_onChange(*) {
    global currentlySelectedVideoListViewEntry
    ; Sets the objects desired format and subtitle array currently selected index to the selected index of the drop down list.
    currentlySelectedVideoListViewEntry.desiredFormatArrayCurrentlySelectedIndex := videoDesiredFormatDDL.Value
    currentlySelectedVideoListViewEntry.desiredSubtitleArrayCurrentlySelectedIndex := videoDesiredSubtitleDDL.Value
}

handleVideoListGUI_videoAdvancedDownloadSettingsButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleVideoListGUI_videoListSearchBarInputEdit_onChange(pEdit, pInfo) {
    global videoListViewContentMap

    searchString := pEdit.Value
    videoListView.Delete()
    ; Shows all data when the search bar is empty.
    if (searchString == "") {
        for (key, videoListEntry in videoListViewContentMap) {
            addVideoListViewEntryToListView(videoListEntry)
            ; Removes the no results entry.
            if (IsSet(noEntriesVideoListEntry) && IsObject(noEntriesVideoListEntry) &&
            videoListViewContentMap.Has(noEntriesVideoListEntry.identifierString)) {
                noEntriesVideoListEntry.removeEntryFromVideoListViewContentMap()
            }
        }
        return
    }
    ; Calls the search function to search in all entries.
    resultArray := searchInVideoListView(searchString)
    for (resultEntry in resultArray) {
        addVideoListViewEntryToListView(resultEntry)
    }
    else {
        ; This entry is displayed when no results are found.
        tmpVideoMetaDataObject := Object()
        tmpVideoMetaDataObject.VIDEO_TITLE := "*****"
        tmpVideoMetaDataObject.VIDEO_ID := ""
        tmpVideoMetaDataObject.VIDEO_URL := "_internal_entry_no_results_found"
        tmpVideoMetaDataObject.VIDEO_UPLOADER := "No results found."
        tmpVideoMetaDataObject.VIDEO_UPLOADER_URL := ""
        tmpVideoMetaDataObject.VIDEO_DURATION_STRING := "*****"
        tmpVideoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := GUIBackgroundImageLocation
        ; Create the entry using the temporary video meta data object.
        static noEntriesVideoListEntry := VideoListViewEntry(tmpVideoMetaDataObject, false)
        noEntriesVideoListEntry.desiredFormatArray := ["None"]
        noEntriesVideoListEntry.desiredSubtitleArray := ["None"]
        ; Manually update the video list view element to avoid showing all entries in the videoListViewContentMap.
        addVideoListViewEntryToListView(noEntriesVideoListEntry)
        updateCurrentlySelectedVideo(noEntriesVideoListEntry)
    }
}

handleVideoListGUI_videoListSearchBarInputClearButton_onClick(pButton, pInfo) {
    videoListSearchBarInputEdit.Value := ""
    ; Trigger the onChange function manually, as changing the value above does not trigger the change event.
    handleVideoListGUI_videoListSearchBarInputEdit_onChange(videoListSearchBarInputEdit, pInfo)
}

handleVideoListGUI_addVideoURLInputClearButton_onClick(pButton, pInfo) {
    addVideoURLInputEdit.Value := ""
}

handleVideoListGUI_addVideoToListButton_onClick(pButton, pInfo) {
    videoURL := addVideoURLInputEdit.Value
    ; Avoids the invalid URL MsgBox when the edit is empty.
    if (videoURL == "") {
        return
    }
    ; Checks if the entered string is a valid URL.
    if (!checkIfStringIsAValidURL(videoURL)) {
        MsgBox("Please enter a valid URL.", "VD - Invalid URL", "O Icon! 262144 T1")
        return
    }
    ; Only relevant when downloading specific parts of a playlist.
    if (addVideoURLUsePlaylistRangeCheckbox.Value &&
        !checkIfStringIsValidPlaylistIndexRange(addVideoSpecifyPlaylistRangeInputEdit.Value)) {
        MsgBox("The provided playlist range index is invalid!", "VD - Invalid Playlist Range Index",
            "O Icon! 16384 Owner" . videoListGUI.Hwnd)
        return
    }
    ; This means the provided URL contains a reference to a playlist.
    if (addVideoURLIsAPlaylistCheckbox.Value) {
        playlistRangeIndex := addVideoSpecifyPlaylistRangeInputEdit.Value
        ; This means the user wants to download only parts of the playlist.
        if (addVideoURLUsePlaylistRangeCheckbox.Value && playlistRangeIndex != "0") {
            playlistVideoMetaDataObjectArray := extractVideoMetaDataPlaylist(videoURL, playlistRangeIndex)
        }
        ; This means the user wants to download the whole playlist.
        else {
            playlistVideoMetaDataObjectArray := extractVideoMetaDataPlaylist(videoURL)
        }
        ; This happens when the playlist could not be found.
        if (playlistVideoMetaDataObjectArray.Length == 0) {
            tmpVideoMetaDataObject := Object()
            tmpVideoMetaDataObject.VIDEO_TITLE := "playlist_not_found: " . videoURL
            tmpVideoMetaDataObject.VIDEO_ID := ""
            tmpVideoMetaDataObject.VIDEO_URL := "playlist_not_found: " . videoURL
            tmpVideoMetaDataObject.VIDEO_UPLOADER := "Not found"
            tmpVideoMetaDataObject.VIDEO_UPLOADER_URL := ""
            tmpVideoMetaDataObject.VIDEO_DURATION_STRING := "Not found"
            tmpVideoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := GUIBackgroundImageLocation
            newVideoEntry := VideoListViewEntry(tmpVideoMetaDataObject)
        }
        else {
            ; Creates a new video list view entry object for each video.
            for (index, videoMetaDataObject in playlistVideoMetaDataObjectArray) {
                /*
                Create a new video entry but do not update the video list view element.
                When updating the element for each object, there is a flickering effect which is unpleasant to look at.
                */
                newVideoEntry := VideoListViewEntry(videoMetaDataObject, false)
            }
        }
        newVideoEntry.updateVideoListViewElement()
    }
    else {
        newVideoEntry := VideoListViewEntry(videoURL)
        updateCurrentlySelectedVideo(newVideoEntry)
    }
}

handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick(pCheckbox, pInfo) {
    ; Enable the checkbox below.
    if (pCheckbox.Value) {
        addVideoURLUsePlaylistRangeCheckbox.Opt("-Disabled")
    }
    ; Disable the checkbox below and uncheck it.
    else {
        addVideoURLUsePlaylistRangeCheckbox.Opt("+Disabled")
        addVideoURLUsePlaylistRangeCheckbox.Value := false
        handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick(addVideoURLUsePlaylistRangeCheckbox, pInfo)
    }
}

handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick(pCheckbox, pInfo) {
    ; Enable the edit below.
    if (pCheckbox.Value) {
        addVideoSpecifyPlaylistRangeInputEdit.Opt("-Disabled")
    }
    else {
        addVideoSpecifyPlaylistRangeInputEdit.Opt("+Disabled")
    }
}

handleSettingsGUI_addVideoSpecifyPlaylistRangeInputEdit_onChange(pEdit, pInfo) {
    ; Displays an inidicator in the text to show the validity status.
    if (checkIfStringIsValidPlaylistIndexRange(pEdit.Value)) {
        addVideoSpecifyPlaylistRangeText.Text := "Index Range (valid)"
    }
    else {
        addVideoSpecifyPlaylistRangeText.Text := "Index Range (invalid)"
    }
}

handleVideoListGUI_removeVideoFromListButton_onClick(pButton, pInfo) {
    ; This map contains all video list view elements currently selected by the user.
    selectedVideoListViewElementsMap := getSelectedVideoListViewElements()

    ; Prompts the user to confirm the deletion of one video element.
    if (selectedVideoListViewElementsMap.Count == 1 &&
        removeVideoConfirmDeletionCheckbox.Value && !removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value) {
        result := MsgBox("Do you really want to delete this video?", "VD - Confirm Deletion",
            "YN Icon? 262144 T15")
        if (result != "Yes") {
            return
        }
    }
    ; Prompts the user to confirm the deletion of multiple video elements.
    else if (selectedVideoListViewElementsMap.Count > 1 &&
        (removeVideoConfirmDeletionCheckbox.Value || removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value)) {
        result := MsgBox("Do you really want to delete " . selectedVideoListViewElementsMap.Count . " videos?",
            "VD - Confirm Deletion", "YN Icon? 262144 T15")
        if (result != "Yes") {
            return
        }
    }
    for (key, videoListEntry in selectedVideoListViewElementsMap) {
        videoListEntry.removeEntryFromVideoListViewContentMap()
    }
}

handleVideoListGUI_removeVideoConfirmDeletionCheckbox_onClick(pCheckbox, pInfo) {
    ; Enable the checkbox below.
    if (pCheckbox.Value) {
        removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Opt("-Disabled")
    }
    ; Disable the checkbox below and uncheck it.
    else {
        removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Opt("+Disabled")
        removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value := false
    }
}

handleVideoListGUI_importVideoListButton_onClick(pButton, pInfo) {
    importFileDefaultDirectory := A_MyDocuments
    importFileLocation := fileSelectPrompt("VD - Please select a file to import", importFileDefaultDirectory, "*.txt")
    ; This usually happens, when the user cancels the selection.
    if (importFileLocation == "_result_no_file_selected") {
        return
    }
    ; Imports all URLs or only valid ones, depending on the value of the checkbox.
    importVideoListViewElements(importFileLocation, exportOnlyValidURLsCheckbox.Value)
}

handleVideoListGUI_exportVideoListButton_onClick(pButton, pInfo) {
    global videoListViewContentMap

    ; This means there are no videos in the list view element.
    if (videoListViewContentMap.Has("*****No videos added yet.*****")) {
        return
    }
    ; Checks if the user has selected a few videos.
    selectedVideoListViewElementsMap := getSelectedVideoListViewElements()
    ; Only export the selected videos.
    if (selectedVideoListViewElementsMap.Count > 0) {
        ; Exports all URLs or only valid ones, depending on the value of the checkbox.
        exportVideoListViewElements(selectedVideoListViewElementsMap, , exportOnlyValidURLsCheckbox.Value)
    }
    ; Export all videos.
    else {
        ; Exports all URLs or only valid ones, depending on the value of the checkbox.
        exportVideoListViewElements(videoListViewContentMap, , exportOnlyValidURLsCheckbox.Value)
    }
}

handleVideoListGUI_videoListView_onItemSelect(pListView, pSelectedElementIndex, pBooleanElementWasSelected) {
    /*
    The value pBooleanElementWasSelected is true if the element was selected and false if it was deselected.
    We need to ignore the event if the element was deselected.
    */
    if (!pBooleanElementWasSelected) {
        return
    }
    videoTitle := pListView.GetText(pSelectedElementIndex, 1)
    videoUploader := pListView.GetText(pSelectedElementIndex, 2)
    videoDurationString := pListView.GetText(pSelectedElementIndex, 3)
    ; Build the identifier string with the values from the video list view element.
    entryIdentifierString := videoTitle . videoUploader . videoDurationString
    if (!videoListViewContentMap.Has(entryIdentifierString)) {
        return
    }
    ; Find the matching video list view entry object with that identifier string.
    currentlySelectedVideoListViewEntry := videoListViewContentMap.Get(entryIdentifierString)
    updateCurrentlySelectedVideo(currentlySelectedVideoListViewEntry)
}

handleVideoListGUI_downloadStartButton_onClick(pButton, pInfo) {
    global videoListViewContentMap
    global videoListViewContentMap
    global currentYTDLPActionObject

    ; This ensures that there can only be one download process at the time.
    if (!currentYTDLPActionObject.booleanDownloadIsRunning) {
        currentYTDLPActionObject.booleanDownloadIsRunning := true
        currentYTDLPActionObject.booleanCancelOneVideoDownload := false
        currentYTDLPActionObject.booleanCancelCompleteDownload := false
    }
    else {
        MsgBox("There is already another download in progress.", "VD - Other Download Running", "O Iconi 262144 T1")
        return
    }

    ; Checks if the user has selected a few videos.
    selectedVideoListViewElementsMap := getSelectedVideoListViewElements()
    ; Only download the selected videos.
    if (selectedVideoListViewElementsMap.Count > 0) {
        localCopyVideoListViewContentMap := selectedVideoListViewElementsMap
    }
    ; Download all videos.
    else {
        /*
        Create a local copy of the video list view content map to avoid download issues
        when the original map changes during the download.
        */
        localCopyVideoListViewContentMap := videoListViewContentMap.Clone()
    }

    ; A copy of the map is required as deleting keys while parsing through the same map causes issues with the for loop.
    localCopyVideoListViewContentMapCopy := localCopyVideoListViewContentMap.Clone()
    ; Filter out the invalid URLs.
    for (key, videoListEntry in localCopyVideoListViewContentMapCopy) {
        videoURL := videoListEntry.videoURL
        ; Checks if the URL is invalid.
        if (!checkIfStringIsAValidURL(videoUrl)) {
            localCopyVideoListViewContentMap.Delete(key)
        }
        ; Checks if the video was not found by yt-dlp.
        else if (InStr(videoListEntry.videoTitle, "video_not_found: ")) {
            localCopyVideoListViewContentMap.Delete(key)
        }
    }

    ; We use the current time stamp to generate a unique name for the download folder.
    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    defaultDownloadDirectory := readConfigFile("DEFAULT_DOWNLOAD_DIRECTORY")
    currentDownloadDirectory := defaultDownloadDirectory . "\" . currentTime
    alternativeDownloadDirectory := downloadSelectDownloadDirectoryInputEdit.Value
    ; Use the alternative download directory if it exists.
    if (DirExist(alternativeDownloadDirectory)) {
        targetDownloadDirectory := alternativeDownloadDirectory
    }
    else {
        targetDownloadDirectory := currentDownloadDirectory
    }

    ; Fill the currentYTDLPActionObject with data which can be used to cancel the download.
    currentYTDLPActionObject.alreadyDownloadedVideoAmount := 0
    currentYTDLPActionObject.completeVideoAmount := localCopyVideoListViewContentMap.Count
    currentYTDLPActionObject.canceledDownloadVideoAmount := 0

    ; This map will be used to automatically export the downloaded URLs into the download folder.
    actuallyDownloadedVideoListViewElements := Map()
    ; Parse through each video and start the download process.
    for (key, videoListEntry in localCopyVideoListViewContentMap) {
        ; Calculates the remaining amount of videos which are left to be downloaded.
        currentYTDLPActionObject.remainingVideos := currentYTDLPActionObject.completeVideoAmount -
            currentYTDLPActionObject.alreadyDownloadedVideoAmount - currentYTDLPActionObject.canceledDownloadVideoAmount
        ; Fill the currentYTDLPActionObject with data which can be used to cancel the download.
        currentYTDLPActionObject.currentlyDownloadedVideoTitle := videoListEntry.videoTitle
        videoURL := videoListEntry.videoURL
        downloadVideoListViewEntry(videoListEntry, targetDownloadDirectory)
        if (currentYTDLPActionObject.booleanCancelOneVideoDownload) {
            currentYTDLPActionObject.canceledDownloadVideoAmount++
            currentYTDLPActionObject.booleanCancelOneVideoDownload := false
            continue
        }
        if (currentYTDLPActionObject.booleanCancelCompleteDownload) {
            break
        }
        ; Remove the video from the video list view element.
        if (downloadRemoveVideosAfterDownloadCheckbox.Value) {
            videoListEntry.removeEntryFromVideoListViewContentMap()
        }
        actuallyDownloadedVideoListViewElements.Set(key, videoListEntry)
        currentYTDLPActionObject.alreadyDownloadedVideoAmount++
    }

    ; Automatically exports all downloaded video URLs.
    if (autoExportVideoListCheckbox.Value && actuallyDownloadedVideoListViewElements.Count > 0) {
        exportFileName := currentTime . "_VD_auto_exported_urls.txt"
        exportFileLocation := currentDownloadDirectory . "\" . exportFileName
        ; There shouldn't be any invalid URLs. Really :D But if there are any, the will be ignored.
        exportVideoListViewElements(actuallyDownloadedVideoListViewElements, exportFileLocation, true)
    }

    ; Calculates the remaining amount of videos which are left to be downloaded once again.
    currentYTDLPActionObject.remainingVideos := currentYTDLPActionObject.completeVideoAmount -
        currentYTDLPActionObject.alreadyDownloadedVideoAmount - currentYTDLPActionObject.canceledDownloadVideoAmount
    ; Updates the downloaded video progress text.
    downloadProgressText.Value := "Downloaded (" . currentYTDLPActionObject.alreadyDownloadedVideoAmount . " / " .
        currentYTDLPActionObject.completeVideoAmount . ") - [" . currentYTDLPActionObject.remainingVideos .
        "] Remaining"
    if (currentYTDLPActionObject.alreadyDownloadedVideoAmount == 1) {
        videoListGUIStatusBar.SetText("Downloaded 1 file to [" . targetDownloadDirectory . "]")
        ; Updates the latest download directory.
        currentYTDLPActionObject.latestDownloadDirectory := targetDownloadDirectory
    }
    else if (currentYTDLPActionObject.alreadyDownloadedVideoAmount > 1) {
        videoListGUIStatusBar.SetText("Downloaded " . currentYTDLPActionObject.alreadyDownloadedVideoAmount
            . " files to [" . targetDownloadDirectory . "]")
        ; Updates the latest download directory.
        currentYTDLPActionObject.latestDownloadDirectory := targetDownloadDirectory
    }
    if (downloadTerminateAfterDownloadCheckbox.Value) {
        exitApplicationWithNotification()
    }
    currentYTDLPActionObject.booleanDownloadIsRunning := false
}

handleVideoListGUI_downloadCancelButton_onClick(pButton, pInfo) {
    global currentYTDLPActionObject

    if (!currentYTDLPActionObject.booleanDownloadIsRunning) {
        return
    }
    msgText := "Would you like to cancel the current video download of"
    msgText .= "`n`n[" . currentYTDLPActionObject.currentlyDownloadedVideoTitle . "]"
    ; Ignores the cancel complete download when there is only one video in total.
    if (currentYTDLPActionObject.remainingVideos == 1) {
        msgText .= "?"
    }
    else {
        msgText .= "`n`nor the complete download of [" . currentYTDLPActionObject.remainingVideos .
            "] remaining video(s)?"
    }
    msgTitle := "VD - Cancel Download"
    msgHeadLine := "Cancel Download Process"
    msgButton1 := "Cancel Current Download"
    msgButton2 := "Abort"
    msgButton3 := "Cancel Complete Download"

    ; Ignores the cancel complete download when there is only one video in total.
    if (currentYTDLPActionObject.remainingVideos == 1) {
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, , , true, videoListGUI.Hwnd)
    }
    else {
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true,
            videoListGUI.Hwnd)
    }
    if (result == msgButton1) {
        if (ProcessExist(currentYTDLPActionObject.downloadProcessYTDLPPID)) {
            ProcessClose(currentYTDLPActionObject.downloadProcessYTDLPPID)
            ; We use recursive mode here to possibly end all sub processes (e.g. ffmpeg) of the yt-dlp sub process.
            terminateAllChildProcesses(currentYTDLPActionObject.downloadProcessYTDLPPID, "yt-dlp.exe", true)
            currentYTDLPActionObject.booleanCancelOneVideoDownload := true
        }
    }
    else if (result == msgButton3) {
        if (ProcessExist(currentYTDLPActionObject.downloadProcessYTDLPPID)) {
            ProcessClose(currentYTDLPActionObject.downloadProcessYTDLPPID)
            ; We use recursive mode here to possibly end all sub processes (e.g. ffmpeg) of the yt-dlp sub process.
            terminateAllChildProcesses(currentYTDLPActionObject.downloadProcessYTDLPPID, "yt-dlp.exe", true)
            currentYTDLPActionObject.booleanCancelCompleteDownload := true
        }
    }
}

handleVideoListGUI_downloadSelectDownloadDirectoryButton_onClick(pButton, pInfo) {
    global applicationMainDirectory

    if (downloadSelectDownloadDirectoryInputEdit.Value != "") {
        ; This will open the current directory (if one is already selected and the folder exists).
        if (DirExist(downloadSelectDownloadDirectoryInputEdit.Value)) {
            selectPath := downloadSelectDownloadDirectoryInputEdit.Value
        }
        else {
            selectPath := applicationMainDirectory
        }
    }
    else {
        selectPath := applicationMainDirectory
    }

    downloadDirectory := directorySelectPrompt("VD - Please select the download target folder", selectPath, true)
    if (downloadDirectory == "_result_no_directory_selected") {
        return
    }
    downloadSelectDownloadDirectoryInputEdit.Value := downloadDirectory
}

handleVideoListGUI_invalidPlaylistRangeIndexMsgBoxHelpButton(*) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

/*
Shows a neat little loading animation in the status bar.
This function can be called again to overwrite the currently playing animation.
@param pStatusBarText [String] The text that is displayed in the status bar while the loading animation plays.
@param pSpinnerCharArray [Array] An array containing different states an positions of an element represented with a string.
It should look as if the object is animated when parsing through the array.
*/
handleVideoListGUI_videoListGUIStatusBar_startAnimation(pStatusBarText, pSpinnerCharArray?) {
    if (!IsSet(pSpinnerCharArray)) {
        pSpinnerCharArray := [
            "[⌛         ]", "[ ⌛        ]", "[  ⌛       ]", "[   ⌛      ]", "[    ⌛     ]",
            "[     ⌛    ]", "[      ⌛   ]", "[       ⌛  ]", "[        ⌛ ]", "[         ⌛]",
            "[        ⌛ ]", "[       ⌛  ]", "[      ⌛   ]", "[     ⌛    ]", "[    ⌛     ]",
            "[   ⌛      ]", "[  ⌛       ]", "[ ⌛        ]"
        ]
    }
    /*
    If this function is called while the loading animation is playing, it will simply swap out the text
    but not start another timer. This avoids multiple timers overlapping and causing graphical issues in the status bar.
    */
    videoListGUIStatusBar.loadingAnimationCurrentStatusBarText := pStatusBarText
    if (videoListGUIStatusBar.loadingAnimationIsPlaying) {
        return
    }
    videoListGUIStatusBar.loadingAnimationIsPlaying := true
    SetTimer(step, 150)
    step() {
        ; Arrays in AHK start with the index of 1.
        static i := 1
        if (!videoListGUIStatusBar.loadingAnimationIsPlaying) {
            SetTimer(step, 0)
            return
        }
        currentChar := pSpinnerCharArray[i]
        videoListGUIStatusBar.SetText(videoListGUIStatusBar.loadingAnimationCurrentStatusBarText . " " . currentChar)
        ; Increases the index for the next time this function is called.
        i := Mod(i, pSpinnerCharArray.Length) + 1
    }
}

/*
Stops the status bar loading animation.
@param pStatusBarText [String] The text that is displayed in the status bar when the loading animation ends.
*/
handleVideoListGUI_videoListGUIStatusBar_stopAnimation(pStatusBarText) {
    videoListGUIStatusBar.loadingAnimationIsPlaying := false
    videoListGUIStatusBar.loadingAnimationCurrentStatusBarText := pStatusBarText
    videoListGUIStatusBar.SetText(pStatusBarText)
}

; Updates the checkbox values according to the config file.
importConfigFileValuesIntoVideoListGUI() {
    ; Add URL elements.
    addVideoURLIsAPlaylistCheckbox.Value := readConfigFile("ADD_VIDEO_URL_IS_A_PLAYLIST")
    addVideoURLUsePlaylistRangeCheckbox.Value := readConfigFile("ADD_VIDEO_URL_USE_PLAYLIST_RANGE")
    addVideoSpecifyPlaylistRangeInputEdit.Value := readConfigFile("ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE")
    ; Remove video elements.
    removeVideoConfirmDeletionCheckbox.Value := readConfigFile("REMOVE_VIDEO_CONFIRM_DELETION")
    removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value := readConfigFile(
        "REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED")
    ; Import and export elements.
    exportOnlyValidURLsCheckbox.Value := readConfigFile("EXPORT_ONLY_VALID_URLS")
    autoExportVideoListCheckbox.Value := readConfigFile("AUTO_EXPORT_VIDEO_LIST")
    ; Controls that are relevant for downloading the videos in the video list.
    downloadRemoveVideosAfterDownloadCheckbox.Value := readConfigFile("REMOVE_VIDEOS_AFTER_DOWNLOAD")
    downloadTerminateAfterDownloadCheckbox.Value := readConfigFile("TERMINATE_AFTER_DOWNLOAD")

    ; Enables or disables a few checkboxes according to their values.
    handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick(addVideoURLIsAPlaylistCheckbox, "")
    handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick(addVideoURLUsePlaylistRangeCheckbox, "")
    handleVideoListGUI_removeVideoConfirmDeletionCheckbox_onClick(removeVideoConfirmDeletionCheckbox, "")
}

/*
Allows to search for elements in the video list view element.
@param pSearchString [String] A string to search for.
@returns [Array] This array contains all ListView objects matching the search string.
*/
searchInVideoListView(pSearchString) {
    global videoListViewContentMap

    resultArrayCollection := Array()
    ; Iterates through all video list view elements.
    for (key, videoListEntry in videoListViewContentMap) {
        ; Search in the video title.
        if (InStr(videoListEntry.videoTitle, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(videoListEntry)
        }
        ; Search in the video uploader name.
        else if (InStr(videoListEntry.videoUploader, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(videoListEntry)
        }
        ; Search in the video duration string.
        else if (InStr(videoListEntry.videoDurationString, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(videoListEntry)
        }
        ; Search in the video URL.
        else if (InStr(videoListEntry.videoURL, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(videoListEntry)
        }
    }
    return resultArrayCollection
}

/*
Adds a video list view entry object to the video list view.
@param pVideoListViewEntry [VideoListViewEntry] The video list view entry object to add.
@param pBooleanAutoAdjust [boolean] If set to true, the column width will be adjusted accordingly to the content.
*/
addVideoListViewEntryToListView(pVideoListViewEntry, pBooleanAutoAdjust := true) {
    videoListView.Add("", pVideoListViewEntry.videoTitle, pVideoListViewEntry.videoUploader,
        pVideoListViewEntry.videoDurationString)
    if (pBooleanAutoAdjust) {
        ; Adjust the width accordingly to the content.
        loop (videoListView.GetCount()) {
            videoListView.ModifyCol(A_Index, "AutoHdr")
        }
    }
}

/*
Updates the currently selected video in the video list GUI.
@param pVideoListViewEntry [VideoListViewEntry] The video list view entry object to update the GUI with.
*/
updateCurrentlySelectedVideo(pVideoListViewEntry) {
    ; Saves the currently selected video list view entry object which belongs to the currently selected video list view entry.
    global currentlySelectedVideoListViewEntry := pVideoListViewEntry

    videoTitleText.Text := pVideoListViewEntry.videoTitle
    videoUploaderText.Text := pVideoListViewEntry.videoUploader
    videoDurationText.Text := pVideoListViewEntry.videoDurationString
    videoThumbnailImage.Value := pVideoListViewEntry.videoThumbailFileLocation
    ; Delete the old content of the drop down lists.
    videoDesiredFormatDDL.Delete()
    videoDesiredSubtitleDDL.Delete()
    ; Add the new content to the drop down lists.
    videoDesiredFormatDDL.Add(pVideoListViewEntry.desiredFormatArray)
    videoDesiredSubtitleDDL.Add(pVideoListViewEntry.desiredSubtitleArray)
    ; Select the currently selected format and subtitle.
    try {
        ; This operation will fail when the index is higher than the amount of elements in the DDL.
        videoDesiredFormatDDL.Value := pVideoListViewEntry.desiredFormatArrayCurrentlySelectedIndex
        videoDesiredSubtitleDDL.Value := pVideoListViewEntry.desiredSubtitleArrayCurrentlySelectedIndex
    }
    catch {
        ; Selects the very first entry.
        videoDesiredFormatDDL.Value := 1
        videoDesiredSubtitleDDL.Value := 1
    }
}

/*
Extracts the metadata of a SINGLE video from a given URL using yt-dlp.
@param pVideoURL [String] The URL of the video.
@returns [videoMetaDataObject] This object has the following properties:
videoMetaDataObject.VIDEO_TITLE (The title of the video)
videoMetaDataObject.VIDEO_URL (The URL of the video)
videoMetaDataObject.VIDEO_UPLOADER (The uploader of the video)
videoMetaDataObject.VIDEO_UPLOADER_URL (The URL of the uploader)
videoMetaDataObject.VIDEO_DURATION_STRING (The duration of the video in this format [HH:mm:ss])
videoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION (The location of the thumbnail file)
*/
extractVideoMetaData(pVideoURL) {
    global GUIBackgroundImageLocation
    global ffmpegDirectory

    tempWorkingDirectory := readConfigFile("TEMP_DIRECTORY")
    if (!DirExist(tempWorkingDirectory)) {
        DirCreate(tempWorkingDirectory)
    }
    ; We use the current time stamp to generate a unique name for both files.
    currentTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    metaDataFileLocation := tempWorkingDirectory . "\" . currentTime . ".ini"
    ; The video thumbnail will be stored and it's location saved in the object.
    thumbnailFileLocation := tempWorkingDirectory . "\" . currentTime . ".%(ext)s"

    ; This object stores the video metadata which yt-dlp should extract.
    videoMetaDataObject := Object()
    videoMetaDataObject.VIDEO_TITLE := "%(title)s"
    videoMetaDataObject.VIDEO_ID := "%(id)s"
    videoMetaDataObject.VIDEO_URL := "%(webpage_url)s"
    videoMetaDataObject.VIDEO_UPLOADER := "%(uploader)s"
    videoMetaDataObject.VIDEO_UPLOADER_URL := "%(uploader_url)s"
    videoMetaDataObject.VIDEO_DURATION_STRING := "%(duration_string)s"
    ; Build the meta data string for yt-dlp.
    relevantMetaDataString := "[VideoMetaData]`n"
    for (property, value in videoMetaDataObject.OwnProps()) {
        relevantMetaDataString .= property . "=" . value . "`n"
    }
    relevantMetaDataString := RTrim(relevantMetaDataString, "`n")
    ; Build the actual yt-dlp command.
    ytdlpCommand := '--skip-download --no-playlist --convert-thumbnails "jpg/png" '
    ytdlpCommand .= '--output "thumbnail:' . thumbnailFileLocation . '" --write-thumbnail '
    ytdlpCommand .= '--paths "home:' . tempWorkingDirectory . '" '
    ytdlpCommand .= '--print-to-file "' . relevantMetaDataString . '" "' . metaDataFileLocation . '" '
    ytdlpCommand .= '--ffmpeg-location "' . ffmpegDirectory . '" '
    ytdlpCommand .= '"' . pVideoURL . '"'
    ; Start the status bar loading animation.
    spinnerCharArray := [
        "[🎞️         ]", "[ 🎞️        ]", "[  🎞️       ]", "[   🎞️      ]", "[    🎞️     ]",
        "[     🎞️    ]", "[      🎞️   ]", "[       🎞️  ]", "[        🎞️ ]", "[         🎞️]",
        "[        🎞️ ]", "[       🎞️  ]", "[      🎞️   ]", "[     🎞️    ]", "[    🎞️     ]",
        "[   🎞️      ]", "[  🎞️       ]", "[ 🎞️        ]"
    ]
    handleVideoListGUI_videoListGUIStatusBar_startAnimation("Extracting video data...", spinnerCharArray)
    processPID := executeYTDLPCommand(ytdlpCommand)
    ; Checks if the yt-dlp executable was launched correctly and if so, waits for it to finish.
    if (processPID != "_result_error_while_starting_ytdlp_executable") {
        ProcessWaitClose(processPID)
    }
    ; Extract the metadata from the file into the object.
    for (property, value in videoMetaDataObject.OwnProps()) {
        videoMetaDataObject.%property% := IniRead(metaDataFileLocation, "VideoMetaData", property, "Not found")
    }
    /*
    When yt-dlp cannot find a given URL, it won't create the file.
    Usually, every property of the meta data object would be "Not found" if the file was not created.
    If this is the case, we replace the video title with the video URL to show that this URL could not be found.
    */
    if (!FileExist(metaDataFileLocation)) {
        videoMetaDataObject.VIDEO_TITLE := "video_not_found: " . pVideoURL
        videoMetaDataObject.VIDEO_URL := "video_not_found: " . pVideoURL
    }
    ; We have to find out the extension of the thumbnail file because we don't know it in advance.
    loop files (tempWorkingDirectory . "\" . currentTime ".*") {
        if (A_LoopFileExt != "ini") {
            thumbnailFileLocation := A_LoopFileFullPath
            break
        }
    }
    ; In case the file does not exist, we use a default thumbnail.
    if (!FileExist(thumbnailFileLocation)) {
        thumbnailFileLocation := GUIBackgroundImageLocation
    }
    ; We add this property after the loops because it will not be written by yt-dlp.
    videoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := thumbnailFileLocation
    handleVideoListGUI_videoListGUIStatusBar_stopAnimation("Finished video information extraction")
    return videoMetaDataObject
}

/*
Extracts the metadata of a SINGLE video from a given URL using yt-dlp.
@param pVideoPlaylistURL [String] The URL of the video.
@param pPlayListRangeIndex [String] Used to only extract specific videos from the playlist.
From the yt-dlp documentation:
    Comma separated playlist_index of the items
    to download. You can specify a range using
    "[START]:[STOP][:STEP]". For backward
    compatibility, START-STOP is also supported.
    Use negative indices to count from the right
    and negative STEP to download in reverse
    order. E.g. "--playlist-items 1:3,7,-5::2" used on a
    playlist of size 15 will download the items
    at index 1,2,3,7,11,13,15.
@returns [Array] an array containing a [videoMetaDataObject] for each video in the playlist (or the provided range index).

[videoMetaDataObject] This object has the following properties:
videoMetaDataObject.VIDEO_TITLE (The title of the video)
videoMetaDataObject.VIDEO_URL (The URL of the video)
videoMetaDataObject.VIDEO_UPLOADER (The uploader of the video)
videoMetaDataObject.VIDEO_UPLOADER_URL (The URL of the uploader)
videoMetaDataObject.VIDEO_DURATION_STRING (The duration of the video in this format [HH:mm:ss])
videoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION (The location of the thumbnail file)
*/
extractVideoMetaDataPlaylist(pVideoPlaylistURL, pPlayListRangeIndex := "-1") {
    global GUIBackgroundImageLocation
    global YTDLPFileLocation
    global ffmpegDirectory

    ; We use the current time stamp to generate a unique name for each operation.
    currentTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    tempWorkingDirectory := readConfigFile("TEMP_DIRECTORY")
    tempWorkingDirectoryPlaylist := tempWorkingDirectory . "\" . currentTime . "_playlist"
    ; The %(id)s part will be filled by yt-dlp.
    metaDataFileLocation := tempWorkingDirectoryPlaylist . "\" . currentTime . "_%(id)s.ini"
    thumbnailFileLocation := tempWorkingDirectoryPlaylist . "\" . currentTime . "_%(id)s.%(ext)s"
    if (!DirExist(tempWorkingDirectoryPlaylist)) {
        DirCreate(tempWorkingDirectoryPlaylist)
    }
    ; This object stores the video metadata which yt-dlp should extract.
    videoMetaDataObject := Object()
    videoMetaDataObject.VIDEO_TITLE := "%(title)s"
    videoMetaDataObject.VIDEO_ID := "%(id)s"
    videoMetaDataObject.VIDEO_URL := "%(webpage_url)s"
    videoMetaDataObject.VIDEO_UPLOADER := "%(uploader)s"
    videoMetaDataObject.VIDEO_UPLOADER_URL := "%(uploader_url)s"
    videoMetaDataObject.VIDEO_DURATION_STRING := "%(duration_string)s"
    ; Build the meta data string for yt-dlp.
    relevantMetaDataString := "[VideoMetaData]`n"
    for (property, value in videoMetaDataObject.OwnProps()) {
        relevantMetaDataString .= property . "=" . value . "`n"
    }
    relevantMetaDataString := RTrim(relevantMetaDataString, "`n")
    ; Build the actual yt-dlp command.
    ytdlpCommand := '--skip-download --yes-playlist --convert-thumbnails "jpg/png" '
    ytdlpCommand .= '--output "thumbnail:' . thumbnailFileLocation . '" --write-thumbnail '
    ytdlpCommand .= '--paths "home:' . tempWorkingDirectoryPlaylist . '" '
    ytdlpCommand .= '--print-to-file "' . relevantMetaDataString . '" "' . metaDataFileLocation . '" '
    ytdlpCommand .= '--ffmpeg-location "' . ffmpegDirectory . '" '
    ; If the user wants to download only a specific range of the playlist.
    if (pPlayListRangeIndex != "-1") {
        ytdlpCommand .= '--playlist-items "' . pPlayListRangeIndex . '" '
    }
    ytdlpCommand .= '"' . pVideoPlaylistURL . '"'
    ; Start the status bar loading animation.
    spinnerCharArray := [
        "[💾         ]", "[ 💾        ]", "[  💾       ]", "[   💾      ]", "[    💾     ]",
        "[     💾    ]", "[      💾   ]", "[       💾  ]", "[        💾 ]", "[         💾]",
        "[        💾 ]", "[       💾  ]", "[      💾   ]", "[     💾    ]", "[    💾     ]",
        "[   💾      ]", "[  💾       ]", "[ 💾        ]"
    ]
    handleVideoListGUI_videoListGUIStatusBar_startAnimation("Extracting playlist data...", spinnerCharArray)
    ; Run yt-dlp and create a .INI and a thumbnail file for each video in the playlist.
    processPID := executeYTDLPCommand(ytdlpCommand)
    ; Checks if the yt-dlp executable was launched correctly and if so, waits for it to finish.
    if (processPID != "_result_error_while_starting_ytdlp_executable") {
        ProcessWaitClose(processPID)
    }
    videoMetaDataObjectArray := []
    ; Parse all .INI files in the temp directory and extract the metadata.
    iniFileSearchString := tempWorkingDirectoryPlaylist . "\" . currentTime . "_*.ini"
    loop files (iniFileSearchString) {
        videoMetaDataObject := Object()
        videoMetaDataObject.VIDEO_TITLE := ""
        videoMetaDataObject.VIDEO_ID := ""
        videoMetaDataObject.VIDEO_URL := ""
        videoMetaDataObject.VIDEO_UPLOADER := ""
        videoMetaDataObject.VIDEO_UPLOADER_URL := ""
        videoMetaDataObject.VIDEO_DURATION_STRING := ""
        ; Extract the meta data from the .INI file.
        for (property, value in videoMetaDataObject.OwnProps()) {
            videoMetaDataObject.%property% := IniRead(A_LoopFileFullPath, "VideoMetaData", property,
                "Not found")
        }
        ; We have to find out the extension of the thumbnail file because we don't know it in advance.
        videoID := videoMetaDataObject.VIDEO_ID
        thumbnailSearchString := tempWorkingDirectoryPlaylist . "\" . currentTime . "_" . videoID . ".*"
        thumbnailFileLocation := ""
        loop files (thumbnailSearchString) {
            if (A_LoopFileExt != "ini") {
                thumbnailFileLocation := A_LoopFileFullPath
                break
            }
        }
        ; In case the file does not exist, we use a default thumbnail.
        if (!FileExist(thumbnailFileLocation)) {
            thumbnailFileLocation := GUIBackgroundImageLocation
        }
        ; We add this property after the loops because it will not be written by yt-dlp.
        videoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := thumbnailFileLocation
        videoMetaDataObjectArray.Push(videoMetaDataObject)
    }
    handleVideoListGUI_videoListGUIStatusBar_stopAnimation("Finished playlist information extraction")
    return videoMetaDataObjectArray
}

/*
Downloads a video from a given video list view entry object.
@param pVideoListViewEntry [VideoListViewEntry] The video list view entry object to download.
@param pDownloadTargetDirectory [String] The target directory to download the video to.
*/
downloadVideoListViewEntry(pVideoListViewEntry, pDownloadTargetDirectory) {
    global currentYTDLPActionObject
    global YTDLPFileLocation
    global ffmpegDirectory

    if (!DirExist(pDownloadTargetDirectory)) {
        DirCreate(pDownloadTargetDirectory)
    }
    tempWorkingDirectory := readConfigFile("TEMP_DIRECTORY")
    if (!DirExist(tempWorkingDirectory)) {
        DirCreate(tempWorkingDirectory)
    }
    downloadTempDirectory := readConfigFile("TEMP_DOWNLOAD_DIRECTORY")
    if (!DirExist(downloadTempDirectory)) {
        DirCreate(downloadTempDirectory)
    }

    ; Build the yt-dlp command to download the video and add progress tracking points to the stdout.
    ytdlpCommand := '--no-playlist --paths "' . pDownloadTargetDirectory . '" '
    ytdlpCommand .= '--paths "temp:' . downloadTempDirectory . '" '
    ytdlpCommand .= '--ffmpeg-location "' . ffmpegDirectory . '" '
    ytdlpCommand .=
        '--progress-template "[Downloading...] [%(progress._percent_str)s of %(progress._total_bytes_str)s ' .
        'at %(progress._speed_str)s. Time passed: %(progress._elapsed_str)s]" '
    ; These printed lines will be used to track the download progress more accurately.
    ytdlpCommand .=
        '--print "pre_process:[PROGRESS_INFO_PRE_PROCESS] [Tracking Point: Video information has been extracted.]" '
    ytdlpCommand .=
        '--print "after_filter:[PROGRESS_INFO_AFTER_FILTER] [Tracking Point: Video has passed the format filter.]" '
    ytdlpCommand .=
        '--print "video:[PROGRESS_INFO_VIDEO] [Tracking Point: Starting download of subtitle and other requested files...]" '
    ytdlpCommand .=
        '--print "before_dl:[PROGRESS_INFO_BEFORE_DL] [Tracking Point: Starting video download...]" '
    ytdlpCommand .=
        '--print "post_process:[PROGRESS_INFO_POST_PROCESS] [Tracking Point: All relevant files have been downloaded. Starting video post processing...]" '
    ytdlpCommand .=
        '--print "after_move:[PROGRESS_INFO_AFTER_MOVE] [Tracking Point: Video has been post processed and moved.]" '
    ytdlpCommand .=
        '--print "after_video:[PROGRESS_INFO_AFTER_VIDEO] [Tracking Point: The video download process has been finished.]" '
    ; Those options are required due to the use of the --print command.
    ytdlpCommand .= '--no-quiet --no-simulate '
    ; Add the custom parameters from the video list view entry.
    pVideoListViewEntry.generateDownloadCommandPart()
    ytdlpCommand .= pVideoListViewEntry.downloadCommandPart

    ; We use the current time stamp to generate a unique name for log file.
    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    ; Defines the yt-dlp download log file name.
    ytdlpDownloadLogFileName := currentTime . "_yt_dlp_download_log.log"
    ytdlpDownloadLogFileLocation := tempWorkingDirectory . "\" . ytdlpDownloadLogFileName
    ; Defines the yt-dlp error log file name.
    ytdlpErrorLogFileName := currentTime . "_yt_dlp_error_log.log"
    ytdlpErrorLogFileLocation := tempWorkingDirectory . "\" . ytdlpErrorLogFileName
    ; Execute the yt-dlp command and monitor the download progress.
    processPID := executeYTDLPCommand(ytdlpCommand, ytdlpDownloadLogFileLocation, ytdlpErrorLogFileLocation)

    ; Fill the currentYTDLPActionObject with data which can be used to cancel the download.
    currentYTDLPActionObject.downloadProcessYTDLPPID := processPID

    ; Progress section below.
    videoTitle := pVideoListViewEntry.videoTitle
    statusBarText := "[" . videoTitle . "] - Starting download process..."
    handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
    ; This function monitor the download progress and update the video list GUI accordingly.
    monitorVideoDownloadProgress(processPID, ytdlpDownloadLogFileLocation, videoTitle)

    ; Checks if the yt-dlp executable was launched correctly and if so, waits for it to finish.
    if (processPID != "_result_error_while_starting_ytdlp_executable") {
        ProcessWaitClose(processPID)
    }
    if (currentYTDLPActionObject.booleanCancelOneVideoDownload) {
        statusBarText := "[" . videoTitle . "] - Canceled download process."
    }
    else {
        statusBarText := "[" . videoTitle . "] - Finished download process."
    }
    handleVideoListGUI_videoListGUIStatusBar_stopAnimation(statusBarText)
    ; This delay allows the user to read the status message for a short period of time before downloading the next video.
    Sleep(200)
}

/*
Extracts the metadata of a video from a given URL using yt-dlp.
This object is used as a data container for the video list view element.
@param pVideoURL [String] The URL of the video OR a [videoMetaDataObject]. See extractVideoMetaData() for more information.
@param pBooleanUpdateVideoListViewElement[boolean] if set to true, the video list view element will be updated.
*/
class VideoListViewEntry {
    __New(pVideoURLOrVideoMetaDataObject, pBooleanUpdateVideoListViewElement := true) {
        global desiredDownloadFormatArray
        global desiredSubtitleArray

        /*
        This map stores all video list view content objects with their identifier string as key.
        It is used to provide the content for the video list view element.
        */
        if (!isSet(videoListViewContentMap)) {
            global videoListViewContentMap := Map()
        }
        ; Use the meta data object if it is already given.
        if (IsObject(pVideoURLOrVideoMetaDataObject)) {
            metaData := pVideoURLOrVideoMetaDataObject
        }
        ; Extract the meta data from the given URL.
        else {
            metaData := extractVideoMetaData(pVideoURLOrVideoMetaDataObject)
        }
        this.videoTitle := metaData.VIDEO_TITLE
        this.videoUploader := metaData.VIDEO_UPLOADER
        this.videoDurationString := metaData.VIDEO_DURATION_STRING
        this.videoURL := metaData.VIDEO_URL
        this.videoUploaderURL := metaData.VIDEO_UPLOADER_URL
        this.videoThumbailFileLocation := metaData.VIDEO_THUMBNAIL_FILE_LOCATION
        ; The following attributes will be used when downloading the video.
        this.desiredFormatArray := desiredDownloadFormatArray.Clone()
        ; This option changes when the user selects a different format in the video list GUI.
        this.desiredFormatArrayCurrentlySelectedIndex := readConfigFile("DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX")
        this.desiredSubtitleArray := desiredSubtitleArray.Clone()
        ; This option changes when the user selects a different format in the video list GUI.
        this.desiredSubtitleArrayCurrentlySelectedIndex := readConfigFile("DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX")
        ; This is the part of the download command that is specific to this video.
        this.downloadCommandPart := ""
        ; Creates the download command for the first time.
        this.generateDownloadCommandPart()
        ; The following attributes are required for other purposes such as identification.
        this.identifierString := this.videoTitle . this.videoUploader . this.videoDurationString
        ; Adds this object to the video list view content map.
        this.addEntryToVideoListViewContentMap(pBooleanUpdateVideoListViewElement)
    }
    ; Generates the part of the download command that is specific to this video.
    generateDownloadCommandPart() {
        this.downloadCommandPart := ''
        desiredFormat := this.desiredFormatArray[this.desiredFormatArrayCurrentlySelectedIndex]
        videoFormatArray := ["Automatically choose best video format", "mp4", "webm", "avi", "flv", "mkv", "mov"]
        audioFormatArray := ["Automatically choose best audio format", "mp3", "wav", "m4a", "flac", "opus",
            "vorbis"]

        ; In case the user selected a video format.
        if (checkIfStringIsInArray(desiredFormat, videoFormatArray)) {
            ; We only (possibly) need to recode the video if the user selected a specific format.
            if (desiredFormat != "Automatically choose best video format") {
                this.downloadCommandPart .= '--recode-video "' . desiredFormat . '" '
            }
        }
        ; In case the user selected an audio format.
        else if (checkIfStringIsInArray(desiredFormat, audioFormatArray)) {
            this.downloadCommandPart .= "--extract-audio "
            ; We only (possibly) need to recode the audio if the user selected a specific format.
            if (desiredFormat != "Automatically choose best audio format") {
                this.downloadCommandPart .= '--audio-format "' . desiredFormat . '" '
            }
        }
        ; Embeds the subtitles if the user selected this option.
        desiredSubtitleFormat := this.desiredSubtitleArray[this.desiredSubtitleArrayCurrentlySelectedIndex]
        if (desiredSubtitleFormat == "Embed all available subtitles") {
            this.downloadCommandPart .= '--sub-langs "all" '
            this.downloadCommandPart .= "--embed-subs "
        }
        this.downloadCommandPart .= '"' . this.videoURL . '" '
    }
    /*
    SHOULD be called when the values of this.videoTitle, this.videoUploader or this.videoDurationString are changed externally.
    @param pBooleanUpdateVideoListViewElementWhenRemovingOldEntry [boolean] If set to true, the video list view element will be updated when removing the old entry.
    */
    rebuildIdentifierString(pBooleanUpdateVideoListViewElementWhenRemovingOldEntry := true) {
        if (pBooleanUpdateVideoListViewElementWhenRemovingOldEntry) {
            ; Removes the old entry with the old identifier string from the video list view content map.
            this.removeEntryFromVideoListViewContentMap()
        }
        else {
            /*
            Suppresses the update of the video list view element because we are going to update it after the new entry is added.
            This avoids an inifinte loop when the only element is the no entries entry.
            */
            this.removeEntryFromVideoListViewContentMap(false)
        }
        this.identifierString := this.videoTitle . this.videoUploader . this.videoDurationString
        this.addEntryToVideoListViewContentMap()
    }
    /*
    Adds the object to the video list view content map.
    @param pBooleanUpdateVideoListViewElement[boolean] if set to true, the video list view element will be updated.
    */
    addEntryToVideoListViewContentMap(pBooleanUpdateVideoListViewElement := true) {
        global videoListViewContentMap
        videoListViewContentMap.Set(this.identifierString, this)
        if (pBooleanUpdateVideoListViewElement) {
            this.updateVideoListViewElement()
        }
    }
    /*
    Removes the object from the video list view content map.
    @param pBooleanUpdateVideoListViewElement [boolean] If set to true, the video list view element will be updated.
    */
    removeEntryFromVideoListViewContentMap(pBooleanUpdateVideoListViewElement := true) {
        global videoListViewContentMap
        videoListViewContentMap.Delete(this.identifierString)
        if (pBooleanUpdateVideoListViewElement) {
            this.updateVideoListViewElement()
        }
    }
    ; Updates the video list view element with the current content of the video list view content map.
    updateVideoListViewElement() {
        global GUIBackgroundImageLocation
        global videoListViewContentMap
        if (videoListViewContentMap.Count == 0) {
            ; This entry is displayed when no videos are added yet.
            tmpVideoMetaDataObject := Object()
            tmpVideoMetaDataObject.VIDEO_TITLE := "*****"
            tmpVideoMetaDataObject.VIDEO_ID := ""
            tmpVideoMetaDataObject.VIDEO_URL := "_internal_entry_no_videos_added_yet"
            tmpVideoMetaDataObject.VIDEO_UPLOADER := "No videos added yet."
            tmpVideoMetaDataObject.VIDEO_UPLOADER_URL := ""
            tmpVideoMetaDataObject.VIDEO_DURATION_STRING := "*****"
            tmpVideoMetaDataObject.VIDEO_THUMBNAIL_FILE_LOCATION := GUIBackgroundImageLocation
            ; Create the entry using the temporary video meta data object.
            noEntriesVideoListEntry := VideoListViewEntry(tmpVideoMetaDataObject)
            noEntriesVideoListEntry.desiredFormatArray := ["None"]
            noEntriesVideoListEntry.desiredSubtitleArray := ["None"]
            updateCurrentlySelectedVideo(noEntriesVideoListEntry)
        }
        ; This means there is at least one video together with the no entries entry in the list view.
        else if (videoListViewContentMap.Count >= 2) {
            ; Remove the no entries entry if it is in the list view.
            if (videoListViewContentMap.Has("*****No videos added yet.*****")) {
                videoListViewContentMap.Get("*****No videos added yet.*****").removeEntryFromVideoListViewContentMap()
                ; Select the video. Otherwise the currently selected video would stay at the no entries entry.
                updateCurrentlySelectedVideo(this)
            }
        }
        ; Clears the old data from the list view element.
        videoListView.Delete()
        for (key, value in videoListViewContentMap) {
            addVideoListViewEntryToListView(value)
        }
        ; Sorts the videos in case a search prompt is present in the search field.
        if (videoListSearchBarInputEdit.Value != "") {
            handleVideoListGUI_videoListSearchBarInputEdit_onChange(videoListSearchBarInputEdit, "")
        }
    }
}
