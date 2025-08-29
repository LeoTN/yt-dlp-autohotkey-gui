#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

functions_onInit() {
    /*
    This causes the application to react upon the user moving his mouse and show
    a tooltip if possible for the GUI element under the cursor.
    */
    OnMessage(0x0200, handleAllGUI_toolTips)
    ; Causes VideoDownloader to react upon toast notification events.
    OnMessage(0x404, handleAllApplication_toastNotifications_onClick)
}

/*
FUNCTION SECTION
-------------------------------------------------
*/

; This function determines the current control under the mouse cursor and if it has a tooltip, displays it.
handleAllGUI_toolTips(wParam, lParam, msg, hwnd) {
    static oldHWND := 0
    if (hwnd != oldHWND) {
        ; Closes all existing tooltips.
        toolTipText := ""
        ToolTip()
        /*
        This is an exception for the settingsGUIVideoDesiredSubtitleComboBox's edit element.
        It makes sure that the tooltip is displayed when the user hovers over the edit as well.
        */
        if (IsSet(settingsGUIVideoDesiredSubtitleComboBox)
        && settingsGUIVideoDesiredSubtitleComboBox.HasOwnProp("EditHwnd")
        && hwnd == settingsGUIVideoDesiredSubtitleComboBox.EditHwnd) {
            currentControlElement := Object()
            currentControlElement.Hwnd := settingsGUIVideoDesiredSubtitleComboBox.EditHwnd
            currentControlElement.ToolTip := settingsGUIVideoDesiredSubtitleComboBox.ToolTip
        }
        else {
            currentControlElement := GuiCtrlFromHwnd(hwnd)
        }
        if (currentControlElement) {
            if (!currentControlElement.HasProp("ToolTip")) {
                ; There is no tooltip for this control element.
                return
            }
            toolTipText := currentControlElement.ToolTip
            ; Displays the tooltip after the user hovers for 1.5 seconds over a control element.
            SetTimer () => displayToolTip(toolTipText, currentControlElement.Hwnd), -1500
        }
        oldHWND := hwnd
    }
    /*
    This function makes sure that the tooltip is only displayed when the user hovers over the same control element for
    more than 1.5 seconds. If the control element under the cursor changes by any means, the tooltip won't be displayed.
    */
    displayToolTip(pToolTipText, pCurrentControlElementHWND) {
        MouseGetPos(, , , &currentControlElementUnderCursorHWND, 2)
        if (pCurrentControlElementHWND == currentControlElementUnderCursorHWND) {
            ToolTip(pToolTipText)
        }
    }
}

; This function reacts upon the user left-clicking on a toast notification.
handleAllApplication_toastNotifications_onClick(wParam, lParam, msg, hwnd) {
    global currentYTDLPActionObject

    ; Ignore messages from other applications and all events that are not a left click.
    if (hwnd != A_ScriptHwnd || lParam != 1029) {
        ; Tells Windows to process this message further.
        return
    }
    /*
    This technically works for every toast notification from VideoDownloader,
    but it is meant for the finished download notification.
    */
    if (IsSet(currentYTDLPActionObject) && DirExist(currentYTDLPActionObject.latestDownloadDirectory)) {
        openDirectoryInExplorer(currentYTDLPActionObject.latestDownloadDirectory)
    }
}

/*
Executes a given command with the yt-dlp executable.
@param pYTDLPCommandString [String] The yt-dlp command to execute.
@param pLogFileLocation [String] An optional full path to a log file which will contain the output.
@returns [int] The PID of the yt-dlp process.
@returns (alt) [String] "_result_error_while_starting_ytdlp_executable", when the yt-dlp executable failed to launch.
*/
executeYTDLPCommand(pYTDLPCommandString, pLogFileLocation := A_Temp . "\yt-dlp.log",
    pErrorLogFileLocation := A_Temp . "\yt-dlp_errors.log") {
    global psRunYTDLPExecutableLocation
    global YTDLPFileLocation

    ; Replaces all single quotation marks with tripple quoation marks to make the string compatible with PowerShell.
    formattedYTDLPCommandString := StrReplace(pYTDLPCommandString, '"', '"""')

    commandString := 'powershell.exe -executionPolicy bypass -file "' . psRunYTDLPExecutableLocation . '" '
    commandString .= '-pYTDLPExecutableFileLocation "' . YTDLPFileLocation . '" '
    commandString .= '-pYTDLPLogFileLocation "' . pLogFileLocation . '" '
    commandString .= '-pYTDLPErrorLogFileLocation "' . pErrorLogFileLocation . '" '
    commandString .= '-pYTDLPCommandString "' . formattedYTDLPCommandString . '"'

    exitCode := RunWait(commandString, , "Hide")
    if (exitCode == 1) {
        ; Recreates the log file path because the application will put the log file in the same directory as itself.
        psRunYTDLPExecutableLocationLogFileLocation := StrReplace(psRunYTDLPExecutableLocation, ".ps1", ".log")
        errorExtraMessage := "The following log files might provide more information:`n`n"
        errorExtraMessage .= "[" . psRunYTDLPExecutableLocationLogFileLocation . "]`n"
        errorExtraMessage .= "[" . pLogFileLocation . "]`n"
        errorExtraMessage .= "[" . pErrorLogFileLocation . "]"
        errorObject := Error("Failed to run yt-dlp executable with redirected stdout.", , errorExtraMessage)
        errorObject.File := psRunYTDLPExecutableLocation
        errorObject.Line := "No line information required."
        errorObject.Stack := "No call stack required."
        displayErrorMessage(errorObject,
            "Please report this error and provide the information from the log files mentioned above. Thank you!")
        return "_result_error_while_starting_ytdlp_executable"
    }
    else {
        return exitCode
    }
}

