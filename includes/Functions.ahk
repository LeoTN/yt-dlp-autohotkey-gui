#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

functions_onInit() {

}

/*
FUNCTION SECTION
-------------------------------------------------
*/

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
        ; Recreates the log file path because the script will put the log file in the same directory as itself.
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
Reads the download log file during the download process. The progress will be displayed in the video list GUI.
@param pYTDLPProcessPID [int] The PID of the yt-dlp process downloading the video.
@param pYTDLPLogFileLocation [int] The location of the log file that the yt-dlp process writes to.
@param pCompleteVideoAmount [int] The total amount of videos that are going to be downloaded.
@param pAlreadyDownloadedVideoAmount [int] The amount of videos that have been downloaded already.
@param pCurrentlyDownloadedVideoTitle [int] The title of the currently downloaded video.
*/
monitorVideoDownloadProgress(pYTDLPProcessPID, pYTDLPLogFileLocation, pCompleteVideoAmount,
    pAlreadyDownloadedVideoAmount, pCurrentlyDownloadedVideoTitle) {
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
    downloadProgressText.Value := "Downloaded " . pAlreadyDownloadedVideoAmount . " / " . pCompleteVideoAmount
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
            downloadProgressText.Value := "Downloaded " . pAlreadyDownloadedVideoAmount + 1
                . " / " . pCompleteVideoAmount
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
}

/*
Tries to find an existing process via a wildcard.
NOTE: Currently only supports wildcards containing the beginning of the wanted process.
@param pWildcard [String] Should be a wildcard process name for example "VideoDownloader.exe".
*/
findAlreadyRunningScriptInstance(pWildcard) {
    SplitPath(pWildcard, , , &outExtension, &outNameNoExt)
    allRunningProcessesNameArray := []
    allRunningProcessesPathArray := []
    ; Filles the array with all existing process names.
    for (Process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")) {
        allRunningProcessesNameArray.InsertAt(A_Index, Process.Name)
        allRunningProcessesPathArray.InsertAt(A_Index, Process.CommandLine)
    }
    ; Traveres through every object to compare it with the wildcard.
    for (v in allRunningProcessesNameArray) {
        ; For example if you are process called "VideoDownloader.development-build-6.exe" it
        ; would be sufficient to search for "VideoDownloader.exe" as the [*]+ part allows an
        ; undefined amount of characters to appear between the wildcard name and it's extension.
        ; The condition below makes sure that it does not find the current instance of this script as a proces.
        if (RegExMatch(v, outNameNoExt . ".*." . outExtension) && v != A_ScriptName) {
            processPath := StrReplace(allRunningProcessesPathArray.Get(A_Index), '"')
            msgText := "Another instance of VideoDownloader is already running."
            msgText .= "`n`n********************"
            msgText .= "`nName: [ " . v . "]"
            msgText .= "`nPath: [ " . processPath . "]"
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
                        ProcessClose(v)
                    }
                    catch as error {
                        errorAdditionalMessage :=
                            "The process might be elevated (which means it was launched with higher permissions)."
                        displayErrorMessage(error, errorAdditionalMessage, true)
                    }
                }
                case msgButton1:
                {
                    ; This option is not recommended because the script is not supposed to run with multiple instances active.
                    return
                }
                Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                    exitScriptWithNotification(true)
                }
                    ; Stops after the first match.
                    break
            }
        }
    }
}

