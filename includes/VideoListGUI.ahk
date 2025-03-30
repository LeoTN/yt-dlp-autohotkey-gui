#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

/*
Allows the DELETE key to have the same function as clicking the remove video from list button.
This is done to allow the user to delete videos from the list by pressing the DELETE key.
It only works while the video list GUI is the active window.
*/
#HotIf (WinExist("ahk_id " . videoListGUI.Hwnd) && WinActive("ahk_id " . videoListGUI.Hwnd))
Delete:: {
    handleVideoListGUI_removeVideoFromListButton_onClick("", "")
}
#HotIf

/*
Allows the ENTER key to function the same way as the add video to list button.
This makes adding a video URL more convenient as the user can simply press enter while focused on the URL input field.
Only works while the URL input field or the playlist range input field is focused.
*/
#HotIf (WinExist("ahk_id " . videoListGUI.Hwnd) &&
((ControlGetFocus("ahk_id " . videoListGUI.Hwnd) == addVideoURLInputEdit.Hwnd ||
ControlGetFocus("ahk_id " . videoListGUI.Hwnd) == addVideoSpecifyPlaylistRangeInputEdit.Hwnd)))
Enter:: {
    handleVideoListGUI_addVideoToListButton_onClick("", "")
}
#HotIf

createVideoListGUI() {
    global
    videoListGUI := Gui("+OwnDialogs", "VD - Video List")
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
    addVideoToListButton := videoListGUI.Add("Button", "xp-560 yp+29 w200", "Add Video URL To List")
    addVideoURLIsAPlaylistCheckbox := videoListGUI.Add("CheckBox", "xp+10 yp+30", "Add videos from a playlist")
    addVideoURLUsePlaylistRangeCheckbox := videoListGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only add videos in a specific range")
    addVideoSpecifyPlaylistRangeText := videoListGUI.Add("Text", "yp+20", "Index Range")
    addVideoSpecifyPlaylistRangeInputEdit := videoListGUI.Add("Edit", "yp+20 w100 +Disabled", "1")
    ; Remove video elements.
    removeVideoFromListButton := videoListGUI.Add("Button", "xp+200 yp-90 w200", "Remove Selected Video(s) From List")
    removeVideoConfirmDeletionCheckbox := videoListGUI.Add("CheckBox", "xp+10 yp+30",
        "Confirm deletion of selected videos")
    removeVideoConfirmOnlyWhenMultipleSelectedCheckbox := videoListGUI.Add("CheckBox", "yp+20 +Disabled",
        "Only multiple videos")
    ; Import and export elements.
    importVideoListButton := videoListGUI.Add("Button", "xp+200 yp-50 w75", "Import")
    exportVideoListButton := videoListGUI.Add("Button", "yp xp+85 w75", "Export")
    exportOnlySelectedVideosCheckbox := videoListGUI.Add("CheckBox", "xp-75 yp+30", "Only export selected videos")
    autoExportVideoListCheckbox := videoListGUI.Add("CheckBox", "yp+20", "Auto export video list (WIP)") ; REMOVE
    ; Controls that are relevant for downloading the videos in the video list.
    downloadVideoGroupBox := videoListGUI.Add("GroupBox", "w300 xm+610 ym+400 h185", "Download (WIP)") ; REMOVE
    downloadAllVideosButton := videoListGUI.Add("Button", "xp+10 yp+20 w135", "Download All")
    downloadCancelButton := videoListGUI.Add("Button", "xp+145 yp w135", "Cancel Download")
    downloadRemoveVideosAfterDownloadCheckbox := videoListGUI.Add("Checkbox", "xp-135 yp+30 Checked",
        "Automatically remove downloaded videos")
    downloadTerminateAfterDownloadCheckbox := videoListGUI.Add("Checkbox", "yp+20",
        "Terminate application after download")
    downloadSelectDownloadDirectoryText := videoListGUI.Add("Text", "xp-10 yp+20", "Download Directory")
    downloadSelectDownloadDirectoryInputEdit := videoListGUI.Add("Edit", "yp+20 w255 R1 -WantReturn +ReadOnly",
        "default")
    downloadSelectDownloadDirectoryButton := videoListGUI.Add("Button", "xp+260 yp+1 w20 h20", "...")
    downloadProgressText := videoListGUI.Add("Text", "xp-260 yp+29", "Downloaded 0 / 0 (WIP)") ; REMOVE
    downloadProgressBar := videoListGUI.Add("Progress", "yp+20 w280")
    ; Status bar
    videoListGUIStatusBar := videoListGUI.Add("StatusBar", , "Add a video URL to start")
    videoListGUIStatusBar.SetIcon("shell32.dll", 222)
    videoListGUIStatusBar.loadingAnimationIsPlaying := false

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
    addVideoURLIsAPlaylistCheckbox.OnEvent("Click", handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick)
    addVideoURLUsePlaylistRangeCheckbox.OnEvent("Click",
        handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick)
    addVideoToListButton.OnEvent("Click", handleVideoListGUI_addVideoToListButton_onClick)
    ; Remove video elements.
    removeVideoFromListButton.OnEvent("Click", handleVideoListGUI_removeVideoFromListButton_onClick)
    removeVideoConfirmDeletionCheckbox.OnEvent("Click", handleVideoListGUI_removeVideoConformDeletionCheckbox_onClick)
    ; Import and export elements.
    importVideoListButton.OnEvent("Click", handleVideoListGUI_importVideoListButton_onClick)
    exportVideoListButton.OnEvent("Click", handleVideoListGUI_exportVideoListButton_onClick)
    ; Video list controls.
    videoListView.OnEvent("ItemSelect", handleVideoListGUI_videoListView_onItemSelect)
    ; Controls that are relevant for downloading the videos in the video list.
    downloadAllVideosButton.OnEvent("Click", handleVideoListGUI_downloadAllVideosButton_onClick)
    downloadCancelButton.OnEvent("Click", handleVideoListGUI_downloadCancelButton_onClick)
    downloadSelectDownloadDirectoryButton.OnEvent("Click",
        handleVideoListGUI_downloadSelectDownloadDirectoryButton_onClick)
    ; Enables the help button in the MsgBox which informs the user once they entered an incorrect playlist range index.
    OnMessage(0x0053, handleVideoListGUI_invalidPlaylistRangeIndexMsgBoxHelpButton)
    /*
    ********************************************************************************************************************
    This section creates all the menus.
    ********************************************************************************************************************
    */
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add("Config-File`tShift+1", (*) => menu_openConfigFile())
    fileSelectionMenuOpen.SetIcon("Config-File`tShift+1", "shell32.dll", 70)
    fileSelectionMenuOpen.Add("Download destination`tShift+2", (*) => menu_openDownloadLocation()) ; REMOVE
    fileSelectionMenuOpen.SetIcon("Download destination`tShift+2", "shell32.dll", 116)

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add("Config-File`tCtrl+1", (*) => createDefaultConfigFile(, true))
    fileSelectionMenuReset.SetIcon("Config-File`tCtrl+1", "shell32.dll", 70)

    fileMenu := Menu()
    fileMenu.Add("&Open...", fileSelectionMenuOpen)
    fileMenu.SetIcon("&Open...", "shell32.dll", 127)
    fileMenu.Add("&Reset...", fileSelectionMenuReset)
    fileMenu.SetIcon("&Reset...", "shell32.dll", 239)

    optionsMenu := Menu()
    optionsMenu.Add("Open New Settings Window (Beta)",
        (*) => MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1")) ; REMOVE
    optionsMenu.SetIcon("Open New Settings Window (Beta)", "shell32.dll", 123) ; REMOVE
    optionsMenu.Add("Terminate Script", (*) => terminateScriptPrompt())
    optionsMenu.SetIcon("Terminate Script", "shell32.dll", 28)
    optionsMenu.Add("Reload Script", (*) => reloadScriptPrompt())
    optionsMenu.SetIcon("Reload Script", "shell32.dll", 207)

    allMenus := MenuBar()
    allMenus.Add("&File", fileMenu)
    allMenus.SetIcon("&File", "shell32.dll", 4)
    allMenus.Add("&Options", optionsMenu)
    allMenus.SetIcon("&Options", "shell32.dll", 317)
    allMenus.Add("&Help", (*) => helpGUI.Show())
    allMenus.SetIcon("&Help", "shell32.dll", 24)
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
}

videoListGUI_onInit() {
    createVideoListGUI()
    if (readConfigFile("SHOW_VIDEO_LIST_GUI_ON_LAUNCH")) {
        hotkey_openVideoListGUI()
    }
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
        tmpVideoMetaDataObject.VIDEO_URL := ""
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
    if (addVideoURLUsePlaylistRangeCheckbox.Value) {
        ; Checks if the provided playlist range index string has a correct syntaxt (1-2 or 1:2 for example).
        regExString := '^([1-9]\d*([-:]\d+)?)(,[1-9]\d*([-:]\d+)?)*$'
        if (!RegExMatch(addVideoSpecifyPlaylistRangeInputEdit.Value, regExString)) {
            result := MsgBox("The provided playlist range index is invalid!", "VD - Invalid Playlist Range Index",
                "O Icon! 16384 Owner" . videoListGUI.Hwnd)
            return
        }
    }
    ; This means the provided URL contains a refference to a playlist.
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
            tmpVideoMetaDataObject.VIDEO_URL := ""
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

handleVideoListGUI_removeVideoFromListButton_onClick(pButton, pInfo) {
    selectedItemsIdentifierStringArray := []
    ; Count the selected elements in the list view.
    listViewSelectedElementsCount := ListViewGetContent("Count Selected", videoListView.Hwnd,
        "ahk_id " . videoListGUI.Hwnd)
    ; Prompts the user to confirm the deletion of one video element.
    if (listViewSelectedElementsCount == 1 &&
        removeVideoConfirmDeletionCheckbox.Value && !removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value) {
        result := MsgBox("Do you really want to delete this video?", "VD - Confirm Deletion",
            "YN Icon? 262144 T15")
        if (result != "Yes") {
            return
        }
    }
    ; Prompts the user to confirm the deletion of multiple video elements.
    else if (listViewSelectedElementsCount > 1 &&
        (removeVideoConfirmDeletionCheckbox.Value || removeVideoConfirmOnlyWhenMultipleSelectedCheckbox.Value)) {
        result := MsgBox("Do you really want to delete " . listViewSelectedElementsCount . " videos?",
            "VD - Confirm Deletion", "YN Icon? 262144 T15")
        if (result != "Yes") {
            return
        }
    }
    ; Get all selected list view items or rather their content in the form of a string.
    listViewContent := ListViewGetContent("Selected", videoListView.Hwnd, "ahk_id " . videoListGUI.Hwnd)
    ; The content is separated by new lines and tabs so we need two loops to get the identifier strings.
    loop parse, listViewContent, "`n" {
        entryIdentifierString := ""
        loop parse, A_LoopField, A_Tab {
            entryIdentifierString .= A_LoopField
        }
        selectedItemsIdentifierStringArray.Push(entryIdentifierString)
    }
    for (index, identifierString in selectedItemsIdentifierStringArray) {
        ; Find the matching video list view entry object with that identifier string.
        selectedVideoEntry := videoListViewContentMap.Get(identifierString)
        selectedVideoEntry.removeEntryFromVideoListViewContentMap()
    }
}

handleVideoListGUI_removeVideoConformDeletionCheckbox_onClick(pCheckbox, pInfo) {
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
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleVideoListGUI_exportVideoListButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
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

handleVideoListGUI_downloadAllVideosButton_onClick(pButton, pInfo) {
    global videoListViewContentMap
    global scriptWorkingDirectory
    global videoListViewContentMap

    static booleanDownloadIsRunning
    ; This ensures that there can only be one download process at the time.
    if (!IsSet(booleanDownloadIsRunning) || !booleanDownloadIsRunning) {
        booleanDownloadIsRunning := true
    }
    else {
        MsgBox("There is already another download in progress.", "VD - Other Download Running", "O Iconi 262144 T1")
        return
    }
    /*
    Create a local copy of the video list view content map to avoid download issues
    when the original map changes during the download.
    It only contains valid URLs which could be found by yt-dlp.
    */
    localCopyVideoListViewContentMap := videoListViewContentMap.Clone()
    for (key, videoListEntry in videoListViewContentMap) {
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

    ; We use the current time stamp to generade a unique name for the download folder.
    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
    currentDownloadDirectory := scriptWorkingDirectory . "\download\" . currentTime
    alternativeDownloadDirectory := downloadSelectDownloadDirectoryInputEdit.Value
    if (DirExist(alternativeDownloadDirectory)) {
        targetDownloadDirectory := alternativeDownloadDirectory
    }
    else {
        targetDownloadDirectory := currentDownloadDirectory
    }

    totalAvailableVideoAmount := localCopyVideoListViewContentMap.Count
    totalDownloadedVideoAmount := 0
    ; Parse through each video and start the download process.
    for (key, videoListEntry in localCopyVideoListViewContentMap) {
        videoURL := videoListEntry.videoURL
        downloadVideoListViewEntry(videoListEntry, targetDownloadDirectory)
        ; Remove the video from the video list view element.
        if (downloadRemoveVideosAfterDownloadCheckbox.Value) {
            videoListEntry.removeEntryFromVideoListViewContentMap()
        }
        totalDownloadedVideoAmount++
    }
    if (totalDownloadedVideoAmount == 1) {
        videoListGUIStatusBar.SetText("Downloaded 1 video to [" . targetDownloadDirectory . "]")
    }
    else if (totalDownloadedVideoAmount > 1) {
        videoListGUIStatusBar.SetText("Downloaded " . totalDownloadedVideoAmount
            . " videos to [" . targetDownloadDirectory . "]")
    }
    if (downloadTerminateAfterDownloadCheckbox.Value) {
        exitScriptWithNotification()
    }
    booleanDownloadIsRunning := false
}

handleVideoListGUI_downloadCancelButton_onClick(pButton, pInfo) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

handleVideoListGUI_downloadSelectDownloadDirectoryButton_onClick(pButton, pInfo) {
    global scriptWorkingDirectory

    if (downloadSelectDownloadDirectoryInputEdit.Value != "") {
        ; This will open the current directory (if one is already selected and the folder exists).
        if (DirExist(downloadSelectDownloadDirectoryInputEdit.Value)) {
            selectPath := downloadSelectDownloadDirectoryInputEdit.Value
        }
        else {
            selectPath := scriptWorkingDirectory
        }
    }
    else {
        selectPath := scriptWorkingDirectory
    }

    downloadDirectory := FileSelect("D", selectPath, "VD - Please select the download target folder")
    ; Makes sure that the path is an actual file and not a directory or more specifically a folder.
    ; This usually happens, when the user cancels the selection.
    if (downloadDirectory == "") {
        return
    }
    downloadSelectDownloadDirectoryInputEdit.Value := downloadDirectory
}

handleVideoListGUI_invalidPlaylistRangeIndexMsgBoxHelpButton(*) {
    MsgBox("Not implemented yet.", "VD - WIP", "O Iconi 262144 T1") ; REMOVE
}

/*
Shows a neat little loading animation in the status bar.
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
        videoListGUIStatusBar.SetText(pStatusBarText . " " . currentChar)
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
    videoListGUIStatusBar.SetText(pStatusBarText)
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
    videoDesiredFormatDDL.Value := pVideoListViewEntry.desiredFormatArrayCurrentlySelectedIndex
    videoDesiredSubtitleDDL.Value := pVideoListViewEntry.desiredSubtitleArrayCurrentlySelectedIndex
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
    global scriptWorkingDirectory

    tempWorkingDirectory := scriptWorkingDirectory . "\temp" ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
    if (!DirExist(tempWorkingDirectory)) {
        DirCreate(tempWorkingDirectory)
    }
    ; We use the current time stamp to generade a unique name for both files.
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
    global scriptWorkingDirectory

    ; We use the current time stamp to generade a unique name for each operation.
    currentTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    tempWorkingDirectoryPlaylist := scriptWorkingDirectory . "\temp\" . currentTime . "_playlist"  ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
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

downloadVideoListViewEntry(pVideoListViewEntry, pDownloadTargetDirectory) {
    global scriptWorkingDirectory
    global YTDLPFileLocation
    global ffmpegDirectory

    if (!DirExist(pDownloadTargetDirectory)) {
        DirCreate(pDownloadTargetDirectory)
    }
    ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
    downloadTempDirectory := scriptWorkingDirectory . "\download_temp"
    if (!DirExist(downloadTempDirectory)) {
        DirCreate(downloadTempDirectory)
    }

    ytdlpCommand := '--no-playlist --paths "' . pDownloadTargetDirectory . '" '
    ytdlpCommand .= '--paths "temp:' . downloadTempDirectory . '" '
    ytdlpCommand .= '--ffmpeg-location "' . ffmpegDirectory . '" '
    ; Add the custom parameters from the video list view entry.
    pVideoListViewEntry.generateDownloadCommandPart()
    ytdlpCommand .= pVideoListViewEntry.downloadCommandPart
    videoTitle := pVideoListViewEntry.videoTitle
    handleVideoListGUI_videoListGUIStatusBar_startAnimation("Downloading (" . videoTitle . ")...")
    processPID := executeYTDLPCommand(ytdlpCommand)
    ; Checks if the yt-dlp executable was launched correctly and if so, waits for it to finish.
    if (processPID != "_result_error_while_starting_ytdlp_executable") {
        ProcessWaitClose(processPID)
    }
    handleVideoListGUI_videoListGUIStatusBar_stopAnimation("Finished downloading (" . videoTitle . ")")
    ; This delay gives the loading bar animation enough time to end properly and avoid visual bugs.
    Sleep(200)
}

/*
Checks if a given string is in a given array.
@param pString [String] The string to check.
@param pArray [Array] The array to check.
@returns [boolean] True if the string is in the array, false otherwise.
*/
checkIfStringIsInArray(pString, pArray) {
    for (index, value in pArray) {
        if (pString == value) {
            return true
        }
    }
    return false
}

/*
Extracts the metadata of a video from a given URL using yt-dlp.
This object is used as a data container for the video list view element.
@param pVideoURL [String] The URL of the video OR a [videoMetaDataObject]. See extractVideoMetaData() for more information.
@param pBooleanUpdateVideoListViewElement[boolean] if set to true, the video list view element will be updated.
*/
class VideoListViewEntry {
    __New(pVideoURLOrVideoMetaDataObject, pBooleanUpdateVideoListViewElement := true) {
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
        this.desiredFormatArray := [
            ; Video formats.
            "Automatically choose best video format", "mp4", "webm", "avi", "flv", "mkv", "mov",
            ; Audio formats.
            "Automatically choose best audio format", "mp3", "wav", "m4a", "flac", "opus", "vorbis"
        ]
        ; This option changes when the user selects a different format in the video list GUI.
        this.desiredFormatArrayCurrentlySelectedIndex := 1
        this.desiredSubtitleArray := [
            "Do not download subtitles", "Embed all available subtitles" ; REMOVE [ADD AVAILABLE SUBTITLES IN THE FUTURE]
        ]
        ; This option changes when the user selects a different format in the video list GUI.
        this.desiredSubtitleArrayCurrentlySelectedIndex := 1
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
    Removes this object from the video list view content map.
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
            tmpVideoMetaDataObject.VIDEO_URL := ""
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