/*
Reads the download log file during the download process. The progress will be displayed in the video list GUI.
@param pYTDLPProcessPID [int] The PID of the yt-dlp process downloading the video.
@param pYTDLPLogFileLocation [int] The location of the log file that the yt-dlp process writes to.
@param pCurrentlyDownloadedVideoTitle [int] The title of the currently downloaded video.
*/
monitorVideoDownloadProgress(pYTDLPProcessPID, pYTDLPLogFileLocation, pCurrentlyDownloadedVideoTitle) {
    global currentYTDLPActionObject

    ; The phases will be marked with a tracking point line in the yt-dlp log file.
    static booleanPhaseReached_pre_process := false
    static booleanPhaseReached_after_filter := false
    static booleanPhaseReached_video := false
    static booleanPhaseReached_before_dl := false
    static booleanPhaseReached_post_process := false
    static booleanPhaseReached_after_move := false
    static booleanPhaseReached_after_video := false
    ; These values represent the download progress for the video and it's corresponding audio track.
    static videoDownloadProgress := 0
    static audioDownloadProgress := 0
    ; These values are important for the parseYTDLPLogFile() function.
    static previousProgressPerecentage := 0
    static parsedLines := 0

    ; Updates the downloaded video progress text.
    downloadProgressText.Value := "Downloaded (" . currentYTDLPActionObject.alreadyDownloadedVideoAmount . " / " .
        currentYTDLPActionObject.completeVideoAmount . ") - [" . currentYTDLPActionObject.remainingVideos .
        "] Remaining"
    ; Resets the download progress bar.
    downloadProgressBar.Value := 0

    SetTimer(updateDownloadProgressStep, 1000)
    ; This function is called every second to update the download progress GUI elements.
    updateDownloadProgressStep() {
        ; Stops the monitoring because the yt-dlp executable delivering new progress is no longer running.
        if (!ProcessExist(pYTDLPProcessPID)) {
            SetTimer(updateDownloadProgressStep, 0)
            downloadProgressBar.Value := 100
            ; Updates the downloaded video progress text.
            downloadProgressText.Value := "Downloaded (" . currentYTDLPActionObject.alreadyDownloadedVideoAmount .
                " / " .
                currentYTDLPActionObject.completeVideoAmount . ") - [" . currentYTDLPActionObject.remainingVideos .
                "] Remaining"
            ; Resets all relevant values for the next download.
            booleanPhaseReached_pre_process := false
            booleanPhaseReached_after_filter := false
            booleanPhaseReached_video := false
            booleanPhaseReached_before_dl := false
            booleanPhaseReached_post_process := false
            booleanPhaseReached_after_move := false
            booleanPhaseReached_after_video := false
            videoDownloadProgress := 0
            audioDownloadProgress := 0
            previousProgressPerecentage := 0
            parsedLines := 0
        }
        else {
            parseYTDLPLogFile()
            downloadProgressBar.Value := calculateDownloadProgressBarValue()
            currentTotalDownloadProgress := calculateTaskbarProgressBarValue(downloadProgressBar.Value)
            totalDownloadProgressMax := currentYTDLPActionObject.completeVideoAmount * 100
            ; Updates the taskbar progress bar with the current total download progress.
            setProgressOnTaskbarApplication(videoListGUI.Hwnd, 2, currentTotalDownloadProgress,
                totalDownloadProgressMax)
        }
    }
    ; This function parses the yt-dlp log file and extracts the relevant information to track the download process.
    parseYTDLPLogFile() {
        loop read (pYTDLPLogFileLocation) {
            ; All previous lines will be skipped.
            if (parsedLines >= A_Index) {
                continue
            }
            parsedLines++
            /*
            Checks the log file for any of the tracking point lines below.
            These will be printed by yt-dlp depending on the overall download progression.
            -------------------------------------------------
            */
            trackingLine :=
                "[PROGRESS_INFO_PRE_PROCESS] [Tracking Point: Video information has been extracted.]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_pre_process := true
                statusBarText := "[" . pCurrentlyDownloadedVideoTitle . "] - Processing video information..."
                handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_AFTER_FILTER] [Tracking Point: Video has passed the format filter.]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_after_filter := true
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_VIDEO] [Tracking Point: Starting download of subtitle and other requested files...]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_video := true
                statusBarText := "[" . pCurrentlyDownloadedVideoTitle .
                    "] - Downloading video subtitle(s) and other requested files..."
                handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_BEFORE_DL] [Tracking Point: Starting video download...]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_before_dl := true
                statusBarText := "[" . pCurrentlyDownloadedVideoTitle . "] - Downloading video..."
                handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_POST_PROCESS] [Tracking Point: All relevant files have been downloaded. Starting video post processing...]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_post_process := true
                statusBarText := "[" . pCurrentlyDownloadedVideoTitle . "] - Post processing downloaded video..."
                handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_AFTER_MOVE] [Tracking Point: Video has been post processed and moved.]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_after_move := true
                statusBarText := "[" . pCurrentlyDownloadedVideoTitle . "] - Finishing video post processing..."
                handleVideoListGUI_videoListGUIStatusBar_startAnimation(statusBarText)
                continue
            }
            trackingLine :=
                "[PROGRESS_INFO_AFTER_VIDEO] [Tracking Point: The video download process has been finished.]"
            if (InStr(A_LoopReadLine, trackingLine)) {
                booleanPhaseReached_after_video := true
                continue
            }
            /*
            Extracts the download progress for the video file and it's corresponding audio track.
            -------------------------------------------------
            */
            ; This tracking point must occur in order to be able to track the video (and audio) download progress.
            if (!booleanPhaseReached_before_dl) {
                continue
            }
            /*
            Scans the output from the yt-dlp executable and extracts the download progress percentage values.
            As yt-dlp usually downloads the video file first, this will most likely be the video download progress.
            */
            if (RegExMatch(A_LoopReadLine, "S)[\d]+[.][\d{1}][%]", &outMatch) && videoDownloadProgress != 100) {
                outString := outMatch[]
                outStringReady := StrReplace(outString, "%")
                extractedPercentage := Number(outStringReady)
                extractedPercentage := Round(extractedPercentage, 2)
                /*
                Checks if the extracted perentage is bigger than the previously extracted number.
                Otherwise the progress bar might move backwards.
                */
                if (extractedPercentage <= 100 && extractedPercentage > previousProgressPerecentage) {
                    /*
                    This is another safety guard. If yt-dlp outputs a progress number which is way to high,
                    this condition will sort that out. For example, if the download progress is at 4% and suddenly
                    there is a 100% in the log file. This would be discarded as the difference is to high.
                    */
                    if ((extractedPercentage - previousProgressPerecentage) >= 80) {
                        continue
                    }
                    previousProgressPerecentage := extractedPercentage
                    videoDownloadProgress := extractedPercentage
                    if (videoDownloadProgress == 100) {
                        ; Resets the previous progress percentage for the audio download.
                        previousProgressPerecentage := 0
                    }
                }
                continue
            }
            /*
            This makes sure, that the video has already been downloaded.
            Usually at this point, yt-dlp will download the corresponding audio track.
            This means the progress will most likely be the audio track download progress.
            */
            static booleanWaitForVideoDestinationString := true
            if (booleanWaitForVideoDestinationString && videoDownloadProgress == 100
                && InStr(A_LoopReadLine, "[download] Destination: ")) {
                booleanWaitForVideoDestinationString := false
            }
            else {
                continue
            }
            ; Scans the output from the yt-dlp executable and extracts the download progress percentage values.
            if (RegExMatch(A_LoopReadLine, "S)[\d]+[.][\d{1}][%]", &outMatch) && audioDownloadProgress != 100) {
                outString := outMatch[]
                outStringReady := StrReplace(outString, "%")
                extractedPercentage := Number(outStringReady)
                extractedPercentage := Round(extractedPercentage, 2)
                /*
                Checks if the extracted perentage is bigger than the previously extracted number.
                Otherwise the progress bar might move backwards.
                */
                if (extractedPercentage <= 100 && extractedPercentage > previousProgressPerecentage) {
                    /*
                    This is another safety guard. If yt-dlp outputs a progress number which is way to high,
                    this condition will sort that out. For example, if the download progress is at 4% and suddenly
                    there is a 100% in the log file. This would be discarded as the difference is to high.
                    */
                    if ((extractedPercentage - previousProgressPerecentage) >= 80) {
                        continue
                    }
                    previousProgressPerecentage := extractedPercentage
                    audioDownloadProgress := extractedPercentage
                }
                continue
            }
        }
    }
    /*
    It also calculates the overall progress of the video download to display it via a progress bar.
    @returns [int] The overall download progress percentage (0-100).
    */
    calculateDownloadProgressBarValue() {
        totalDownloadProgressBarValue := 0
        /*
        The phases will be marked with a tracking point line in the yt-dlp log file. If the value of a phase is true,
        which means yt-dlp has completed this phase, it will increase the progress bar value by 5.
        The progress bar has a maximum value of 100. This means that 30% of it will be filled by completing
        the phases and the remaining 70% will be filled with the actual download progress from the log file.
        */
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_pre_process
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_after_filter
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_video
        ; The phase "booleanPhaseReached_before_dl" is skipped because the progress will be read from the log file instead.
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_post_process
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_after_move
        totalDownloadProgressBarValue += 5 * booleanPhaseReached_after_video
        /*
        Adds the actual download progress from the log file. Per default, yt-dlp downloads the video and audio separately.
        60% of the progress bar will be filled by completing the download of the video.
        The remaining 10% can be filled by completing the download of the video's audio track.
        */
        totalDownloadProgressBarValue += 0.6 * videoDownloadProgress
        totalDownloadProgressBarValue += 0.1 * audioDownloadProgress
        return Round(totalDownloadProgressBarValue, 2)
    }
    /*
    Calculates the overall progress of all videos that are currently being downloaded.
    @returns [int] The overall progress percentage. The range depends on the total amount of videos to download.
    For example, if there are 10 videos, the range would be 0-1000.
    */
    calculateTaskbarProgressBarValue(pCurrentVideoProgressPercentage) {
        ; Calculates how many vidoes have been downloaded or skipped in total.
        alreadyReachedPercentage :=
            (currentYTDLPActionObject.completeVideoAmount - currentYTDLPActionObject.remainingVideos) * 100
        currentPercentage := alreadyReachedPercentage + pCurrentVideoProgressPercentage
        return currentPercentage
    }
}

/*
Shows a progress animation for the specified window in the taskbar.
@param pWindowHwnd [int] The handle of the window to show the progress animation for.
@param pState [int] The state of the progress animation. Possible values are:
    - TBPF_NOPROGRESS (0): No progress.
    - TBPF_INDETERMINATE (1): Indeterminate progress.
    - TBPF_NORMAL (2): Normal progress.
    - TBPF_ERROR (4): Error progress.
    - TBPF_PAUSED (8): Paused progress.
@param pAlreadyCompletedPercentage [int] (optional) The percentage of progress that has already been completed.
@param pTotalPercentage [int] (optional) The total percentage of progress. Default is 100.
Original code sourced from https://www.autohotkey.com/boards/viewtopic.php?p=568827&sid=b4da45941d62ee0d21025ec23c22a067#p568827.
*/
setProgressOnTaskbarApplication(pWindowHwnd, pState := 0, pAlreadyCompletedPercentage?, pTotalPercentage := 100) {
    static CLSID_TaskbarList := '{56FDF344-FD6D-11d0-958A-006097C9A090}'
    static IID_ITaskbarList3 := '{EA1AFB91-9E28-4B86-90E9-9E9F8A5EEFAF}'
    static ITaskbarList3 := ComObject(CLSID_TaskbarList, IID_ITaskbarList3)

    ; Start the progress animation.
    ComCall(SetProgressState := 10, ITaskbarList3, 'Ptr', pWindowHwnd, 'UInt', pState)
    ; Starts the progress animation with an already completed amount of progress.
    if (IsSet(pAlreadyCompletedPercentage)) {
        ComCall(SetProgressValue := 9, ITaskbarList3, 'Ptr', pWindowHwnd, 'Int64', pAlreadyCompletedPercentage, 'Int64',
            pTotalPercentage)
    }
}