/*
Copies all files from the old version into a backup folder using robocopy.
@param pBackupParentDirectory [String] Usually the script directory with an additional folder called "VideoDownloader_old_version_backups" at the end.
*/
backupOldVersionFiles(pBackupParentDirectory) {
    global versionFullName
    global scriptWorkingDirectory

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
    downloadFolder := readConfigFile("DOWNLOAD_PATH")
    downloadFolderTemp := sourceDirectory . "\VideoDownloader\download_temp" ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
    generalTempFolder := scriptWorkingDirectory . "\temp" ; REMOVE [READ VALUE FROM CONFIG FILE IN THE FUTURE]
    ; Build the paramter string for the robocopy executable.
    parameterString := "`"" . sourceDirectory . "`" `"" . destinationDirectory . "`" /E "
    parameterString .= "/XD `"" . sourceDirectory . "\VideoDownloader_old_version_backups`" "
    parameterString .= "`"" . downloadFolder . "`" "
    parameterString .= "`"" . downloadFolderTemp . "`" "
    parameterString .= "`"" . generalTempFolder . "`" "
    parameterString .= "/MAX:10485760"

    ; Waits 3 seconds before starting the backup process to ensure that the main script has exited already.
    Run('cmd.exe /c "timeout /t 3 /nobreak && robocopy ' . parameterString . '"', , "Hide")
    exitScriptWithNotification()
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
@returns [String] The text of the button clicked by the user.
@returns (alt) [String] "_result_gui_closed" if the GUI was closed.
@returns (alt) [String] "_result_timeout" if the timeout was reached.
*/
customMsgBox(pMsgBoxText, pMsgBoxTitle := A_ScriptName, pMsgBoxHeadLine := A_ScriptName,
    pButton1Text?, pButton2Text := "Okay", pButton3Text?, pMsgBoxTimeoutSeconds?, pBooleanAlwaysOnTop := false) {
    ; This value represents either the user choice or any other possible outcome like a timeout for example.
    returnValue := "_result_gui_closed"
    ; Create the GUI which will mimic the style of a message box.
    customMsgBoxGUI := Gui(, pMsgBoxTitle)
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
    customMsgBoxGUIStatusBar.SetIcon("shell32.dll", 222) ; REMOVE USE ICON DLL HERE
    customMsgBoxGUI.Show("w490")
    ; OnEvent function for the buttons.
    handleCustomMsgBoxGUI_button_onClick(pButton, pInfo) {
        ; The text of the pressed button will be returned.
        returnValue := pButton.Text
        if (WinExist("ahk_id " . customMsgBoxGUI.Hwnd)) {
            WinClose()
        }
    }
    ; The script waits until the user made a choice or the timer runs out.
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
Reads the registry and extracts the current script version.
If the version in the registry has a build version other than 0, it will append the word "-beta".
@returns [String] The version from the registry or "v0.0.0.1" in case the registry value is invalid.
*/
getCorrectScriptVersionFromRegistry() {
    global scriptRegistryDirectory

    regValue := RegRead(scriptRegistryDirectory, "CURRENT_VERSION", "v0.0.0.1")
    ; Finds versions matching this format [v1.2.3.4]
    if (RegExMatch(regValue, "^v\d+\.\d+\.\d+\.(\d+)$", &match)) {
        buildVersionNumber := match[1]
        ; A version number with a build version is only used for beta versions.
        if (buildVersionNumber != 0) {
            regValue := regValue . "-beta"
            ; Corrects the version number in the registry.
            RegWrite(regValue, "REG_SZ", scriptRegistryDirectory, "CURRENT_VERSION")
            return getCorrectScriptVersionFromRegistry()
        }
        return regValue
    }
    ; Finds versions matching this format [v1.2.3], [v1.2.3-beta], [1.2.3] or [1.2.3-beta].
    else if (RegExMatch(regValue, "^v?\d+\.\d+\.\d+(\.\d+)?(-beta)?$", &match)) {
        return regValue
    }
    else {
        ; In case the version in the registry is invalid.
        regValue := "v0.0.0.1"
    }
    return regValue
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
Checks a given path for writing permissions with the current user rights (the user who launched this script).
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
    global scriptRegistryDirectory

    ; Does not check for updates, if there is no Internet connection or the script isn't compiled.
    if (!checkInternetConnection() || !A_IsCompiled) {
        return "_result_no_update_available"
    }
    /*
    Changes "HKCU\SOFTWARE\LeoTN\VideoDownloader" to "HKCU:SOFTWARE\LeoTN\VideoDownloader"
    to make the path compatible with PowerShell.
    */
    psCompatibleScriptRegistryPath := StrReplace(scriptRegistryDirectory, "\", ":", , , 1)
    parameterString :=
        '-pGitHubRepositoryLink "https://github.com/LeoTN/yt-dlp-autohotkey-gui"' .
        ' -pRegistryDirectory "' . psCompatibleScriptRegistryPath . '"'

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
            updateVersion := RegRead(scriptRegistryDirectory, "AVAILABLE_UPDATE", "v0.0.0.1")
            if (updateVersion == "no_available_update") {
                return "_result_no_update_available"
            }
            return updateVersion
        }
        Default:
        {
            return "_result_no_update_available"
        }
    }
}

/*
Tries to ping google.com to determine the computer's Internet connection status.
@returns [boolean] True, if the computer is connected to the Internet. False otherwise.
*/
checkInternetConnection() {
    ; Checks if the user has an established Internet connection.
    try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://www.google.com", false)
        httpRequest.Send()

        if (httpRequest.Status = 200) {
            return true
        }
    }
    return false
}

