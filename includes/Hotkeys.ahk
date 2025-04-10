#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

hotkeys_onInit() {
    try {
        registerHotkeys()
    }
    catch as error {
        displayErrorMessage(error)
    }
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

registerHotkeys() {
    ; Main hotkey (start download).
    if (readConfigFile("START_DOWNLOAD_HK_ENABLED")) {
        Hotkey(readConfigFile("START_DOWNLOAD_HK"), (*) => hotkey_startDownload(), "On")
    }
    ; First hotkey (collect URLs).
    if (readConfigFile("URL_COLLECT_HK_ENABLED")) {
        Hotkey(readConfigFile("URL_COLLECT_HK"), (*) => hotkey_extractVideoURLFromSearchBar(), "On")
    }
    ; Second hotkey (collect URLs from video thumbnail).
    if (readConfigFile("THUMBNAIL_URL_COLLECT_HK_ENABLED")) {
        Hotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK"), (*) => hotkey_extractVideoURLUnderMouseCursor(), "On")
    }
    ; Hotkey to open the video list GUI.
    if (readConfigFile("VIDEO_LIST_GUI_HK_ENABLED")) {
        Hotkey(readConfigFile("VIDEO_LIST_GUI_HK"), (*) => hotkey_openVideoListGUI(), "On")
    }
    ; Hotkey to terminate the program.
    if (readConfigFile("TERMINATE_PROGRAM_HK_ENABLED")) {
        Hotkey(readConfigFile("TERMINATE_PROGRAM_HK"), (*) => hotkey_terminateProgram(), "On")
    }
    ; Hotkey to reload the program.
    if (readConfigFile("RELOAD_PROGRAM_HK_ENABLED")) {
        Hotkey(readConfigFile("RELOAD_PROGRAM_HK"), (*) => hotkey_reloadProgram(), "On")
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
    handleVideoListGUI_downloadAllVideosButton_onClick("", "")
}

; Extracts the video URL from the browser search bar.
hotkey_extractVideoURLFromSearchBar() {
    A_Clipboard := ""
    Send("^{l}")
    Sleep(150)
    Send("^{c}")
    if (!ClipWait(0.5)) {
        MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T1")
        return
    }
    clipboardContent := A_Clipboard
    Sleep(150)
    Send("{Escape}")
    Send("{Escape}")
    if (!checkIfStringIsAValidURL(clipboardContent)) {
        MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T1")
        return
    }
    ; Extracts the video meta data and checks if it is already in the video list.
    resultArray := createVideoListViewEntry(clipboardContent)
    if (resultArray[1] == "_result_video_already_in_list") {
        MsgBox(resultArray[2] . "`n`nis already in the video list.", "VD - Duplicate URL!", "O Iconi T2")
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
        MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T1")
        return
    }
    ; Extracts the video meta data and checks if it is already in the video list.
    resultArray := createVideoListViewEntry(url)
    if (resultArray[1] == "_result_video_already_in_list") {
        MsgBox(resultArray[2] . "`n`nis already in the video list.", "VD - Duplicate URL!", "O Iconi T2")
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
        static flipflop := true
        if (!WinExist("ahk_id " . videoListGUI.Hwnd)) {
            videoListGUI.Show("AutoSize")
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
    terminateScriptPrompt()
}

hotkey_reloadProgram() {
    reloadScriptPrompt()
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
    MsgBox("This debug hotkey is currently not used.", "VD - WIP", "O Iconi 262144 T1")
}

hotkey_debug_4() {
    MsgBox("This debug hotkey is currently not used.", "VD - WIP", "O Iconi 262144 T1")
}

/*
DEBUG HOTKEY FUNCTION SECTION END
-------------------------------------------------
*/

/*
MENU FUNCTION SECTION
-------------------------------------------------
*/

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

; Opens the explorer.
menu_openDownloadLocation() {
    try
    {
        /*
        The reason why the path is opened explicitly with explorer.exe is, that sometimes it will attempt to sort of guess the file
        extension and open other files.
        */
        downloadDirectory := readConfigFile("DEFAULT_DOWNLOAD_DIRECTORY")
        if (DirExist(downloadDirectory)) {
            Run('explorer.exe "' . downloadDirectory . '"')
        }
        else {
            MsgBox("The directory`n[" . downloadDirectory . "]`ndoes not exist.", "VD - Nonexisting Directory!",
                "O Icon! 262144 T3")
        }
    }
    catch as error {
        displayErrorMessage(error, "This error is rare.")
    }
}

/*
MENU FUNCTION SECTION END
-------------------------------------------------
*/
