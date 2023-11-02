#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

/*
DEBUG SECTION
-------------------------------------------------
Hotkey to disable/enable debug mode.
*/

+^!F1::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        editConfigFile("booleanDebugMode", false)
        MsgBox("Debug mode has been disabled.", "DEBUG MODE", "O Iconi 262144 T1")
    }
    Else If (readConfigFile("booleanDebugMode") = false)
    {
        editConfigFile("booleanDebugMode", true)
        MsgBox("Debug mode has been enabled.", "DEBUG MODE", "O Icon! 262144 T1")
    }
    Else
    {
        Throw ("No valid state in booleanDebugMode")
    }
}

Hotkey_onInit()
{
    Try
    {
        registerHotkeys()
    }
    Catch
    {
        registerHotkeys()
    }
}

registerHotkeys()
{
    ; Beginning of all standard script hotkeys.

    ; Main hotkey (start download).
    Hotkey(readConfigFile("DOWNLOAD_HK"), (*) => startDownload(buildCommandString()), "On")

    ; Second hotkey (collect URLs).
    Hotkey(readConfigFile("URL_COLLECT_HK"), (*) => saveSearchBarContentsToFile(), "On")

    ; Third hotkey (collect URLs from video thumbnail).
    Hotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK"), (*) => saveVideoURLDirectlyToFile(), "On")

    ; GUI hotkey (opens GUI).
    Hotkey(readConfigFile("MAIN_GUI_HK"), (*) => Hotkey_openMainGUI())
    ; Hotkey to open Download Options GUI.
    Hotkey(readConfigFile("OPTIONS_GUI_HK"), (*) => Hotkey_openOptionsGUI())
    ; Hotkey to termniate the script.
    Hotkey(readConfigFile("TERMINATE_SCRIPT_HK"), (*) => terminateScriptPrompt(), "Off")

    ; Hotkey to reload the script.
    Hotkey(readConfigFile("RELOAD_SCRIPT_HK"), (*) => reloadScriptPrompt(), "Off")

    ; Hotkey that is currently not used.
    Hotkey(readConfigFile("NOT_USED_HK"), (*) => MsgBox("Not implemented yet", , "T2"), "Off")

    ; Hotkey for clearing the URL file.
    Hotkey(readConfigFile("CLEAR_URL_FILE_HK"), (*) => clearURLFile(), "Off")

    global isDownloading := false
}

; Hotkey support function to open the script GUI.
Hotkey_openMainGUI()
{
    Try
    {
        static flipflop := true
        If (!WinExist("ahk_id " . mainGUI.Hwnd))
        {
            mainGUI.Show("w300 h200")
            flipflop := false
        }
        Else If (flipflop = false && WinActive("ahk_id " . mainGUI.Hwnd))
        {
            mainGUI.Hide()
            flipflop := true
        }
        Else
        {
            WinActivate("ahk_id " . mainGUI.Hwnd)
        }
    }
}

; Hotkey support function to open the script download options GUI.
Hotkey_openOptionsGUI()
{
    Try
    {
        static flipflop := true
        If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            downloadOptionsGUI.Show("w500 h405")
            flipflop := false
        }
        Else If (flipflop = false && WinActive("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            downloadOptionsGUI.Hide()
            flipflop := true
        }
        Else
        {
            WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
        }
    }
    global lastDownloadPath := ""
}

/*
FUNCTION SECTION
-------------------------------------------------
*/