/*
Terminates the script and shows a tray tip message to inform the user.
@param pBooleanUseFallbackMessage [boolean] If set to true, will use the hardcoded English version
of the termination message. This can be useful if the language modules have not been loaded yet.
*/
exitScriptWithNotification(pBooleanUseFallbackMessage := false) {
    if (pBooleanUseFallbackMessage) {
        TrayTip("VideoDownloader terminated.", "VideoDownloader - Status", "Iconi Mute")
    }
    else {
        TrayTip("VideoDownloader terminated. (NO LANGUAGE LOADED)", "VideoDownloader - Status", "Iconi Mute") ; REMOVE [ADD LANGUAGE OPTION]
    }
    ; Using ExitApp() twice ensures that the script will be terminated entirely.
    ExitApp()
    ExitApp()
}

reloadScriptPrompt() {
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui(, "VD - Reloading Script")
    textField := reloadScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n reloaded in " . i . " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadScriptGUI.Add("Progress", "w280 h20 x10 y100", 0)
    buttonOkay := reloadScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := reloadScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    reloadScriptGUI.Show("w300 h200")

    buttonOkay.OnEvent("Click", (*) => Reload())
    buttonCancel.OnEvent("Click", (*) => reloadScriptGUI.Destroy())

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
                textField.Text := "The script will be`n reloaded in " . i . " second."
            }
            else {
                textField.Text := "The script will be`n reloaded in " . i . " seconds."
            }
            i--
        }
        textField.Text := "The script has been reloaded."
        Sleep(100)
        Reload()
        ExitApp()
        ExitApp()
    }
}

terminateScriptPrompt() {
    ; Number in seconds.
    i := 4

    terminateScriptGUI := Gui(, "VD - Terminating Script")
    textField := terminateScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n terminated in " . i .
        " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateScriptGUI.Add("Progress", "w280 h20 x10 y100 cRed backgroundBlack", 0)
    buttonOkay := terminateScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := terminateScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    terminateScriptGUI.Show("w300 h200")

    buttonOkay.OnEvent("Click", (*) => ExitApp())
    buttonCancel.OnEvent("Click", (*) => terminateScriptGUI.Destroy())

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
                textField.Text := "The script will be`n terminated in " . i . " second."
            }
            else {
                textField.Text := "The script will be`n terminated in " . i . " seconds."
            }
            i--
        }
        textField.Text := "The script has been terminated."
        Sleep(100)
        ExitApp()
        ExitApp()
    }
}

/*
Outputs a little GUI containing information about the error. Allows to be copied to the clipboard.
@param pErrorObject [Error Object] Usually created when catching an error via Try / Catch.
@param pAdditionalErrorMessage [String] An optional error message to show.
@param pBooleanTerminatingError [boolean] If set to true, will force the script to terminate once the message disappears.
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
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Exit Script")
    }
    else {
        errorGUIActionButton := errorGUI.Add("Button", "xp+110 w100 R2", "Continue Script")
    }
    errorGUIActionButton.OnEvent("Click", (*) => errorGUI.Destroy())
    errorGUI.Show()
    errorGUI.Flash()
    ; There might be an error with the while condition, once the GUI is destroyed.
    try
    {
        while (WinExist("ahk_id " . errorGUI.Hwnd)) {
            Sleep(500)
        }
    }

    if (pBooleanTerminatingError) {
        exitScriptWithNotification(true)
    }
}

/*
A simple method to convert an array into a string form.
@param pArray [Array] Should be an array to convert.
@returns [String] The array converted into a string form.
*/
arrayToString(pArray) {
    string := "["

    for (index, value in pArray) {
        string .= value
        if (index < pArray.Length) {
            string .= ","
        }
    }

    string .= "]"
    return string
}

/*
A simple method to convert a string (in array form) into an array.
@param pString [String] Should be a string (in array form) to convert.
@returns [Array] The string converted into an array form.
*/
stringToArray(pString) {
    array := StrSplit(pString, ",")
    return array
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