/*
This function will try to extract the video meta data from any given URL and add the video to the video list.
@param pVideoURL [String] Should be a valid URL from a video.
@returns [Array] A status code which is the first element in the array.
The array might have different values at other indexes depending on the status code at the first index
*/
createVideoListViewEntry(pVideoURL) {
    global videoListViewContentMap
    ; This object will store the information about the given video URL.
    extractedVideoMetaDataObject := extractVideoMetaData(pVideoURL)
    extractedVideoIdentifierString := extractedVideoMetaDataObject.VIDEO_TITLE . extractedVideoMetaDataObject.VIDEO_UPLOADER .
        extractedVideoMetaDataObject.VIDEO_DURATION_STRING
    ; Parses through all entries in the video list.
    for (identifierString, videoListEntry in videoListViewContentMap) {
        if (identifierString == extractedVideoIdentifierString) {
            returnArray := ["_result_video_already_in_list", extractedVideoMetaDataObject.VIDEO_TITLE]
            return returnArray
        }
    }
    ; Adds the video to the list.
    VideoListViewEntry(extractedVideoMetaDataObject)
    return ["_result_video_added_to_list"]
}

/*
Imports URLs from a text file which must contain one URL per line.
@param pImportFileLocation [String] The location of the URL file.
@param pBooleanSkipInvalidURLs [boolean] If set to true, all invalid URLs will automatically not be imported.
*/
importVideoListViewElements(pImportFileLocation, pBooleanSkipInvalidURLs := false) {
    validURLArray := Array()
    invalidURLArray := Array()
    loop read (pImportFileLocation) {
        ; Comments will be skipped.
        if (InStr(A_LoopReadLine, "#")) {
            continue
        }
        ; Sorts out all invalid URLs and saves them in the array.
        if (!checkIfStringIsAValidURL(A_LoopReadLine)) {
            invalidURLArray.Push(A_LoopReadLine)
            continue
        }
        validURLArray.Push(A_LoopReadLine)
    }

    if (invalidURLArray.Length > 0 && !pBooleanSkipInvalidURLs) {
        ; Asks the user if they would like to import the invalid URLs (if there are any).
        if (invalidURLArray.Length == 1) {
            msgText := "There is [1] invalid URL in the file [" . pImportFileLocation . "]."
            msgText .= "`n`nWould you like to import it anyway?"
            msgTitle := "VD - Invalid URL Found"
            msgHeadLine := "Import Invalid URL?"
            msgButton1 := "Import Invalid URL"
            msgButton2 := ""
            msgButton3 := "Exclude Invalid URL"
        }
        else {
            msgText := "There are [" . invalidURLArray.Length . "] invalid URLs in the file ["
                . pImportFileLocation . "]."
            msgText .= "`n`nWould you like to import them anyway?"
            msgTitle := "VD - Invalid URLs Found"
            msgHeadLine := "Import Invalid URLs?"
            msgButton1 := "Import Invalid URLs"
            msgButton2 := ""
            msgButton3 := "Exclude Invalid URLs"
        }
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true,
            videoListGUI)
        ; If the users wishes, the invalid URLs will be imported as well.
        if (result == msgButton1) {
            for (invalidURL in invalidURLArray) {
                validURLArray.Push(invalidURL)
            }
        }
    }

    ; Creates new video list view entry objects with the given URLs.
    for (validURL in validURLArray) {
        url := validURL
        ; Removes the "invalid" marker. This gives the URL behind the marker a new "chance" to be found.
        url := StrReplace(url, "video_not_found: ")
        url := StrReplace(url, "playlist_not_found: ")
        VideoListViewEntry(url)
        ; Prevents the status bar animation from glitching out.
        Sleep(100)
    }
    statusBarText := "Finished importing " . validURLArray.Length . " URLs"
    videoListGUIStatusBar.SetText(statusBarText)
}

/*
Exports all video list view elements in the given map to a text file.
@param pVideoListViewElementMap [Map] A map filled with video list view elements to export.
@param pExportFileLocation [String] An optional file path to save the exported URLs.
If not provided, the user will be prompted to select a save location.
@param pBooleanSkipInvalidURLs [boolean] If set to true, all invalid URLs will automatically not be exported.
*/
exportVideoListViewElements(pVideoListViewElementMap, pExportFileLocation?, pBooleanSkipInvalidURLs := false) {
    global videoListViewContentMap

    ; It does not make sense to start an with an empty map.
    if (pVideoListViewElementMap.Count == 0) {
        return
    }

    validURLArray := Array()
    invalidURLArray := Array()
    for (key, videoListEntry in pVideoListViewElementMap) {
        ; Skips all internal video list view entries used to communicate with the user.
        if (videoListEntry.videoURL == "_internal_entry_no_results_found" || videoListEntry.videoURL ==
            "_internal_entry_no_videos_added_yet") {
            continue
        }
        ; Sorts out all invalid URLs and saves them in the array.
        if (!checkIfStringIsAValidURL(videoListEntry.videoURL)) {
            invalidURLArray.Push(videoListEntry.videoURL)
            continue
        }
        validURLArray.Push(videoListEntry.videoURL)
    }

    ; This happens when the user only selected invalid URLs but the option to ignore them is still enabled.
    if (pBooleanSkipInvalidURLs && validURLArray.Length == 0) {
        highlightedCheckbox := highlightControl(importAndExportOnlyValidURLsCheckbox)
        MsgBox("You only selected invalid URLs to export.`n`nDisable the checkbox [" .
            importAndExportOnlyValidURLsCheckbox.Text . "] to export invalid URLs.", "VD - Canceled URL Export",
            "O Icon! Owner" . videoListGUI.Hwnd)
        highlightedCheckbox.destroy()

        statusBarText := "Canceled URL export - There are no valid URLs to export"
        videoListGUIStatusBar.SetText(statusBarText)
        return
    }

    if (invalidURLArray.Length > 0 && !pBooleanSkipInvalidURLs) {
        ; Asks the user if they would like to include the invalid URLs (if there are any).
        if (invalidURLArray.Length == 1) {
            msgText := "There is [1] invalid URL in the list."
            msgText .= "`n`nWould you like to export it anyway?"
            msgTitle := "VD - Invalid URL Found"
            msgHeadLine := "Export Invalid URL?"
            msgButton1 := "Export Invalid URL"
            msgButton2 := ""
            msgButton3 := "Exclude Invalid URL"
        }
        else {
            msgText := "There are [" . invalidURLArray.Length . "] invalid URLs in the list."
            msgText .= "`n`nWould you like to export them anyway?"
            msgTitle := "VD - Invalid URLs Found"
            msgHeadLine := "Export Invalid URLs?"
            msgButton1 := "Export Invalid URLs"
            msgButton2 := ""
            msgButton3 := "Exclude Invalid URLs"
        }
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true,
            videoListGUI)
        ; If the user wishes, the invalid URLs will be included in the export.
        if (result == msgButton1) {
            ; Adds the separation line into the array.
            validURLArray.Push("# ********************`n# Invalid URLs below.`n# ********************")
            ; Includes the invalid URLs in the export.
            for (invalidURL in invalidURLArray) {
                validURLArray.Push(invalidURL)
            }
        }
    }

    for (validURL in validURLArray) {
        exportFileContent .= validURL . "`n"
    }
    ; Removing the separator line must be done in a separate for loop.
    for (validURL in validURLArray) {
        if (validURL == "# ********************`n# Invalid URLs below.`n# ********************") {
            ; Removes the separation line to correct the amount of exported URLs (which is the length of the array).
            validURLArray.RemoveAt(A_Index)
        }
    }

    ; Checks if there are any URLs to export. Sometimes there are only invalid URLs and the user decides to exclude them.
    if (!isSet(exportFileContent)) {
        MsgBox("There are no valid URLs to export.", "VD - Canceled URL Export",
            "O Icon! T3 Owner" . videoListGUI.Hwnd)
        statusBarText := "Canceled URL export - There are no valid URLs to export"
        videoListGUIStatusBar.SetText(statusBarText)
        return
    }

    ; We use the current time stamp to generate a unique name for the exported file.
    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    if (!IsSet(pExportFileLocation)) {
        exportFileDefaultLocation := A_MyDocuments . "\" . currentTime . "_VD_exported_urls.txt"
        pExportFileLocation := fileSavePrompt("VD - Please select a save location for the URL file",
            exportFileDefaultLocation, "*.txt", videoListGUI)
        ; This usually happens, when the user cancels the selection.
        if (pExportFileLocation == "_result_no_file_save_location_selected") {
            return
        }
    }

    exportFileContent := RTrim(exportFileContent, "`n")
    exportFileContentFinal := "# ********************"
    exportFileContentFinal .= "`n# VideoDownloader URL Export - " . currentTime
    exportFileContentFinal .= "`n# Total URLs - " . validURLArray.Length
    exportFileContentFinal .= "`n# ********************`n"
    exportFileContentFinal .= exportFileContent

    ; "Overwrites" the existing file.
    if (FileExist(pExportFileLocation)) {
        FileDelete(pExportFileLocation)
    }
    try
    {
        FileAppend(exportFileContentFinal, pExportFileLocation)
    }
    catch as error {
        displayErrorMessage(error, "File writing errors are usually rare. Please report this!")
    }
    statusBarText := "Finished exporting " . validURLArray.Length . " URLs"
    videoListGUIStatusBar.SetText(statusBarText)
}