; Important function which executes the built command string by pasting it into the console.
startDownload(pCommandString, pBooleanSilent := enableSilentDownloadModeCheckbox.Value)
{
    global isDownloading
    If (checkInternetConnection() = false)
    {
        Return MsgBox("Unable to connect to the Internet.`n`nPlease check your Internet connection.", "Warning !", "O Icon! 4096 T2")
    }
    If (isDownloading = true)
    {
        Return MsgBox("There is a download process running already.`n`nPlease wait for it to finish or cancel it.",
            "Information", "O Icon! 4096 T2")
    }
    Else
    {
        isDownloading := true
    }

    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
    stringToExecute := pCommandString
    booleanSilent := pBooleanSilent

    If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
    {
        Hotkey_openOptionsGUI()
    }
    Else
    {
        WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
    }
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    If (!FileExist(tmpConfig) && downloadOptionsGUI_SubmitObject.UseTextFileForURLsCheckbox = true)
    {
        MsgBox("No URL file found. You can save`nURLs by clicking on a video and`npressing: [" .
            expandHotkey(readConfigFile("URL_COLLECT_HK")) . "]", "Download status", "O Icon! 8192")
        isDownloading := false
        Return
    }
    If (downloadOptionsGUI_SubmitObject.useTextFileForURLsCheckbox = true)
    {
        SplitPath(tmpConfig, , &outDir)
        If (downloadOptionsGUI_SubmitObject.ClearURLFileAfterDownloadCheckbox = true)
        {
            FileMove(tmpConfig, outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt", true)
        }
        Else
        {
            FileCopy(tmpConfig, outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt", true)
        }
    }
    If (booleanSilent = true)
    {
        ; Execute the command line command and wait for it to be finished.
        displayAndLogConsoleCommand(stringToExecute, true)
        monitorDownloadProgress()
    }
    Else
    {
        ; Enables the user to access the command and to review potential errors thrown by yt-dlp.
        displayAndLogConsoleCommand(stringToExecute, false)
        monitorDownloadProgress()
    }
    postProcessDownloadFiles()
    If (downloadOptionsGUI_SubmitObject.ClearURLFileAfterDownloadCheckbox = true
        && downloadOptionsGUI_SubmitObject.IgnoreAllOptionsCheckbox != true)
    {
        manageURLFile(false)
    }
    If (downloadOptionsGUI_SubmitObject.TerminateScriptAfterDownloadCheckbox = true)
    {
        isDownloading := false
        saveGUISettingsAsPreset("last_settings", true)
        If (downloadOptionsGUI_SubmitObject.EnableSilentDownloadModeCheckbox = false)
        {
            terminateScriptPrompt()
        }
        Else
        {
            ExitApp()
            ExitApp()
        }
    }
    Else
    {
        Switch (downloadOptionsGUI_SubmitObject.UseDefaultDownloadLocationCheckbox)
        {
            Case 0:
            {
                global lastDownloadPath := downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . '\' . downloadTime
            }
            Case 1:
            {
                global lastDownloadPath := readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime
            }
        }
        isDownloading := false
        saveGUISettingsAsPreset("last_settings", true)
    }
}

displayAndLogConsoleCommand(pCommand, pBooleanSilent)
{
    command := pCommand
    booleanSilent := pBooleanSilent
    global hiddenConsolePID
    global visualPowershellPID

    Run(A_ComSpec . ' /c title Download is running... & ' . command . ' > "' . A_Temp
        . '\yt_dlp_download_log.txt" && title Completed... && timeout /T 3', , "Min", &hiddenConsolePID)
    ProcessWait(hiddenConsolePID)

    If (booleanSilent = false)
    {
        ; Deletes the old log file.
        Try
        {
            FileDelete(A_Temp . "\yt_dlp_download_log.txt")
        }
        ; The powershell script now waits for the hook file.
        Run('powershell.exe -noExit -executionPolicy bypass -file "' . scriptBaseFilesLocation . '\library\scripts\MonitorHookFile.ps1"'
            , , "Min", &visualPowershellPID)
        WinWait("ahk_pid " . visualPowershellPID)
        WinActivate("ahk_pid " . visualPowershellPID)
    }
}

; Checks the download log file for status updates and reacts by updating the download options GUI progress bar and text fields.
monitorDownloadProgress()
{
    global booleanDownloadTerminated := false
    If (downloadOptionsGUI_SubmitObject.useTextFileForURLsCheckbox = true)
    {
        SplitPath(readConfigFile("URL_FILE_LOCATION"), , &outDir)
        global urlArray := readFile(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt", true)
        global videoAmount := urlArray.Length
    }
    Else
    {
        global videoAmount := 1
    }
    global downloadedVideoAmount := 0
    global skippedVideoArchiveAmount := 0
    global skippedVideoPresentAmount := 0
    global skippedVideoMaxSizeAmount := 0
    maximumBarValue := videoAmount * 100
    currentBarValue := 0
    partProgress := 0
    ; This variable needs to exist because yt-dlp spams the file to large message which causes a lot of trouble.
    booleanSkippingLocked := false
    booleanWaitForVideoDownload := true
    parsedLines := 0
    ; Prepares the download options GUI.
    downloadStatusProgressBar.Opt("Range0-" . maximumBarValue)
    downloadStatusProgressBar.Value := 0
    If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = true)
    {
        downloadStatusText.Text := "Playlist mode: " . downloadedVideoAmount . " video(s) processed."
    }
    Else
    {
        downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
    }

    ; Waits for the download log file to exist.
    maxRetries := 10
    While (!FileExist(A_Temp . "\yt_dlp_download_log.txt"))
    {
        Sleep(1000)
        If (maxRetries <= 0)
        {
            MsgBox("Could not find hook file to track progress.`n`nTerminating script.", "Error !", "O IconX T2")
            ExitApp()
            ExitApp()
        }
        maxRetries--
    }
startOfFileReadLoop:
    Loop Read (A_Temp . "\yt_dlp_download_log.txt")
    {
        ; All previous lines will be skipped.
        If (parsedLines >= A_Index)
        {
            Continue
        }
        ; Makes the script skip all other download percentage values so that the progress bar does only fill when
        ; downloading the actual video.
        If (booleanWaitForVideoDownload = true)
        {
            ; Makes sure that the the progress bar is not unlocked by messages like "Deleting file" etc.
            If (InStr(A_LoopReadLine, "[download] Destination:"))
            {
                tmp_Line := A_LoopReadLine
                Loop (downloadVideoFormatArray.Length)
                {
                    If (InStr(tmp_Line, "." . downloadVideoFormatArray.Get(A_Index)))
                    {
                        booleanWaitForVideoDownload := false
                    }
                }
            }
        }
        ; Scanns the output from the console and extracts the download progress percentage values.
        Else If (RegExMatch(A_LoopReadLine, "S)[\d]+[.][\d{1}][%]", &outMatch) != 0 && partProgress < 100)
        {
            outString := outMatch[]
            outStringReady := StrReplace(outString, "%")
            outNumberReady := Number(outStringReady)
            ; This avoids filling the progress bar to fast because of too many 100% messages from yt-dlp.
            If (outNumberReady < 100)
            {
                partProgress := outNumberReady
            }
            ; This marks the end of the download process of the video.
            ; It also deactivates the second if condition above.
            Else If (outNumberReady = 100)
            {
                partProgress := 100
            }
        }
        ; The already recorded message is important because the progress bar has to move up one video to avoid issues.
        If (InStr(A_LoopReadLine, "has already been recorded in the archive"))
        {
            booleanWaitForVideoDownload := true
            skippedVideoArchiveAmount++
            partProgress := 0
            downloadStatusText.Text := skippedVideoArchiveAmount . " video(s) already in archive file."
            ; Calculates the progress bar value with all videos processed.
            tmpResult := downloadedVideoAmount + skippedVideoArchiveAmount + skippedVideoPresentAmount + skippedVideoMaxSizeAmount
            currentBarValue := tmpResult * 100
            ; Applies the changes to the GUI progress bar.
            downloadStatusProgressBar.Value := currentBarValue
            Sleep(100)
        }
        ; Same thing as above.
        Else If (InStr(A_LoopReadLine, "has already been downloaded"))
        {
            booleanWaitForVideoDownload := true
            skippedVideoPresentAmount++
            partProgress := 0
            downloadStatusText.Text := skippedVideoPresentAmount . " video(s) already present."
            ; Calculates the progress bar value with all videos processed.
            tmpResult := downloadedVideoAmount + skippedVideoArchiveAmount + skippedVideoPresentAmount + skippedVideoMaxSizeAmount
            currentBarValue := tmpResult * 100
            ; Applies the changes to the GUI progress bar.
            downloadStatusProgressBar.Value := currentBarValue
            Sleep(100)
        }
        ; This message indicates that the video will be skipped because it is larger than the selected filesize.
        Else If (InStr(A_LoopReadLine, "does not pass filter (filesize_approx<" .
            downloadOptionsGUI_SubmitObject.MaxDownloadSizeEdit . "M)"))
        {
            If (booleanSkippingLocked = false)
            {
                booleanWaitForVideoDownload := true
                booleanSkippingLocked := true
                skippedVideoMaxSizeAmount++
                partProgress := 0
                downloadStatusText.Text := skippedVideoMaxSizeAmount . " video(s) larger than maximum filesize."
                ; Calculates the progress bar value with all videos processed.
                tmpResult := downloadedVideoAmount + skippedVideoArchiveAmount + skippedVideoPresentAmount + skippedVideoMaxSizeAmount
                currentBarValue := tmpResult * 100
                ; Applies the changes to the GUI progress bar.
                downloadStatusProgressBar.Value := currentBarValue
                Sleep(100)
            }
        }
        ; This message only appears when the previous video processing has been finished.
        ; NOTE: Does only work when using a temp directory as parameter !
        Else If (InStr(A_LoopReadLine, "[MoveFiles] Moving file"))
        {
            If (partProgress = 100)
            {
                booleanWaitForVideoDownload := true
                downloadedVideoAmount++
                partProgress := 0
                If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = true)
                {
                    downloadStatusText.Text := "Playlist mode: " . downloadedVideoAmount . " video(s) processed."
                }
                Else
                {
                    downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
                }
            }
        }
        Else If (booleanSkippingLocked = true)
        {
            ; When a video is skipped this method is used to detect if a new video is beeing processed.
            If (InStr(A_LoopReadLine, "Extracting URL: https://www"))
            {
                ; "[youtube:tab]" is considered to be ignored, as it only shows up when downloading a playlist.
                If (!InStr(A_LoopReadLine, "[youtube:tab] Extracting URL: https://www"))
                {
                    ; When a new video is beeing processed, skipping it will be unlocked.
                    booleanSkippingLocked := false
                }
            }
        }
        If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = false)
        {
            ; Calculates the progress bar value with all videos processed.
            tmpResult := downloadedVideoAmount + skippedVideoArchiveAmount + skippedVideoPresentAmount + skippedVideoMaxSizeAmount
            currentBarValue := tmpResult * 100 + partProgress
            ; Applies the changes to the GUI progress bar.
            downloadStatusProgressBar.Value := currentBarValue
        }
        Else
        {
            ; This makes sure that the progress animation is still displayed.
            downloadStatusProgressBar.Value := maximumBarValue - 1
        }
        parsedLines++
    }
    ; When the loop reaches the file end it will check if the console log has reached it's end.
    ; In other terms if the downloads have completed or not.
    While (ProcessExist(hiddenConsolePID))
    {
        ; Saves the content of the download log file.
        ; Because the console only adds content it is a reliable method to detect added data to the .txt file.
        oldFileContent := FileRead(A_Temp . "\yt_dlp_download_log.txt")
        ; Wait for the console log to be changed.
        Sleep(5000)
        newFileContent := FileRead(A_Temp . "\yt_dlp_download_log.txt")

        If (oldFileContent != newFileContent && booleanDownloadTerminated = false)
        {
            ; If there is new data.
            Goto startOfFileReadLoop
        }
    }
    ; Download finish section.
    downloadStatusText.Text := "Final video processing..."
    ; Makes sure the log powershell windows is closed as well.
    Try
    {
        WinClose("ahk_pid " . visualPowershellPID)
    }
    Sleep(500)
    If (booleanDownloadTerminated = true)
    {
        downloadStatusProgressBar.Value := 0
        downloadStatusText.Text := "Download canceled."
    }
    Else
    {
        downloadStatusProgressBar.Value := maximumBarValue
        If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = true)
        {
            downloadStatusText.Text := "Playlist mode: " . downloadedVideoAmount . " video(s) processed."
        }
        Else
        {
            downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
        }
    }
    If (downloadOptionsGUI_SubmitObject.enableSilentDownloadModeCheckbox != true)
    {
        MsgBox("Total video amount: " . videoAmount .
            "`nSkipped Videos (already in archive): " . skippedVideoArchiveAmount .
            "`nSkipped Videos (already present): " . skippedVideoPresentAmount .
            "`nSkipped Videos (too large): " . skippedVideoMaxSizeAmount .
            "`nDownloaded Videos: " . downloadedVideoAmount, "Download Summary", "O Iconi T5")
    }
}