/*
Creates a map containing all currently selected video list view elements in the video list.
@Returns [Map] This map can contain no objects if no videos are currently selected.
*/
getSelectedVideoListViewElements() {
    global videoListViewContentMap

    selectedItemsIdentifierStringArray := Array()
    selectedVideoListViewElementsMap := Map()

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
    for (identifierString in selectedItemsIdentifierStringArray) {
        if (!videoListViewContentMap.Has(identifierString)) {
            continue
        }
        ; Retrieves the video list view element from the content map and adds it to the selected entries map.
        videoListEntry := videoListViewContentMap.Get(identifierString)
        ; Skips all internal video list view entries used to communicate with the user.
        if (videoListEntry.videoURL == "_internal_entry_no_results_found" || videoListEntry.videoURL ==
            "_internal_entry_no_videos_added_yet") {
            continue
        }
        selectedVideoListViewElementsMap.Set(identifierString, videoListEntry)
    }
    return selectedVideoListViewElementsMap
}

/*
Reads the version information from the application executable file (if compiled).
@returns [String] The version from the executable or "v0.0.0.1" in case the application is not compiled.
*/
getCorrectScriptVersion() {
    if (!A_IsCompiled) {
        fileVersion := "v0.0.0.1"
    }
    else {
        try {
            ; Extract the version from the executable file.
            fileVersion := "v" . FileGetVersion(A_ScriptFullPath)
        }
        catch {
            ; Used as a fallback.
            fileVersion := "v0.0.0.2"
        }
    }
    ; Finds versions matching this format [v1.2.3.4]
    if (RegExMatch(fileVersion, "^v\d+\.\d+\.\d+\.(\d+)$", &match)) {
        buildVersionNumber := match[1]
        ; A version number with a build version is only used for beta versions.
        if (buildVersionNumber != 0) {
            fileVersion := fileVersion . "-beta"
        }
        return fileVersion
    }
    ; Finds versions matching this format [v1.2.3], [v1.2.3-beta], [1.2.3] or [1.2.3-beta].
    else if (RegExMatch(fileVersion, "^v?\d+\.\d+\.\d+(\.\d+)?(-beta)?$")) {
        return fileVersion
    }
    else {
        ; In case the version from the compiled file is invalid.
        fileVersion := "v0.0.0.3"
    }
    return fileVersion
}

/*
Extracts a comma seperated string and creates an array. Empty and duplicate entries will be ignored.
@param pConfigFileEntry [String] The config file entry to read from.
@returns [Array] An array containing the entries from the config file. The array can be empty.
*/
getCsvArrayFromConfigFile(pConfigFileEntry) {
    ; The string is stored in the config file as a comma separated list.
    configArray := StrSplit(readConfigFile(pConfigFileEntry), ",", " `t")
    returnArray := Array()
    ; Removes empty and duplicate entries from the array.
    for (entry in configArray) {
        if (entry == "" || checkIfStringIsInArray(entry, returnArray)) {
            continue
        }
        returnArray.Push(entry)
    }
    return returnArray
}

/*
Writes a given array to the config file as a comma separated string.
@param pConfigFileEntry [String] The config file entry to write to.
@param pArray [Array] The array to write to the config file.
*/
writeCsvArrayToConfigFile(pConfigFileEntry, pArray) {
    arrayString := ""
    ; Converts the array into a string and writes it to the config file.
    for (entry in pArray) {
        arrayString .= entry . ","
    }
    arrayString :=
        RTrim(arrayString, ",")
    editConfigFile(arrayString, pConfigFileEntry)
}

/*
Parses a string containing language data and returns a Map with language names as keys and language codes as values.
@param pRawString [String] The raw string containing the language data.
@returns [Map] A map where the keys are language names and the values are language codes.
*/
parseYTDLPSubtitleString(pRawString) {
    languageCodeMap := Map()
    parts := StrSplit(pRawString, "%=%")

    for (i, part in parts) {
        if (i = 1) {
            ; Skip the table header.
            continue
        }
        part := Trim(part)
        if (RegExMatch(part, "^\s*(\S+)\s+([^\d,]+?)\s+(?:vtt|ttml|srv3|srv2|srv1|json3)", &match)) {
            languageCode := Trim(match[1])
            languageName := Trim(match[2])
            ; This avoids empty language names.
            if (languageName) {
                languageCodeMap[languageName] := languageCode
            }
        }
    }
    return languageCodeMap
}

; Tries to find currently running instances of the application and warns the user about it.
findAlreadyRunningVDInstance() {
    ; Searches for the process name and excludes this instance.
    query := 'SELECT * FROM Win32_Process WHERE Name = "VideoDownloader.exe"'
    childProcesses := ComObjGet("winmgmts:").ExecQuery(query)

    for (childProcess in childProcesses) {
        ; Skipts this instance of the application.
        if (childProcess.ExecutablePath == A_ScriptFullPath) {
            continue
        }
        askUserToTerminateOtherInstance(childProcess)
    }
    askUserToTerminateOtherInstance(pProcessObject) {
        processName := pProcessObject.Name
        processPath := pProcessObject.ExecutablePath
        msgText := "Another instance of VideoDownloader is already running."
        msgText .= "`n`n********************"
        msgText .= "`nName: [" . processName . "]"
        msgText .= "`nPath: [" . processPath . "]"
        msgText .= "`n********************"
        msgText .= "`n`nRunning multiple instances can cause unpredictable issues."
        msgText .= "`n`nContinue at your own risk."
        msgTitle := "VD - Multiple Instances Found!"
        msgHeadLine := "Multiple Instances Found!"
        msgButton1 := "Continue"
        msgButton2 := "Abort"
        msgButton3 := "Terminate Other Instance"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)

        switch (result) {
            case msgButton3:
            {
                try
                {
                    ProcessClose(pProcessObject.ProcessId)
                }
                catch as error {
                    errorAdditionalMessage :=
                        "The process might be elevated (which means it was launched with higher permissions)."
                    displayErrorMessage(error, errorAdditionalMessage, true)
                }
            }
            case msgButton1:
            {
                ; This option is not recommended because the application is not supposed to run with multiple instances active.
                return
            }
            default:
            {
                exitApplicationWithNotification(true)
            }
        }
    }
}

/*
This function will close every child process with that corresponding parent's process ID.
@param pParentProcessPID [int] The PID of the process which started the child processes.
@param pChildProcessNameFilter [String] An optional filter e.g. "yt-dlp.exe"
@param pBooleanRecursive [boolean] If set to true, will terminate all child processes of the child processes.
For safety and performance reasons, this will only go one layer deeper and stop after that.
*/
terminateAllChildProcesses(pParentProcessPID, pChildProcessNameFilter?, pBooleanRecursive := false) {
    ; Searches for the process name and the matching parent process id.
    query := 'SELECT * FROM Win32_Process WHERE ParentProcessId = "' . pParentProcessPID . '" '
    if (IsSet(pChildProcessNameFilter)) {
        query .= 'AND Name = "' . pChildProcessNameFilter . '"'
    }
    childProcesses := ComObjGet("winmgmts:").ExecQuery(query)

    for (childProcess in childProcesses) {
        if (pBooleanRecursive) {
            ; For safety reasons, this request will not be recursive.
            terminateAllChildProcesses(childProcess.ProcessId)
        }
        try
        {
            ProcessClose(childProcess.ProcessId)
        }
        catch as error {
            errorAdditionalMessage :=
                "The process might be elevated (which means it was launched with higher permissions)."
            displayErrorMessage(error, errorAdditionalMessage)
        }
    }
}

/*
Copies all files from the old version into a backup folder using robocopy.
@param pBackupParentDirectory [String] Usually the application directory with an additional folder called "VideoDownloader_old_version_backups" at the end.
*/
backupOldVersionFiles(pBackupParentDirectory) {
    global versionFullName

    oldVersion := versionFullName
    backupDate := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    backupFolderName := "VideoDownloader_backup_from_version_" . oldVersion . "_at_" . backupDate
    sourceDirectory := A_ScriptDir
    destinationDirectory := pBackupParentDirectory . "\" . backupFolderName
    /*
    All subdirectories and files are copied. The folder "VideoDownloader_old_version_backups" is excluded.
    All download related folders and temporary directories will be excluded.
    Files larger than 10MB will be ignored as well.
    */
    downloadFolder := readConfigFile("DEFAULT_DOWNLOAD_DIRECTORY")
    downloadFolderTemp := readConfigFile("TEMP_DOWNLOAD_DIRECTORY")
    generalTempFolder := readConfigFile("TEMP_DIRECTORY")
    ; Build the paramter string for the robocopy executable.
    parameterString := "`"" . sourceDirectory . "`" `"" . destinationDirectory . "`" /E "
    parameterString .= "/XD `"" . sourceDirectory . "\VideoDownloader_old_version_backups`" "
    parameterString .= "`"" . downloadFolder . "`" "
    parameterString .= "`"" . downloadFolderTemp . "`" "
    parameterString .= "`"" . generalTempFolder . "`" "
    parameterString .= "/MAX:10485760"

    ; Waits 3 seconds before starting the backup process to ensure that the main application has exited already.
    Run('cmd.exe /c "timeout /t 3 /nobreak && robocopy ' . parameterString . '"', , "Hide")
    exitApplicationWithNotification()
}