; Adds time, date and further information into the text files. Might also make .JSON comment files prettier in the future.
postProcessDownloadFiles()
{
    tmpConfig := readConfigFile("DOWNLOAD_PATH")
    If (readConfigFile("DELETE_EMPTY_DOWNLOAD_FOLDERS_AFTER_DOWNLOAD") = true
        && downloadOptionsGUI_SubmitObject.UseDefaultDownloadLocationCheckbox = true)
    {
        ; Prepares for the upcomming download folder content check.
        tmpPath := tmpConfig . "\" . downloadTime . "\media\*.*"
        If (!FileExist(tmpPath))
        {
            SplitPath(tmpPath, , &outDir)
            SplitPath(outDir, , &outDir)
            Try
            {
                DirDelete(outDir, true)
            }
            Return
        }
    }
    ; Moves and renames all important text files into the download directory.
    Try
    {
        If (FileExist(A_Temp . "\yt_dlp_download_log.txt"))
        {
            FileCopy(A_Temp . "\yt_dlp_download_log.txt", readConfigFile("DOWNLOAD_LOG_FILE_LOCATION"), true)
        }
        If (downloadOptionsGUI_SubmitObject.UseDefaultDownloadLocationCheckbox = true)
        {
            If (FileExist(A_Temp . "\yt_dlp_download_log.txt"))
            {
                ; Better alternative for FileCopy because it will append instead of overwrite the old data.
                FileAppend(FileRead(A_Temp . "\yt_dlp_download_log.txt") . "`n`n#Download time: " . downloadTime
                    . "`n`n##################################################`n`n",
                    tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_log.txt")
            }
            If (FileExist(readConfigFile("DOWNLOAD_ARCHIVE_LOCATION")))
            {
                FileAppend(FileRead(readConfigFile("DOWNLOAD_ARCHIVE_LOCATION")) . "`n`n#: " . downloadTime
                    . "`n`n##################################################`n`n",
                    tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_archive.txt")
            }
            SplitPath(readConfigFile("URL_FILE_LOCATION"), , &outDir)
            If (FileExist(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt"))
            {
                FileAppend(FileRead(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt") . "`n`n#Download time: " . downloadTime
                    . "`n`n##################################################`n`n",
                    tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_YT_URLS.txt")
            }
        }
        Else
        {
            If (FileExist(A_Temp . "\yt_dlp_download_log.txt"))
            {
                SplitPath(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit, &outFolderName)
                ; Better alternative for FileCopy because it will append instead of overwrite the old data.
                FileAppend(FileRead(A_Temp . "\yt_dlp_download_log.txt") . "`n`n#Download time: " . downloadTime
                    . "`n`n##################################################`n`n",
                    downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_log.txt")
            }
            If (FileExist(readConfigFile("DOWNLOAD_ARCHIVE_LOCATION")))
            {
                SplitPath(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit, &outFolderName)
                FileAppend(FileRead(readConfigFile("DOWNLOAD_ARCHIVE_LOCATION")) . "`n`n#Download time: " . downloadTime
                    . "`n`n##################################################`n`n",
                    downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_archive.txt")
            }
            SplitPath(readConfigFile("URL_FILE_LOCATION"), , &outDir)
            If (FileExist(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt"))
            {
                SplitPath(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit, &outFolderName)
                FileAppend(FileRead(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt") . "`n`n#Download time: " . downloadTime
                    . "`n`n##################################################`n`n",
                    downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_YT_URLS.txt")
            }
        }
    }
    Catch
    {
        MsgBox("Malfunction while writing to download log file.", "Warning !", "O Icon! T1.5")
    }

    ; Creates the download summary text file.
    Try
    {
        If (downloadOptionsGUI_SubmitObject.UseDefaultDownloadLocationCheckbox = true)
        {
            FileAppend("##################################################`n`nTotal video amount: " . videoAmount .
                "`nSkipped Videos (already in archive): " . skippedVideoArchiveAmount .
                "`nSkipped Videos (already present): " . skippedVideoPresentAmount .
                "`nSkipped Videos (too large): " . skippedVideoMaxSizeAmount .
                "`nDownloaded Videos: " . downloadedVideoAmount . "`n`n",
                tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_summary.txt")
            If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = true)
            {
                FileAppend("#Notice that playlist mode has been activated, so the values might not be correct. \(.-.)/`n`n`n",
                    tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_summary.txt")
            }
            Else
            {
                FileAppend("`n", tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_summary.txt")
            }
            FileAppend("#Download time: " . downloadTime . "`n`n##################################################`n`n",
                tmpConfig . "\" . downloadTime . "\[" . downloadTime . "]_download_summary.txt")
        }
        Else
        {
            SplitPath(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit, &outFolderName)
            FileAppend("##################################################`n`nTotal video amount: " . videoAmount .
                "`nSkipped Videos (already in archive): " . skippedVideoArchiveAmount .
                "`nSkipped Videos (already present): " . skippedVideoPresentAmount .
                "`nSkipped Videos (too large): " . skippedVideoMaxSizeAmount .
                "`nDownloaded Videos: " . downloadedVideoAmount . "`n`n",
                downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_summary.txt")
            If (downloadOptionsGUI_SubmitObject.downloadWholePlaylistsCheckbox = true)
            {
                FileAppend("#Notice that playlist mode has been activated, so the values might not be correct. \(.-.)/`n`n`n",
                    downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_summary.txt")
            }
            Else
            {
                FileAppend("`n", downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_summary.txt")
            }
            FileAppend("#Download time: " . downloadTime . "`n`n##################################################`n`n",
                downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\[" . outFolderName . "]_download_summary.txt")
        }
    }

    If (downloadOptionsGUI_SubmitObject.downloadVideoCommentsCheckbox = true)
    {
        ; This is the work around for the missing --paths option for comments in yt-dlp (WIP).
        If (downloadOptionsGUI_SubmitObject.UseDefaultDownloadLocationCheckbox = true)
        {
            If (!DirExist(tmpConfig . "\" . downloadTime . "\comments"))
            {
                Try
                {
                    DirCreate(tmpConfig . "\" . downloadTime . "\comments")
                    Sleep(500)
                }
            }
            Try
            {
                FileMove(tmpConfig . "\" . downloadTime . "\media\*.info.json",
                    tmpConfig . "\" . downloadTime . "\comments", true)
            }
        }
        Else
        {
            If (!DirExist(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\comments"))
            {
                Try
                {
                    DirCreate(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\comments")
                    Sleep(500)
                }
            }
            Try
            {
                FileMove(downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\media\*.info.json",
                    downloadOptionsGUI_SubmitObject.CustomDownloadLocationEdit . "\comments", true)
            }
        }
        ; :=> JSON prettifier here in the future.
    }
}

; Works together with handleMainGUI_MenuCheckHandler() to enable / disable certain hotkeys depending on
; the checkmark array generated by the script GUI.
toggleHotkey(pStateArray)
{
    stateArray := pStateArray
    ; This array will be manipulated depending on the values in the array above.
    static onOffArray := ["On", "On", "On", "On", "On", "On", "On"]

    Loop (stateArray.Length)
    {
        ; The old stateArray.Get(A_Index) = true condition has been replaced for compatibillity reasons.
        If (InStr(stateArray.Get(A_Index), "0", 0))
        {
            onOffArray.InsertAt(A_Index, "Off")
        }
        Else If (InStr(stateArray.Get(A_Index), "1", 0))
        {
            onOffArray.InsertAt(A_Index, "On")
        }
    }

    Hotkey(readConfigFile("TERMINATE_SCRIPT_HK"), (*) => terminateScriptPrompt(), onOffArray.Get(1))
    Hotkey(readConfigFile("RELOAD_SCRIPT_HK"), (*) => reloadScriptPrompt(), onOffArray.Get(2))
    Hotkey(readConfigFile("NOT_USED_HK"), (*) => MsgBox("Not implemented yet", , "T2"), onOffArray.Get(3))
    Hotkey(readConfigFile("DOWNLOAD_HK"), (*) => startDownload(buildCommandString()), onOffArray.Get(4))
    Hotkey(readConfigFile("URL_COLLECT_HK"), (*) => saveSearchBarContentsToFile(), onOffArray.Get(5))
    Hotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK"), (*) => saveVideoURLDirectlyToFile(), onOffArray.Get(6))
    Hotkey(readConfigFile("CLEAR_URL_FILE_HK"), (*) => clearURLFile(), onOffArray.Get(7))
}

clearURLFile()
{
    If (FileExist(readConfigFile("URL_FILE_LOCATION")))
    {
        manageURLFile()
    }
    Else
    {
        MsgBox("The  URL file does not exist !`n`nIt was probably already cleared.", "Error !", "O Icon! T3")
    }
}

; Opens only one instance each
openURLFile()
{
    Try
    {
        If (WinExist("YT_URLS.txt - Editor"))
        {
            WinActivate()
            Return true
        }
        Run(readConfigFile("URL_FILE_LOCATION"))
        Return true
    }
    Catch
    {
        MsgBox("The URL file does not exist !`n`nIt was probably already cleared.", "Error !", "O Icon! T3")
    }
}

openURLBackupFile()
{
    Try
    {
        If (WinExist("YT_URLS_BACKUP.txt - Editor"))
        {
            WinActivate()
            Return true
        }
        Run(readConfigFile("URL_BACKUP_FILE_LOCATION"))
        Return true
    }
    Catch
    {
        MsgBox("The URL backup file does not exist !`n`nIt was probably not generated yet.", "Error !", "O Icon! T3")
    }
}

openURLBlacklistFile(pBooleanShowPrompt := false)
{
    booleanShowPrompt := pBooleanShowPrompt
    If (booleanShowPrompt = true)
    {
        result := MsgBox("Do you really want to replace the current`n`nblacklist file with a new one ?", "Warning !", "YN Icon! T10")
        If (result = "Yes")
        {
            Try
            {
                If (!DirExist(scriptBaseFilesLocation . "\deleted"))
                {
                    DirCreate(scriptBaseFilesLocation . "\deleted")
                }
                SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                ; Calls checkBlackListFile() in order to create a new blacklist file.
                checkBlackListFile("generateFile", false)
                Return
            }
            Catch
            {
                ; Calls checkBlackListFile() in order to create a new blacklist file.
                checkBlackListFile("generateFile", false)
                Return
            }
        }
        Else
        {
            Return
        }
    }
    Try
    {
        If (WinExist("YT_BLACKLIST.txt - Editor"))
        {
            WinActivate()
            Return true
        }
        Else If (FileExist(readConfigFile("BLACKLIST_FILE_LOCATION")))
        {
            Run(readConfigFile("BLACKLIST_FILE_LOCATION"))
            Return true
        }
        Else
        {
            ; Calls checkBlackListFile() in order to create a new blacklist file.
            checkBlackListFile("generateFile")
        }
    }
    Catch
    {
        MsgBox("The URL blacklist file does not exist !`n`nIt was probably not generated yet.", "Error !", "O Icon! T3")
    }
}

openConfigFile()
{
    Try
    {
        If (WinExist("ytdownloader.ini - Editor"))
        {
            WinActivate()
            Return true
        }
        Else If (FileExist(configFileLocation))
        {
            Run(configFileLocation)
            Return true
        }
        Else
        {
            createDefaultConfigFile()
        }
    }
    Catch
    {
        MsgBox("The script's config file does not exist !`n`nA fatal error has occurred.", "Error !", "O Icon! T3")
    }
}

; Saves a lot of coding by using a switch to determine which MsgBox has to be shown.
deleteFilePrompt(pFileName)
{
    fileName := pFileName
    result := MsgBox("Would you like to delete the " . fileName . " ?", "Delete " . fileName, "YN Icon! 8192 T10")
    If (result = "Yes")
    {
        If (!DirExist(scriptBaseFilesLocation . "\deleted"))
        {
            DirCreate(scriptBaseFilesLocation . "\deleted")
        }
        Try
        {
            Switch (fileName)
            {
                Case "URL-File":
                    {
                        c := "URL_FILE_LOCATION"
                        tmpConfig := readConfigFile("URL_FILE_LOCATION")
                        SplitPath(tmpConfig, &outFileName)
                        FileMove(tmpConfig, scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                    }
                Case "URL-Backup-File":
                    {
                        c := "URL_BACKUP_FILE_LOCATION"
                        SplitPath(readConfigFile("URL_BACKUP_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_BACKUP_FILE_LOCATION"), scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                    }
                Case "URL-Blacklist-File":
                    {
                        c := "BLACKLIST_FILE_LOCATION"
                        SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                    }
                Case "latest download":
                    {
                        If (DirExist(lastDownloadPath))
                        {
                            DirMove(lastDownloadPath, scriptBaseFilesLocation . "\deleted\" . downloadTime, true)
                        }
                        Else
                        {
                            MsgBox("No downloaded files from`ncurrent session found.", "Error !", "O Icon! T2.5")
                        }
                    }
                Default:
                    {
                        MsgBox("Invalid delete request.", "Error !", "O IconX T2")
                    }
            }
        }
        ; In case something goes wrong this will try to resolve the issue.
        Catch
        {
            If (FileExist(scriptBaseFilesLocation . "\deleted\" . outFileName) && FileExist(scriptBaseFilesLocation . "\" . outFileName))
            {
                result := MsgBox("The " . fileName . " was found in the deleted directory."
                    "`n`nDo you want to overwrite it ?", "Warning !", "YN Icon! T10")
                If (result = "Yes")
                {
                    FileDelete(scriptBaseFilesLocation . "\deleted\" . outFileName)
                    FileMove(readConfigFile(c), scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                }
            }
            Else
            {
                MsgBox("The " . fileName . " does not exist !`n`nIt was probably not generated yet.", "Warning !", "O Icon! T3")
            }
        }
    }
}

reloadScriptPrompt()
{
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui()
    textField := reloadScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n reloaded in " . i . " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := reloadScriptGUI.Add("Progress", "w280 h20 x10 y100", 0)
    buttonOkay := reloadScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := reloadScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    reloadScriptGUI.Show("w300 h200")

    buttonOkay.OnEvent("Click", (*) => Reload())
    buttonCancel.OnEvent("Click", (*) => reloadScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    Try
    {
        while (i >= 0)
        {
            ; Makes the progress bar feel smoother.
            Loop 20
            {
                progressBar.Value += 1.25
                Sleep(50)
            }

            If (i = 1)
            {
                textField.Text := "The script will be`n reloaded in " . i . " second."
            }
            Else
            {
                textField.Text := "The script will be`n reloaded in " . i . " seconds."
            }
            i--
        }
        textField.Text := "The script has been reloaded."
        saveGUISettingsAsPreset("last_settings", true)
        Sleep(100)
        Reload()
        ExitApp()
        ExitApp()
    }
}

terminateScriptPrompt()
{
    ; Number in seconds.
    i := 4

    terminateScriptGUI := Gui()
    textField := terminateScriptGUI.Add("Text", "r3 w260 x20 y40", "The script will be`n terminated in " . i . " seconds.")
    textField.SetFont("s12")
    textField.SetFont("bold")
    progressBar := terminateScriptGUI.Add("Progress", "w280 h20 x10 y100 cRed backgroundBlack", 0)
    buttonOkay := terminateScriptGUI.Add("Button", "Default w80 x60 y170", "Okay")
    buttonCancel := terminateScriptGUI.Add("Button", "w80 x160 y170", "Cancel")
    terminateScriptGUI.Show("w300 h200")

    buttonOkay.OnEvent("Click", (*) => ExitApp())
    buttonCancel.OnEvent("Click", (*) => terminateScriptGUI.Destroy())

    ; The try statement is needed to protect the code from crashing because
    ; of the destroyed GUI when the user presses cancel.
    Try
    {
        while (i >= 0)
        {
            ; Makes the progress bar feel smoother.
            Loop 20
            {
                progressBar.Value += 1.25
                Sleep(50)
            }

            If (i = 1)
            {
                textField.Text := "The script will be`n terminated in " . i . " second."
            }
            Else
            {
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

; Tries to find an existing process via a wildcard.
; Note: Currently only supports wildcards containing the
; beginning of the wanted process.
findProcessWithWildcard(pWildcard)
{
    wildcard := pWildcard
    SplitPath(wildcard, , , &outExtension, &outNameNoExt)
    allRunningProcessesNameArray := []
    allRunningProcessesPathArray := []
    ; Filles the array with all existing process names.
    For (Process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process"))
    {
        allRunningProcessesNameArray.InsertAt(A_Index, Process.Name)
        allRunningProcessesPathArray.InsertAt(A_Index, Process.CommandLine)
    }
    ; Traveres through every object to compare it with the wildcard.
    For (v in allRunningProcessesNameArray)
    {
        ; For example if you are process called "VideoDownloader.development-build-6.exe" it
        ; would be sufficient to search for "VideoDownloader.exe" as the [*]+ part allows an
        ; undefined amount of characters to appear between the wildcard name and it's extension.
        ; The condition below makes sure that it does not find the current instance of this script as a proces.
        If (RegExMatch(v, outNameNoExt . ".*." . outExtension) != 0 && v != A_ScriptName)
        {
            tmp := StrReplace(allRunningProcessesPathArray.Get(A_Index), '"')
            result := MsgBox("There is currently another instance of this script running."
                "`nName: [" . v . "]`nPath: [" . tmp . "]`nContinue at your own risk !"
                "`nPress Retry to terminate the other instance.", "Attention !", "ARI Icon! 262144 T15")

            Switch (result)
            {
                Case "Retry":
                    {
                        Try
                        {
                            ProcessClose(v)
                            If (ProcessWaitClose(v, 5) != 0)
                            {
                                Throw ("Could not close the other process.")
                            }
                        }
                        Catch
                        {
                            MsgBox("Could not close process :`n"
                                v . "`nTerminating script.", "Error !", "O IconX T1.5")
                            ExitApp()
                        }
                    }
                Case "Ignore":
                    {
                        ; This option is not recommended because the script is not supposed to run with multiple instances.
                        Return
                    }
                Default:
                    {
                        MsgBox("Terminating script.", "Script Status", "O Iconi T1.5")
                        ExitApp()
                    }
                    ; Stops after the first match.
                    Break
            }
        }
    }
}

; A small tour to show off the basic functions of this script.
scriptTutorial()
{
    result := MsgBox("Would you like to have a short tutorial on how to select videos and some basic functionality?",
        "VideoDownloader Tutorial", "YN Iconi 262144")
    If (result = "No")
    {
        result := MsgBox("Press YES if you want to disable the tutorial`nfor the next time you run this script.",
            "VideoDownloader Tutorial", "YN Iconi 262144")
        If (result = "Yes")
        {
            editConfigFile("ASK_FOR_TUTORIAL", false)
        }
        Return
    }

    MsgBox("Hello there... General Kenobi!`n`nWelcome to the tutorial."
        "`nIt will try to teach you the basic functionality of this script but keep this in mind: "
        "`n`nFirstly this script is still in development phase so bugs are to be expected."
        "`nSecondly PLEASE be patient and do not spam buttons like a maniac. Wait for the script to process and if"
        "`nnothing happens even after 3-5 seconds you could try pressing the button or hotkey again."
        "`n`nWith that being said, let's begin with the tutorial."
        "`n`nPress Okay to continue.",
        "VideoDownloader Tutorial - Important", "O Iconi 262144")

    MsgBox("This script acts as a simple GUI for yt-dlp.`n`nYou can open the main GUI by pressing: "
        "`n" . expandHotkey(readConfigFile("MAIN_GUI_HK"))
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Open Main GUI", "O Iconi 262144")
    If (WinWaitActive("ahk_id " . mainGUI.Hwnd, , 5) = 0)
    {
        Hotkey_openMainGUI()
        MsgBox("The script opened the main GUI for you.`n`nNo worries, you will get the hang of it soon :)",
            "VideoDownloader Tutorial - Open Main GUI", "O Iconi 262144 T3")
    }
    MsgBox("The main GUI contains a lot of features and menus.`nYou can take some time to explore them by yourself."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Use Main GUI", "O Iconi 262144")
    If (!WinExist("ahk_id " . mainGUI.Hwnd))
    {
        Hotkey_openMainGUI()
    }
    Else
    {
        WinActivate("ahk_id " . mainGUI.Hwnd)
    }
    MsgBox("As you may have noticed, there is a submenu called`n[Active Hotkeys...] when you expand the [Options] menu."
        "`n`nOn the one hand, it provides a useful list`nof most available hotkeys"
        "`nand on the other hand, it enables you to select which hotkeys you want to activate or deactivate."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Use Main GUI", "O Iconi 262144")
    MsgBox("If you want to select a video there are multiple options.`nYou either open the video and press: "
        "`n[" . expandHotkey(readConfigFile("URL_COLLECT_HK")) . "].`n`nAlternatively hover over the video thumbnail and press: "
        "`n[" . expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")) . "]."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Select Video(s)", "O Iconi 262144")
    MsgBox("It is possible to manually open the URL file`n(with the main GUI) and edit the saved URLs."
        "`n`nThe current location of the URL file is: [" . readConfigFile("URL_FILE_LOCATION") . "]."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Find Selected Video(s)", "O Iconi 262144")
    MsgBox("To download the URLs saved in the file this script uses`na Python command line application called yt-dlp."
        "`nThe download options GUI is used to pass the parameters`nto the console and specify various download options."
        "`n`nPress [" . expandHotkey(readConfigFile("OPTIONS_GUI_HK")) . "] to open the download options GUI."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Download Selected Video(s)", "O Iconi 262144")
    If (WinWaitActive("ahk_id " . downloadOptionsGUI.Hwnd, , 5) = 0)
    {
        Hotkey_openOptionsGUI()
        MsgBox("The script opened the download options GUI for you.`n`nNo worries, you will get the hang of it soon :)",
            "VideoDownloader Tutorial - Open Download Options GUI", "O Iconi 262144 T3")
    }
    MsgBox("If you see the download options GUI for the very first time,`nit might be a bit overwhelming, but once you have"
        "`nused this script a few times it will become more familiar.`n`nQuick tip: "
        "`nHover over an option with the mouse cursor`nto gain extra information."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Use Download Options GUI", "O Iconi 262144")
    MsgBox("Take a look at the top right corner of the download options GUI."
        "`nPresets can be used to store the current configuration`nand load it later on."
        "`n`nPressing the save button twice will store the current preset"
        "`nas the default one which will be loaded at the beginning."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Use Download Options GUI", "O Iconi 262144")
    MsgBox("Depending on your selected options the script will`nclear the URL file and save the content to a backup"
        "`nfile to possibly restore it."
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - After the Finished Download", "O Iconi 262144")
    MsgBox("To change the script hotkeys and script file paths`nyou can use the config file to do so."
        "`n`nThe location of the config file is always :`n[" . configFileLocation . "]"
        "`n`nPress Okay to continue.", "VideoDownloader Tutorial - Using the Config File", "O Iconi 262144")
    result := MsgBox("You have reached the end of the tutorial.`n`nRemember that you can access all important files"
        "`nfrom the main GUI window.`n`nWould you like to disable this tutorial for the`nnext time you run this script ?"
        "`n`nPress Cancel to start the tutorial again.", "VideoDownloader Tutorial - End", "YNC Iconi 262144")
    Switch (result)
    {
        Case "Yes":
            {
                editConfigFile("ASK_FOR_TUTORIAL", false)
            }
        Case "Cancel":
            {
                scriptTutorial()
            }
    }
}

chooseScriptWorkingDirectory()
{
    path := DirSelect(, , "Select a working directory.")
    If (checkForWritingRights(path) = true)
    {
        If (!InStr(path, "yt_dlp_autohotkey_gui_files"))
        {
            Return path . "\yt_dlp_autohotkey_gui_files"
        }
        Else
        {
            Return path
        }
    }
    Else
    {
        result := MsgBox("This path cannot be used because it requires administrative permissions to write.`n`n"
            "Please select another path or press [Ignore] to use the default directory which is:`n"
            "[" . A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files]",
            "Invalid Working Directory", "ARI Icon! Default2")
        Switch (result)
        {
            Case "Retry":
                {
                    Return chooseScriptWorkingDirectory()
                }
            Case "Ignore":
                {
                    Return A_AppData . "\LeoTN\VideoDownloader\yt_dlp_autohotkey_gui_files"
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
}

checkForWritingRights(pPath)
{
    path := pPath

    Try
    {
        FileAppend("checkForWritingRights", path . "\tmp.txt")
        FileDelete(path . "\tmp.txt")
    }
    Catch As error
    {
        If (InStr(error.message, "(5) "))
        {
            Return false
        }
        Else
        {
            MsgBox("checkForWritingRights():`n" . error.message)
            ExitApp()
        }
    }
    Return true
}

checkForValidPath(pPath)
{
    path := pPath

    Try
    {
        FileGetAttrib(path)
    }
    Catch As error
    {
        If (InStr(error.message, "(2s) "))
        {
            Return false
        }
        Else
        {
            MsgBox("checkForValidPath():`n" . error.message)
            ExitApp()
        }
    }
    Return true
}

checkInternetConnection()
{
    ; Checks if the user has an established Internet connection.
    Try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://www.google.com", false)
        httpRequest.Send()

        If (httpRequest.Status = 200)
        {
            Return true
        }
    }

    Return false
}

arrayToString(pArray)
{
    array := pArray
    string := "["

    For index, value in array
    {
        string .= value
        if (index < array.Length)
        {
            string .= ","
        }
    }

    string .= "]"
    Return string
}

stringToArray(pString)
{
    string := pString
    string := SubStr(string, 2, StrLen(string) - 2)
    array := StrSplit(string, ",")

    Return array
}

expandHotkey(pHotkey)
{
    hotkey := pHotkey
    hotkey := StrReplace(hotkey, "+", "SHIFT + ")
    hotkey := StrReplace(hotkey, "^", "CTRL + ")
    hotkey := StrReplace(hotkey, "!", "ALT + ")
    hotkey := StrReplace(hotkey, "#", "WIN + ")

    Return hotkey
}