; Gets the current position, size and maximized/minimized state of the video list GUI and saves it to the config file.
saveCurrentVideoListGUIStateToConfigFile() {
    if (!IsSet(videoListGUI) || !WinExist("ahk_id" . videoListGUI.Hwnd
        || !readConfigFile("REMEMBER_LAST_VIDEO_LIST_GUI_POSITION_AND_SIZE"))) {
        return
    }

    videoListGUI.GetPos(&x, &y)
    ; We need to use GetClientPos() because the Show() function defines the client width and height.
    videoListGUI.GetClientPos(, , &width, &height)
    windowStateString := "x" . x . " y" . y . " w" . width . " h" . height
    state := WinGetMinMax("ahk_id " . videoListGUI.Hwnd)
    switch (state) {
        case -1:
        {
            ; We need to generate a new string because minimized windows return invalid coordinates.
            windowStateString := "w" . width . " h" . height . " Minimize"
        }
        case 1:
        {
            windowStateString .= " Maximize"
        }
    }
    ; Saves the current video list GUI state to the config file.
    editConfigFile(windowStateString, "REMEMBER_LAST_VIDEO_LIST_GUI_POSITION_AND_SIZE_VALUES")
}

; Shows the video list GUI with the saved position state data from the config file.
showVideoListGUIWithSavedStateData() {
    if (!readConfigFile("REMEMBER_LAST_VIDEO_LIST_GUI_POSITION_AND_SIZE")) {
        videoListGUI.Show("AutoSize")
        return
    }

    windowStateString := readConfigFile("REMEMBER_LAST_VIDEO_LIST_GUI_POSITION_AND_SIZE_VALUES")
    ; Checks if the video list GUI is already in the correct position to avoid flickering.
    videoListGUIHwndString := "ahk_id " . videoListGUI.Hwnd
    if (WinExist(videoListGUIHwndString)) {
        videoListGUI.GetPos(&x, &y)
        ; We need to use GetClientPos() because the Show() function defines the client width and height as well.
        videoListGUI.GetClientPos(, , &width, &height)
        currentWindowStateString := "x" . x . " y" . y . " w" . width . " h" . height
        state := WinGetMinMax("ahk_id " . videoListGUI.Hwnd)
        switch (state) {
            case -1:
            {
                ; We need to generate a new string because minimized windows return invalid coordinates.
                currentWindowStateString := "w" . width . " h" . height . " Minimize"
            }
            case 1:
            {
                currentWindowStateString .= " Maximize"
            }
        }
        ; The video list GUI is already in the correct position.
        if (currentWindowStateString == windowStateString) {
            return
        }
    }
    try {
        videoListGUI.Show(windowStateString)
    }
    catch {
        videoListGUI.Show("AutoSize")
        saveCurrentVideoListGUIStateToConfigFile()
    }
}

/*
Positions the given relative GUI in 1 out of 9 possible positions relative to the base GUI.
@param pBaseGUI [Gui] The base GUI which will be used to position the relative GUI.
@param pRelativeGUI [Gui] The relative GUI which will be positioned.
@param pPosition [String] The position of the relative GUI. Possible values are:
    "TopLeftCorner", "TopMiddleCenter", "TopRightCorner",
    "MiddleLeftCorner", "MiddleCenter", "MiddleRightCorner",
    "BottomLeftCorner", "BottomMiddleCenter", "BottomRightCorner"
@param pAdditonalShowParameters [String] Additional show parameters for the relative GUI. For example, "AutoSize".
*/
showGUIRelativeToOtherGUI(pBaseGUI, pRelativeGUI, pPosition, pAdditonalShowParameters?) {
    baseGUIHwndString := "ahk_id " . pBaseGUI.Hwnd
    realtiveGUIHwndString := "ahk_id " . pRelativeGUI.Hwnd
    ; Gather information about the base GUI which will be used to position the relative GUI.
    if ((!WinExist(baseGUIHwndString)) || (WinGetMinMax(baseGUIHwndString) == -1)) {
        ; Shows the GUI hidden which allows the x and y coordinates to have valid values.
        pBaseGUI.Show("NoActivate")
    }
    /*
    We can't use pBaseGUI.GetPos() here because it would output wrong coordinates
    when the screen is scaled in the Windows display settings.
    */
    WinGetPos(&baseX, &baseY, &baseWidth, &baseHeight, baseGUIHwndString)
    ; Get the information about the relative GUI.
    if ((!WinExist(realtiveGUIHwndString)) || (WinGetMinMax(realtiveGUIHwndString) == -1)) {
        ; Shows the GUI hidden which allows the x and y coordinates to have valid values.
        pRelativeGUI.Show("NoActivate")
    }
    /*
    We can't use pRelativeGUI.GetPos() here because it would output wrong coordinates
    when the screen is scaled in the Windows display settings.
    */
    WinGetPos(&relativeX, &relativeY, &relativeWidth, &relativeHeight, realtiveGUIHwndString)

    ; Keep a small distance to the edge of the base GUI.
    baseMarginX := 20
    if (WinGetMinMax("ahk_id " . pBaseGUI.Hwnd) == 1) {
        ; The y margin must be 10 pixels larger to keep the same distance when the base GUI is maximized.
        baseMarginYTop := 30
        baseMarginYBottom := 20
    }
    else {
        baseMarginYTop := 20
        baseMarginYBottom := 20
    }

    switch (pPosition) {
        case "TopLeftCorner":
        {
            newX := baseX + baseMarginX
            newY := baseY + baseMarginYTop
        }
        case "TopMiddleCenter":
        {
            newX := baseX + (baseWidth - relativeWidth) / 2
            newY := baseY + baseMarginYTop
        }
        case "TopRightCorner":
        {
            newX := baseX + baseWidth - relativeWidth - baseMarginX
            newY := baseY + baseMarginYTop
        }
        case "MiddleLeftCorner":
        {
            newX := baseX + baseMarginX
            newY := baseY + (baseHeight - relativeHeight) / 2
        }
        case "MiddleCenter":
        {
            newX := baseX + (baseWidth - relativeWidth) / 2
            newY := baseY + (baseHeight - relativeHeight) / 2
        }
        case "MiddleRightCorner":
        {
            newX := baseX + baseWidth - relativeWidth - baseMarginX
            newY := baseY + (baseHeight - relativeHeight) / 2
        }
        case "BottomLeftCorner":
        {
            newX := baseX + baseMarginX
            newY := baseY + baseHeight - relativeHeight - baseMarginYBottom
        }
        case "BottomMiddleCenter":
        {
            newX := baseX + (baseWidth - relativeWidth) / 2
            newY := baseY + baseHeight - relativeHeight - baseMarginYBottom
        }
        case "BottomRightCorner":
        {
            newX := baseX + baseWidth - relativeWidth - baseMarginX
            newY := baseY + baseHeight - relativeHeight - baseMarginYBottom
        }
        default:
        {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid position received [" . pPosition . "] for relative GUI [" .
                pRelativeGUI.Title . "]", "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            return
        }
    }
    if (IsSet(pAdditonalShowParameters)) {
        ; Shows the relative GUI with the provided additional parameters.
        pRelativeGUI.Show("x" . newX . " y" . newY . " " . pAdditonalShowParameters)
        return
    }
    pRelativeGUI.Show("x" . newX . " y" . newY)
}

/*
Displays a customizable message box with up to 3 buttons and a headline.
@param pMsgBoxText [String] The main body text of the message box. [Max. 78 characters without line breaks (`n)]
@param pMsgBoxTitle [String] The title of the message box window. [Max. 48 characters]
@param pMsgBoxHeadLine [String] The headline text displayed at the top of the message box. [Max. 48 characters]
@param pButton1Text [String] The text for the leftmost button. [Max. 50 characters]
@param pButton2Text [String] The text for the middle button. Defaults to "Okay". [Max. 50 characters]
@param pButton3Text [String] The text for the rightmost button. [Max. 50 characters]
@param pMsgBoxTimeoutSeconds [int] Optional timeout in seconds. Closes the message box automatically after this duration.
@param pBooleanAlwaysOnTop [boolean] If true, the message box will always stay on top of other windows.
@param pOwnerGUI [Gui] An optional GUI object. This GUI will be the owner of the custom message box to make it modal.
@returns [String] The text of the button clicked by the user.
@returns (alt) [String] "_result_gui_closed" if the GUI was closed.
@returns (alt) [String] "_result_timeout" if the timeout was reached.
*/
customMsgBox(pMsgBoxText, pMsgBoxTitle := A_ScriptName, pMsgBoxHeadLine := A_ScriptName,
    pButton1Text?, pButton2Text := "Okay", pButton3Text?, pMsgBoxTimeoutSeconds?, pBooleanAlwaysOnTop := false,
    pOwnerGUI?) {
    ; This value represents either the user choice or any other possible outcome like a timeout for example.
    returnValue := "_result_gui_closed"
    ; Create the GUI which will mimic the style of a message box.
    if (IsSet(pOwnerGUI) && WinExist(pOwnerGUI.Hwnd)) {
        customMsgBoxGUI := Gui("Owner" . pOwnerGUI.Hwnd, pMsgBoxTitle)
        pOwnerGUI.Opt("+Disabled")
    }
    else {
        customMsgBoxGUI := Gui(, pMsgBoxTitle)
    }
    if (pBooleanAlwaysOnTop) {
        customMsgBoxGUI.Opt("+AlwaysOnTop")
    }
    ; Headline text.
    customMsgBoxGUIHeadLineText := customMsgBoxGUI.Add("Text", "xm ym w490 h40", pMsgBoxHeadLine)
    customMsgBoxGUIHeadLineText.SetFont("bold s12")
    ; A separator line.
    customMsgBoxGUIHeadLineSeparatorLineProgressBar := customMsgBoxGUI.Add("Progress", "xm-15 ym+25 w500 h5 cBlack")
    customMsgBoxGUIHeadLineSeparatorLineProgressBar.Value := 100
    ; MsgBox message text.
    customMsgBoxGUITextGroupBox := customMsgBoxGUI.Add("GroupBox", "xm ym+30 w470 h220")
    customMsgBoxGUIText := customMsgBoxGUI.Add("Text", "xp+10 yp+10 w450 h200", pMsgBoxText)
    ; Creates the buttons for the user to choose.
    if (IsSet(pButton1Text) && pButton1Text != "") {
        customMsgBoxGUIButton1 := customMsgBoxGUI.Add("Button", "xm ym+260 w150 h40", pButton1Text)
        customMsgBoxGUIButton1.OnEvent("Click", handleCustomMsgBoxGUI_button_onClick)
    }
    if (IsSet(pButton2Text) && pButton2Text != "") {
        customMsgBoxGUIButton2 := customMsgBoxGUI.Add("Button", "xm+160 ym+260 w150 h40 Default", pButton2Text)
        customMsgBoxGUIButton2.OnEvent("Click", handleCustomMsgBoxGUI_button_onClick)
    }
    if (IsSet(pButton3Text) && pButton3Text != "") {
        customMsgBoxGUIButton3 := customMsgBoxGUI.Add("Button", "xm+320 ym+260 w150 h40", pButton3Text)
        customMsgBoxGUIButton3.OnEvent("Click", handleCustomMsgBoxGUI_button_onClick)
    }
    ; Status bar.
    customMsgBoxGUIStatusBar := customMsgBoxGUI.Add("StatusBar", , "Please choose an option")
    customMsgBoxGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    customMsgBoxGUI.OnEvent("Close", handleCustomMsgBoxGUI_customMsgBoxGUI_onClose)

    if (IsSet(pOwnerGUI)) {
        showGUIRelativeToOtherGUI(pOwnerGUI, customMsgBoxGUI, "MiddleCenter", "w490")
    }
    else {
        customMsgBoxGUI.Show("w490")
    }
    ; OnEvent function for the buttons.
    handleCustomMsgBoxGUI_button_onClick(pButton, pInfo) {
        ; The text of the pressed button will be returned.
        returnValue := pButton.Text
        if (WinExist("ahk_id " . customMsgBoxGUI.Hwnd)) {
            WinClose()
        }
    }
    ; Makes sure that the owner GUI does not minimize.
    handleCustomMsgBoxGUI_customMsgBoxGUI_onClose(pGUI) {
        if (IsSet(pOwnerGUI)) {
            pOwnerGUI.Opt("-Disabled")
        }
    }
    ; The application waits until the user made a choice or the timer runs out.
    if (IsSet(pMsgBoxTimeoutSeconds)) {
        loop (pMsgBoxTimeoutSeconds) {
            if (!WinExist("ahk_id " . customMsgBoxGUI.Hwnd)) {
                return returnValue
            }
            remainingSeconds := pMsgBoxTimeoutSeconds - A_Index + 1
            statusBarText := "Please choose an option - [The window will close in " . remainingSeconds
            if (remainingSeconds == 1) {
                statusBarText .= " second]"
            }
            else {
                statusBarText .= " seconds]"
            }
            customMsgBoxGUIStatusBar.SetText(statusBarText)
            Sleep(1000)
        }
        returnValue := "_result_timeout"
        if (WinExist("ahk_id " . customMsgBoxGUI.Hwnd)) {
            WinClose()
        }
    }
    WinWaitClose("ahk_id " . customMsgBoxGUI.Hwnd)
    return returnValue
}

/*
Prompts the user to select a directory.
@param pPromptTitle [String] The title of the prompt window.
@param pRootDirectory [String] The root directory to start the selection from.
@param pBooleanCheckForWritingRights [boolean] Checks if the user is able to write into the selected directory.
If that is not the case, they will be prompted to select another directory.
@param pOwnerGUI [Gui] An optional GUI object. This GUI will be the owner of the file save prompt to make it modal.
@returns [String] The selected directory path.
@returns (alt) [String] "_result_no_directory_selected" if the user cancels the selection.
*/
directorySelectPrompt(pPromptTitle, pRootDirectory, pBooleanCheckForWritingRights, pOwnerGUI?) {
    ; To make this specific file dialog modal, we need to explicitly set the +OwnDialogs option in this current thread.
    if (IsSet(pOwnerGUI)) {
        pOwnerGUI.Opt("+OwnDialogs")
    }

    selectedDirectory := FileSelect("D3", pRootDirectory, pPromptTitle)
    ; This usually happens, when the user cancels the selection.
    if (selectedDirectory == "") {
        return "_result_no_directory_selected"
    }
    if (pBooleanCheckForWritingRights && !checkForWritingRights(selectedDirectory)) {
        if (IsSet(pOwnerGUI)) {
            result := MsgBox("You do not have permission to write in this directory. Please choose a different one.",
                "VD - Invalid Directory", "RC Icon! Owner" . pOwnerGUI.Hwnd)
        }
        else {
            result := MsgBox("You do not have permission to write in this directory. Please choose a different one.",
                "VD - Invalid Directory", "RC Icon! 262144")
        }

        if (result == "Retry") {
            if (isSet(pOwnerGUI)) {
                return directorySelectPrompt(pPromptTitle, pRootDirectory, pBooleanCheckForWritingRights, pOwnerGUI)
            }
            return directorySelectPrompt(pPromptTitle, pRootDirectory, pBooleanCheckForWritingRights)
        }
        return "_result_no_directory_selected"
    }
    return selectedDirectory
}

/*
Prompts the user to select a file.
@param pPromptTitle [String] The title of the prompt window.
@param pRootDirectory [String] The root directory to start the selection from.
@param pFilter [String] An optional filter for the explorer window. For example, "*.txt" would only show text files.
@param pOwnerGUI [Gui] An optional GUI object. This GUI will be the owner of the file save prompt to make it modal.
@param pBooleanMultiSelect [boolean] If set to true, the user can select multiple files.
@returns [Array] The array of selected file paths. If no files are selected, the array will be empty.
*/
fileSelectPrompt(pPromptTitle, pRootDirectory, pFilter?, pOwnerGUI?, pBooleanMultiSelect := false) {
    ; To make this specific file dialog modal, we need to explicitly set the +OwnDialogs option in this current thread.
    if (IsSet(pOwnerGUI)) {
        pOwnerGUI.Opt("+OwnDialogs")
    }

    if (pBooleanMultiSelect) {
        selectArguments := "M3"
    }
    else {
        selectArguments := "3"
    }
    if (IsSet(pFilter)) {
        selectedFileLocations := FileSelect(selectArguments, pRootDirectory, pPromptTitle, pFilter)
    }
    else {
        selectedFileLocations := FileSelect(selectArguments, pRootDirectory, pPromptTitle)
    }
    if (pBooleanMultiSelect) {
        return selectedFileLocations
    }
    if (selectedFileLocations) {
        ; The string will be returned as an array.
        return Array(selectedFileLocations)
    }
    return Array()
}

/*
Prompts the user to select a file save location.
@param pPromptTitle [String] The title of the prompt window.
@param pRootDirectory [String] The root directory to start the selection from. Can include a file name as well.
@param pFilter [String] An optional filter for the explorer window. For example, "*.txt" would only show text files.
Due to internal limitations, it is recommended to only use one filter at a time.
@param pOwnerGUI [Gui] An optional GUI object. This GUI will be the owner of the file save prompt to make it modal.
@returns [String] The selected file save path.
@returns (alt) [String] "_result_no_file_save_location_selected" if the user cancels the selection.
*/
fileSavePrompt(pPromptTitle, pRootDirectory, pFilter?, pOwnerGUI?) {
    ; To make this specific file dialog modal, we need to explicitly set the +OwnDialogs option in this current thread.
    if (IsSet(pOwnerGUI)) {
        pOwnerGUI.Opt("+OwnDialogs")
    }

    if (IsSet(pFilter)) {
        ; Caution: This currently only works with one filter at a time.
        SplitPath(pFilter, , , &expectedFileExtension)
        selectedFileSaveLocation := FileSelect("S16", pRootDirectory, pPromptTitle, pFilter)
        ; Checks if the selected file save location has the expected file extension.
        SplitPath(selectedFileSaveLocation, , &outDir, &outExt, &outName)
        if (selectedFileSaveLocation && (expectedFileExtension != outExt)) {
            ; Adds the expected file extension to the selected file save location to make the path valid.
            selectedFileSaveLocation := outDir . "\" . outName . "." . expectedFileExtension
        }
    }
    else {
        selectedFileSaveLocation := FileSelect("S16", pRootDirectory, pPromptTitle)
    }
    ; This usually happens, when the user cancels the selection.
    if (selectedFileSaveLocation == "") {
        return "_result_no_file_save_location_selected"
    }
    return selectedFileSaveLocation
}

/*
Opens a directory explicitly with the explorer executable.
@param pDirectory [String] Should be an existing directory path.
*/
openDirectoryInExplorer(pDirectory) {
    try
    {
        /*
        The reason why the path is opened explicitly with the explorer.exe is,
        that sometimes the system will attempt to sort of guess the file extension and open other files.
        */
        if (DirExist(pDirectory)) {
            Run('explorer.exe "' . pDirectory . '"')
        }
        else {
            MsgBox("The directory`n[" . pDirectory . "]`ndoes not exist.", "VD - Non-existing Directory",
                "O Icon! 262144 T3")
        }
    }
    catch as error {
        displayErrorMessage(error, "This error is rare.")
    }
}

reloadApplicationPrompt() {
    ; Number in seconds.
    i := 4

    reloadApplicationGUI := Gui(, "VD - Reloading VideoDownloader")
    textField := reloadApplicationGUI.Add("Text", "r3 w260 x20 y40", "VideoDownloader will be`n reloaded in " . i .
        " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadApplicationGUI.Add("Progress", "w280 h20 x10 y100", 0)
    buttonOkay := reloadApplicationGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := reloadApplicationGUI.Add("Button", "w80 x160 y170", "Cancel")

    ; Makes the video list GUI the owner of the window.
    if (IsSet(videoListGUI) && WinExist("ahk_id " . videoListGUI.Hwnd)) {
        reloadApplicationGUI.Opt("Owner" . videoListGUI.Hwnd)
        showGUIRelativeToOtherGUI(videoListGUI, reloadApplicationGUI, "MiddleCenter", "AutoSize")
    }
    else {
        reloadApplicationGUI.Show("AutoSize")
    }

    buttonOkay.OnEvent("Click", (*) => saveCurrentVideoListGUIStateToConfigFile() Reload())
    buttonCancel.OnEvent("Click", (*) => reloadApplicationGUI.Destroy())
    reloadApplicationGUI.OnEvent("Escape", (*) => reloadApplicationGUI.Destroy())

    /*
    The try statement is needed to protect the code from crashing because
    of the destroyed GUI when the user presses cancel.
    */
    try
    {
        while (i >= 0) {
            ; Makes the progress bar feel smoother.
            loop (20) {
                progressBar.Value += 1.25
                Sleep(50)
            }

            if (i = 1) {
                textField.Text := "VideoDownloader will be`n reloaded in " . i . " second."
            }
            else {
                textField.Text := "VideoDownloader will be`n reloaded in " . i . " seconds."
            }
            i--
        }
        textField.Text := "VideoDownloader has been reloaded."
        saveCurrentVideoListGUIStateToConfigFile()
        Sleep(100)
        Reload()
    }
}

terminateApplicationPrompt() {
    ; Number in seconds.
    i := 4

    terminateApplicationGUI := Gui(, "VD - Terminating VideoDownloader")
    textField := terminateApplicationGUI.Add("Text", "r3 w260 x20 y40", "VideoDownloader will be`n terminated in " . i .
        " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateApplicationGUI.Add("Progress", "w280 h20 x10 y100 cRed backgroundBlack", 0)
    buttonOkay := terminateApplicationGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := terminateApplicationGUI.Add("Button", "w80 x160 y170", "Cancel")

    ; Makes the video list GUI the owner of the window.
    if (IsSet(videoListGUI) && WinExist("ahk_id " . videoListGUI.Hwnd)) {
        terminateApplicationGUI.Opt("Owner" . videoListGUI.Hwnd)
        showGUIRelativeToOtherGUI(videoListGUI, terminateApplicationGUI, "MiddleCenter", "AutoSize")
    }
    else {
        terminateApplicationGUI.Show("AutoSize")
    }

    buttonOkay.OnEvent("Click", (*) => saveCurrentVideoListGUIStateToConfigFile() exitApplicationWithNotification())
    buttonCancel.OnEvent("Click", (*) => terminateApplicationGUI.Destroy())
    terminateApplicationGUI.OnEvent("Escape", (*) => terminateApplicationGUI.Destroy())

    /*
    The try statement is needed to protect the code from crashing because
    of the destroyed GUI when the user presses cancel.
    */
    try
    {
        while (i >= 0) {
            ; Makes the progress bar feel smoother.
            loop (20) {
                progressBar.Value += 1.25
                Sleep(50)
            }

            if (i = 1) {
                textField.Text := "VideoDownloader will be`n terminated in " . i . " second."
            }
            else {
                textField.Text := "VideoDownloader will be`n terminated in " . i . " seconds."
            }
            i--
        }
        textField.Text := "VideoDownloader has been terminated."
        saveCurrentVideoListGUIStateToConfigFile()
        Sleep(100)
        exitApplicationWithNotification()
    }
}

/*
Terminates the application and shows a tray tip message to inform the user.
@param pBooleanUseFallbackMessage [boolean] If set to true, will use the hardcoded English version
of the termination message. This can be useful if the language modules have not been loaded yet.
*/
exitApplicationWithNotification(pBooleanUseFallbackMessage := false) {
    global currentYTDLPActionObject

    ; Terminates all running downloads.
    if (IsSet(currentYTDLPActionObject) && (currentYTDLPActionObject.downloadProcessYTDLPPID)) {
        ProcessClose(currentYTDLPActionObject.downloadProcessYTDLPPID)
        ; We use recursive mode here to possibly end all sub processes (e.g. ffmpeg) of the yt-dlp sub process.
        terminateAllChildProcesses(currentYTDLPActionObject.downloadProcessYTDLPPID, "yt-dlp.exe", true)
    }
    saveCurrentVideoListGUIStateToConfigFile()

    if (pBooleanUseFallbackMessage) {
        displayTrayTip("VideoDownloader terminated.", "VideoDownloader - Status")
    }
    else if (readConfigFile("DISPLAY_EXIT_NOTIFICATION")) {
        displayTrayTip("VideoDownloader terminated.", "VideoDownloader - Status")
    }
    ExitApp()
}

setAutoStart(pBooleanAutoStartStatus) {
    ; Does not work for uncompiled versions of VideoDownloader.
    if (!A_IsCompiled) {
        return
    }

    autoStartShortcutFileLocation := A_Startup . "\VideoDownloader.lnk"
    ; Checks for an already existing shortcut file and extracts the target path.
    if (FileExist(autoStartShortcutFileLocation)) {
        FileGetShortcut(autoStartShortcutFileLocation, &outShortcutTarget)
    }
    else {
        outShortcutTarget := "_result_no_existing_autostart_shortcut_file"
    }

    ; Checks if the existing shortcut file was not created by this instance of VideoDownloader.
    if (pBooleanAutoStartStatus && (A_ScriptFullPath != outShortcutTarget)) {
        ; Creates (or overwrites) the (existing) shortcut to start VideoDownloader with Windows.
        FileCreateShortcut(A_ScriptFullPath, autoStartShortcutFileLocation, A_ScriptDir, ,
            "Auto start shortcut for VideoDownloader.")
        displayTrayTip("VideoDownloader added to startup folder.", "VideoDownloader - Status")
    }
    ; Checks if the existing shortcut file was created by this instance of VideoDownloader and removes it.
    else if (!pBooleanAutoStartStatus && (A_ScriptFullPath == outShortcutTarget)) {
        ; Disables the automatic start with windows.
        displayTrayTip("VideoDownloader removed from startup folder.", "VideoDownloader - Status")
        FileDelete(autoStartShortcutFileLocation)
    }
}

/*
Displays a tray tip message for a given amount of time.
@param pText [String] The text of the tray tip message.
@param pTitle [String] The title of the tray tip message.
@param pOptions [String] The options for the tray tip message. For example "Iconi Mute" or "Icon!".
@param pTimeoutMilliseconds [int] The time in milliseconds that the tray tip message will be displayed.
*/
displayTrayTip(pText, pTitle, pOptions := "Iconi Mute", pTimeoutMilliseconds := 3000) {
    TrayTip(pText, pTitle, pOptions)
    SetTimer((*) => TrayTip(), -pTimeoutMilliseconds)
}

/*
Outputs a little GUI containing information about the error. Allows to be copied to the clipboard.
@param pErrorObject [Error Object] Usually created when catching an error via Try / Catch.
@param pAdditionalErrorMessage [String] An optional error message to show.
@param pBooleanTerminatingError [boolean] If set to true, will force the application to terminate once the message disappears.
@param pMessageTimeoutMilliseconds [int] Optional message timeout. Closes the message after a delay of time.
*/
displayErrorMessage(pErrorObject := unset, pAdditionalErrorMessage := unset, pBooleanTerminatingError := false,
    pMessageTimeoutMilliseconds := unset) {
    if (IsSet(pErrorObject)) {
        errorMessageBlock := "*****ERROR MESSAGE*****`n" . pErrorObject.Message . "`n`n*****ERROR TRIGGER*****`n" .
            pErrorObject.What
        if (pErrorObject.Extra != "") {
            errorMessageBlock .= "`n`n*****ADDITIONAL INFO*****`n" . pErrorObject.Extra
        }
        errorMessageBlock .= "`n`n*****FILE*****`n" . pErrorObject.File . "`n`n*****LINE*****`n" . pErrorObject.Line
            . "`n`n*****CALL STACK*****`n" . pErrorObject.Stack
    }
    if (IsSet(pAdditionalErrorMessage)) {
        errorMessageBlock .= "`n`n#####ADDITIONAL ERROR MESSAGE#####`n" . pAdditionalErrorMessage
    }
    if (pBooleanTerminatingError) {
        errorMessageBlock .= "`n`nScript has to exit!"
    }
    if (IsSet(pMessageTimeoutMilliseconds)) {
        ; Hides the GUI and therefore
        SetTimer((*) => errorGUI.Destroy(), "-" . pMessageTimeoutMilliseconds)
    }

    funnyErrorMessageArray := Array(
        "This shouldn't have happened :(",
        "Well, this is akward...",
        "Why did we stop?!",
        "Looks like we're lost in the code jungle...",
        "That's not supposed to happen!",
        "Whoopsie daisy, looks like an error!",
        "Error 404: Sense of humor not found",
        "Looks like a glitch in the Matrix...",
        "Houston, we have a problem...",
        "Unexpected error: Please blame the developer",
        "Error: Keyboard not responding, press any key to continue... oh wait",
        "Task failed successfully!"
    )
    ; Selects a "random" funny error message to be displayed.
    funnyErrorMessage := funnyErrorMessageArray.Get(Random(1, funnyErrorMessageArray.Length))

    errorGUI := Gui(, "VideoDownloader - Error")

    errorGUIfunnyErrorMessageText := errorGUI.Add("Text", "yp+10 r4 w300", funnyErrorMessage)
    errorGUIfunnyErrorMessageText.SetFont("italic S10")
    errorGUIerrorMessageBlockText := errorGUI.Add("Text", "yp+50", errorMessageBlock)

    errorGUIbuttonGroupBox := errorGUI.Add("GroupBox", "r2.1 w340")
    errorGUIgitHubIssuePageButton := errorGUI.Add("Button", "xp+10 yp+15 w100 R2 Default",
        "Report this issue on GitHub")
    errorGUIgitHubIssuePageButton.OnEvent("Click", (*) => Run(
        "https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues/new/choose"))
    errorGUIcopyErrorToClipboardButton := errorGUI.Add("Button", "xp+110 w100 R2", "Copy error to clipboard")
    errorGUIcopyErrorToClipboardButton.OnEvent("Click", (*) => A_Clipboard := errorMessageBlock)

    if (pBooleanTerminatingError) {
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Exit")
    }
    else {
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Continue")
    }
    errorGUIActionButton.OnEvent("Click", (*) => errorGUI.Destroy())
    errorGUI.Show("AutoSize")
    errorGUI.Flash()
    ; There might be an error with the while condition, once the GUI is destroyed.
    try
    {
        while (WinExist("ahk_id " . errorGUI.Hwnd)) {
            Sleep(500)
        }
    }

    if (pBooleanTerminatingError) {
        exitApplicationWithNotification(true)
    }
}

/*
Checks a given path for writing permissions with the current user rights (the user who launched this application).
@returns [boolean] True, if the current permissions allow writing to the specified directory. False otherwise.
*/
checkForWritingRights(pPath) {
    try
    {
        FileAppend("checkForWritingRights(" . pPath . ")", pPath . "\checkForWritingRights.txt")
        FileDelete(pPath . "\checkForWritingRights.txt")
    }
    catch as error {
        if (InStr(error.message, "(5) ")) {
            return false
        }
        else {
            displayErrorMessage(error, "This error is rare. Please report this!")
            return false
        }
    }
    return true
}

/*
Checks all GitHub Repository tags to find new versions.
@returns [String] Returns the update version (which is usually the tag name), when an update is available.
@returns (alt) [String] "_result_no_update_available", when no update is available.
*/
checkForAvailableUpdates() {
    global psUpdateScriptLocation
    global applicationRegistryDirectory
    global versionFullName

    ; Does not check for updates, if the application isn't compiled.
    if (!A_IsCompiled) {
        return "_result_no_update_available"
    }
    /*
    Changes "HKCU\SOFTWARE\LeoTN\VideoDownloader" to "HKCU:SOFTWARE\LeoTN\VideoDownloader"
    to make the path compatible with PowerShell.
    */
    psCompatibleScriptRegistryPath := StrReplace(applicationRegistryDirectory, "\", ":", , , 1)
    parameterString :=
        '-pGitHubRepositoryLink "https://github.com/LeoTN/yt-dlp-autohotkey-gui" '
        . '-pRegistryDirectory "' . psCompatibleScriptRegistryPath . '" '
        . '-pCurrentVersionTag "' . versionFullName . '"'

    if (readConfigFile("UPDATE_TO_BETA_VERSIONS")) {
        parameterString .= " -pSwitchConsiderBetaReleases"
    }
    ; Calls the PowerShell script to check for available updates.
    exitCode := RunWait('powershell.exe -executionPolicy bypass -file "'
        . psUpdateScriptLocation . '" ' . parameterString, , "Hide")
    switch (exitCode) {
        ; Available update found.
        case 101:
        {
            ; Extracts the available update from the registry.
            updateVersion := RegRead(applicationRegistryDirectory, "AVAILABLE_UPDATE", "v0.0.0.1")
            if (updateVersion == "no_available_update") {
                return "_result_no_update_available"
            }
            return updateVersion
        }
        default:
        {
            return "_result_no_update_available"
        }
    }
}

/*
Tries to reach google.com to determine the computer's Internet connection status.
@returns [boolean] True, if the computer is connected to the Internet. False otherwise.
*/
checkInternetConnection() {
    global configFileLocation

    /*
    This option should only be used for debugging purposes.
    We use IniRead() here, because the config file might not be loaded yet.
    */
    overwriteValue := IniRead(configFileLocation, "DebugSettings", "OVERWRITE_CHECK_INTERNET_CONNECTION", -1)
    if (overwriteValue == 1) {
        MsgBox("[" . A_ThisFunc . "()] [INFO] Forced overwrite to value [1].",
            "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! T3 262144")
        return true
    }
    else if (overwriteValue == 0) {
        MsgBox("[" . A_ThisFunc . "()] [INFO] Forced overwrite to value [0].",
            "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! T3 262144")
        return false
    }

    targetURL := "https://www.google.com"
    try {
        ; https://learn.microsoft.com/de-de/windows/win32/api/wininet/nf-wininet-internetcheckconnectionw
        booleanIsConnected :=
            DllCall("Wininet.dll\InternetCheckConnectionW", "Str", targetURL, "UInt", 1, "UInt", 0)
        if (booleanIsConnected) {
            return true
        }
    }
    try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", targetURL, false)
        httpRequest.Send()
        if (httpRequest.Status = 200) {
            return true
        }
    }
    return false
}

/*
Checks if a given string is a valid video URL.
NOTE: URLs without any content after the top level domain won't be considered valid!
For example [www.youtube.com] would be invalid but [https://www.youtube.com/watch?v=dQw4w9WgXcQ] would be valid.
@param pString [String] The string that should be examined.
@returns [boolean] True, if the provided string is a valid URL. False otherwise.
*/
checkIfStringIsAValidURL(pString) {
    ; Checks if the entered string is a valid URL.
    regExString := '^(https?:\/\/)?([\w\-]+\.)+[\w]{2,}\/[^\s]{3,}$'
    if (RegExMatch(pString, regExString)) {
        return true
    }
    return false
}

/*
Checks if the provided playlist range index string has a correct syntax (1-2 or 1:2 for example).
@param pString [String] The string that should be examined.
@returns [boolean] True, if the provided string is a valid playlist range. False otherwise.
*/
checkIfStringIsValidPlaylistIndexRange(pString) {
    regExString := '^([1-9]\d*([-:]\d+)?)(,[1-9]\d*([-:]\d+)?)*$'
    if (RegExMatch(pString, regExString)) {
        return true
    }
    return false
}

/*
Checks if a given string is in a given array.
@param pString [String] The string to check.
@param pArray [Array] The array to check.
@returns [boolean] True if the string is in the array. False otherwise.
*/
checkIfStringIsInArray(pString, pArray, pBooleanCaseSensitive := true) {
    for (index, value in pArray) {
        if (pBooleanCaseSensitive && (pString == value)) {
            return true
        }
        else if (pString = value) {
            return true
        }
    }
    return false
}

/*
"Decyphers" the cryptic hotkey symblos into normal words.
@param pHotkey [String] Should be a valid AutoHotkey hotkey for example "+!F4".
@returns [String] A "decyphered" AutoHotkey hotkey for example "Shift + Alt + F4".
*/
expandHotkey(pHotkey) {
    hotkeyString := pHotkey
    hotkeyString := StrReplace(hotkeyString, "+", "SHIFT + ")
    hotkeyString := StrReplace(hotkeyString, "^", "CTRL + ")
    hotkeyString := StrReplace(hotkeyString, "!", "ALT + ")
    hotkeyString := StrReplace(hotkeyString, "#", "WIN + ")

    return hotkeyString
}

/*
FUNCTION SECTION END
-------------------------------------------------
*/
