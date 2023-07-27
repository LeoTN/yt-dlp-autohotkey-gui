#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
SetWorkingDir A_ScriptDir
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
    Hotkey(readConfigFile("NOT_USED_HK"), (*) => MsgBox("Not implemented yet"), "Off")

    ; Hotkey for clearing the URL file.
    Hotkey(readConfigFile("CLEAR_URL_FILE_HK"), (*) => clearURLFile(), "Off")
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

; Hotkey support function to open the script uninstall GUI.
Hotkey_openUninstallGUI()
{
    If (A_IsCompiled = true)
    {
        ; Asks for administrative permissions to complete without interruption.
        fullCommandLine := DllCall("GetCommandLine", "str")
        If not (A_IsAdmin || RegExMatch(fullCommandLine, " /restart(?!\S)"))
        {
            FileAppend("Uninstall process", baseFilesLocation . "\NoPermissionsForUninstall.txt")
            Try
            {
                Run '*RunAs "' A_ScriptFullPath '" /restart'
            }
            Catch
            {
                Return
            }
            ExitApp()
            ExitApp()
        }

        static flipflop := true
        If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
        {
            uninstallGUI.Show("w400 h200")
            flipflop := false
        }
        Else If (flipflop = false && WinActive("ahk_id " . uninstallGUI.Hwnd))
        {
            uninstallGUI.Hide()
            flipflop := true
        }
        Else
        {
            WinActivate("ahk_id " . uninstallGUI.Hwnd)
        }
    }
    Else
    {
        MsgBox("You can only uninstall the script if"
            "`n`nyou are using the compiled version.", "Error !", "O IconX T3")
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
            ; Starts the tool tip timer to react upon the user hovering over gui elements.
            SetTimer(handleDownloadOptionsGUI_toolTipManager, 1000)
        }
        Else If (flipflop = false && WinActive("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            downloadOptionsGUI.Hide()
            flipflop := true
            ; Stops the tool tip timer.
            SetTimer(handleDownloadOptionsGUI_toolTipManager, 0)
        }
        Else
        {
            WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
        }
    }
}

/*
FUNCTION SECTION
-------------------------------------------------
*/

; Important function which executes the built command string by pasting it into the console.
startDownload(pCommandString, pBooleanSilent := hideDownloadCommandPromptCheckbox.Value)
{
    If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
    {
        Hotkey_openOptionsGUI()
    }
    Else
    {
        WinActivate("ahk_id " . downloadOptionsGUI.Hwnd)
    }
    stringToExecute := pCommandString
    booleanSilent := pBooleanSilent
    static isDownloading := false
    If (isDownloading = true)
    {
        Return MsgBox("There is a download process running already.`n`nPlease wait for it to finish or cancel it.",
            "Information", "O Icon! 4096 T3")
    }
    Else
    {
        isDownloading := true
    }
    If (!FileExist(readConfigFile("URL_FILE_LOCATION")) && useTextFileForURLsCheckbox.Value = 1)
    {
        isDownloading := false
        MsgBox("No URL file found. You can save`nURLs by clicking on a video and `npressing " .
            expandHotkey(readConfigFile("URL_COLLECT_HK")), "Download status", "O Icon! 8192")
        Return
    }
    If (booleanSilent = 1)
    {
        ; Execute the command line command and wait for it to be finished.
        displayAndLogConsoleCommand(stringToExecute, true)
        monitorDownloadProgress(true)
    }
    Else
    {
        ; Enables the user to access the command and to review potential errors thrown by yt-dlp.
        displayAndLogConsoleCommand(stringToExecute, false)
        monitorDownloadProgress(true)
    }
    If (downloadVideoSubtitlesCheckbox.Value = 1)
    {
        ; This is the work around for the missing --paths option for comments in yt-dlp (WIP).
        If (!DirExist(readConfigFile("DOWNLOAD_PATH") . "\" . downloadTime . "\comments"))
        {
            Try
            {
                DirCreate(readConfigFile("DOWNLOAD_PATH") . "\" . downloadTime . "\comments")
                Sleep(500)
            }
        }
        Try
        {
            FileMove(readConfigFile("DOWNLOAD_PATH") . "\" . downloadTime . "\video\*.info.json",
                readConfigFile("DOWNLOAD_PATH") . "\" . downloadTime . "\comments\*.info.json")
        }
    }
    If (clearURLFileAfterDownloadCheckbox.Value = 1 && ignoreAllOptionsCheckbox.Value != 1)
    {
        manageURLFile(false)
    }
    If (terminateScriptAfterDownloadCheckbox.Value = 1)
    {
        isDownloading := false
        saveGUISettingsAsPreset("last_settings", true)
        MsgBox("The download process has reached it's end.`n`nTerminating script.", "Download status", "O Iconi 262144 T2")
        ExitApp()
        ExitApp()
    }
    Else
    {
        isDownloading := false
        saveGUISettingsAsPreset("last_settings", true)
        MsgBox("The download process has reached it's end.", "Download status", "O Iconi 262144 T2")
    }
}

displayAndLogConsoleCommand(pCommand, pBooleanSilent)
{
    command := pCommand
    booleanSilent := pBooleanSilent
    global hiddenConsolePID
    global visualPowershellPID

    Run(A_ComSpec . " /c " . command . " > " . A_Temp . "\yt_dlp_download_log.txt", , "Min", &hiddenConsolePID)
    ProcessWait(hiddenConsolePID)

    If (booleanSilent = false)
    {
        ; Deletes the old log file.
        Try
        {
            FileDelete(A_Temp . "\yt_dlp_download_log.txt")
        }
        ; The powershell script now waits for the hook file.
        Run("powershell.exe -noExit -ExecutionPolicy Bypass -file " . baseFilesLocation . "\library\MonitorHookFile.ps1"
            , , "Min", &visualPowershellPID)
        WinWait("ahk_pid " . visualPowershellPID)
        WinActivate("ahk_pid " . visualPowershellPID)
    }
}

; Checks the download log file for status updates and reacts by updating the download options GUI progress bar and text fields.
monitorDownloadProgress(pBooleanNewDownload := false)
{
    booleanNewDownload := pBooleanNewDownload

    global booleanDownloadTerminated := false

    static currentBarValue := 0
    static oldCurrentBarValue := 0
    static partProgress := 0
    ; Remembers the amount of parsed lines to begin directly with the new generated ones.
    static parsedLines := 0
    If (booleanNewDownload = true)
    {
        static videoAmount := readFile(readConfigFile("URL_FILE_LOCATION"), true).Length
        static downloadedVideoAmount := 0
        static maximumBarValue := videoAmount * 100
        parsedLines := 0
        currentBarValue := 0
        oldCurrentBarValue := 0
        partProgress := 0
        downloadStatusProgressBar.Value := 0
        downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
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
    }

    downloadStatusProgressBar.Opt("Range0-" . maximumBarValue)

    Loop Read (A_Temp . "\yt_dlp_download_log.txt")
    {
        ; All previous lines will be skipped.
        If (parsedLines >= A_Index)
        {
            Continue
        }
        ; Scanns the output from the console and extracts the download progress percentage values.
        If (RegExMatch(A_LoopReadLine, "S)[\d]+[.][\d{1}][%]", &outMatch) != 0)
        {
            ; This avoids filling the progress bar to fast because of too many 100% messages from yt-dlp.
            If (partProgress <= 99.99)
            {
                outString := outMatch[]
                outStringReady := StrReplace(outString, "%")
                partProgress := Number(outStringReady)
                currentBarValue := oldCurrentBarValue + partProgress
                downloadStatusProgressBar.Value := currentBarValue
            }
        }
        If (partProgress >= 99.99 && downloadedVideoAmount <= videoAmount)
        {
            ; This message only appears when the previous video processing has been finished.
            If (InStr(A_LoopReadLine, "Extracting URL: https://www") && downloadedVideoAmount != videoAmount)
            {
                ; "[youtube:tab]" is considered to be ignored, as it only shows up when downloading a playlist.
                If (!InStr(A_LoopReadLine, "[youtube:tab] Extracting URL: https://www"))
                {
                    oldCurrentBarValue += 100
                    downloadedVideoAmount++
                    partProgress := 0
                    downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
                }
            }
        }
        ; The already recorded message is important because the progress bar has to move up one video to avoid issues.
        Else If (InStr(A_LoopReadLine, "has already been recorded in the archive"))
        {
            oldCurrentBarValue += 100
            downloadedVideoAmount++
            partProgress := 0
            downloadStatusText.Text := "One video has already been recorded in the archive file."
            Sleep(2500)
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
            Return monitorDownloadProgress()
        }
        ; Checks if the background process does not exist to determine the end of the download.
        Else If (!ProcessExist(hiddenConsolePID))
        {
            Break
        }
    }
    Try
    {
        FileCopy(A_Temp . "\yt_dlp_download_log.txt", readConfigFile("DOWNLOAD_LOG_FILE_LOCATION"), true)
    }
    Catch
    {
        MsgBox("Could not write downloag log file.", "Warning !", "O IconX T1.5")
    }
    ; When the loop reaches the final video this function is not called again to add +1 to the downloaded video amount.
    ; If all videos are downloaded, the following conditon is therefore true.
    If (downloadedVideoAmount + 1 = videoAmount)
    {
        downloadedVideoAmount := videoAmount
        downloadStatusText.Text := "Final video processing..."
        Sleep(2000)
    }
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
        downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
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
        ; The old stateArray[A_Index] = true condition has been replaced for compatibillity reasons.
        If (InStr(stateArray[A_Index], "0", 0))
        {
            onOffArray[A_Index] := "Off"
        }
        Else If (InStr(stateArray[A_Index], "1", 0))
        {
            onOffArray[A_Index] := "On"
        }
    }

    Hotkey(readConfigFile("TERMINATE_SCRIPT_HK"), (*) => terminateScriptPrompt(), onOffArray[1])
    Hotkey(readConfigFile("RELOAD_SCRIPT_HK"), (*) => reloadScriptPrompt(), onOffArray[2])
    Hotkey(readConfigFile("NOT_USED_HK"), (*) => MsgBox("Not implemented yet"), onOffArray[3])
    Hotkey(readConfigFile("DOWNLOAD_HK"), (*) => startDownload(buildCommandString()), onOffArray[4])
    Hotkey(readConfigFile("URL_COLLECT_HK"), (*) => saveSearchBarContentsToFile(), onOffArray[5])
    Hotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK"), (*) => saveVideoURLDirectlyToFile(), onOffArray[6])
    Hotkey(readConfigFile("CLEAR_URL_FILE_HK"), (*) => clearURLFile(), onOffArray[7])
}

clearURLFile()
{
    If (FileExist(readConfigFile("URL_FILE_LOCATION")))
    {
        manageURLFile()
    }
    Else
    {
        MsgBox("The  URL file does not exist !	`n`nIt was probably already cleared.", "Error !", "O Icon! T3")
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
        MsgBox("The URL file does not exist !	`n`nIt was probably already cleared.", "Error !", "O Icon! T3")
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
        MsgBox("The URL backup file does not exist !	`n`nIt was probably not generated yet.", "Error !", "O Icon! T3")
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
                If (!DirExist(baseFilesLocation . "\deleted"))
                {
                    DirCreate(baseFilesLocation . "\deleted")
                }
                SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), baseFilesLocation . "\deleted\" . outFileName, true)
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
        MsgBox("The URL blacklist file does not exist !	`n`nIt was probably not generated yet.", "Error !", "O Icon! T3")
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
        MsgBox("The script's config file does not exist !	`n`nA fatal error has occured.", "Error !", "O Icon! T3")
    }
}

; Saves a lot of coding by using a switch to determine which MsgBox has to be shown.
deleteFilePrompt(pFileName)
{
    fileName := pFileName
    result := MsgBox("Would you like to delete the " . fileName . " ?", "Delete " . fileName, "YN Icon! 8192 T10")
    If (result = "Yes")
    {
        If (!DirExist(baseFilesLocation . "\deleted"))
        {
            DirCreate(baseFilesLocation . "\deleted")
        }
        Try
        {
            Switch (fileName)
            {
                Case "URL-File":
                    {
                        c := "URL_FILE_LOCATION"
                        SplitPath(readConfigFile("URL_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_FILE_LOCATION"), baseFilesLocation . "\deleted\" . outFileName)
                    }
                Case "URL-Backup-File":
                    {
                        c := "URL_BACKUP_FILE_LOCATION"
                        SplitPath(readConfigFile("URL_BACKUP_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_BACKUP_FILE_LOCATION"), baseFilesLocation . "\deleted\" . outFileName)
                    }
                Case "URL-Blacklist-File":
                    {
                        c := "BLACKLIST_FILE_LOCATION"
                        SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), baseFilesLocation . "\deleted\" . outFileName)
                    }
                Case "latest download":
                    {
                        Try
                        {
                            Switch (useDefaultDownloadLocationCheckbox.Value)
                            {
                                Case 0:
                                {
                                    FileMove(customDownloadLocation.Value . '\' . downloadTime, baseFilesLocation
                                        . "\deleted\" . downloadTime)
                                }
                                Case 1:
                                {
                                    Run(readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime, baseFilesLocation
                                        . "\deleted\" . downloadTime)
                                }
                            }
                        }
                        Catch
                        {
                            MsgBox("No downloaded files from `ncurrent session found.", "Delete download error !", "O Icon! T2.5")
                        }
                    }
                Default:
                    {
                        terminateScriptPrompt()
                    }
            }
        }
        ; In case something goes wrong this will try to resolve the issue.
        Catch
        {
            If (FileExist(baseFilesLocation . "\deleted\" . outFileName) && FileExist(baseFilesLocation . "\" . outFileName))
            {
                result := MsgBox("The " . fileName . " was found in the deleted directory."
                    "`n`nDo you want to overwrite it ?", "Warning !", "YN Icon! T10")
                If (result = "Yes")
                {
                    FileDelete(baseFilesLocation . "\deleted\" . outFileName)
                    FileMove(readConfigFile(c), baseFilesLocation . "\deleted\" . outFileName)
                }
            }
            Else
            {
                MsgBox("The " . fileName . " does not exist !	`n`nIt was probably not generated yet.", "Error !", "O Icon! T3")
            }
        }
    }
}

reloadScriptPrompt()
{
    ; Number in seconds.
    i := 4

    reloadScriptGUI := Gui(, "Script reload")
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

    terminateScriptGUI := Gui(, "Script termination")
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
; Note : Currently only supports wildcards containing the
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
                "`nName : [" . v . "]`nPath : [" . tmp . "]`nContinue at your own risk !"
                "`nPress Try Again to terminate the other instance.", "Attention !", "CTC Icon! 262144 T15")

            Switch (result)
            {
                Case "Continue":
                    {
                        ; Do nothing.
                    }
                Case "TryAgain":
                    {
                        Try
                        {
                            ProcessClose(v)
                            If (ProcessWaitClose(v, 5) != 0)
                            {
                                Throw ("Could not close the other process")
                            }
                        }
                        Catch
                        {
                            MsgBox("Could not close process :`n"
                                v . "`nTerminating script.", "Error !", "O IconX T1.5")
                            ExitApp()
                        }
                    }
                Default:
                    {
                        MsgBox("Terminating script.", "Script status", "O Iconi T1.5")
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
        "Video Downloader Tutorial", "YN Iconi 8192")
    If (result = "No")
    {
        result := MsgBox("Press YES if you want to disable the tutorial`nfor the next time you run this script.",
            "Video Downloader Tutorial", "YN Iconi 8192")
        If (result = "Yes")
        {
            editConfigFile("ASK_FOR_TUTORIAL", false)
        }
        Return
    }

    MsgBox("This script acts as a simple GUI for yt-dlp.`n`nYou can open the main GUI by pressing : "
        "`n" . expandHotkey(readConfigFile("MAIN_GUI_HK")), "Video Downloader Tutorial - Open Main GUI", "O Iconi 8192 T10")
    If (WinWaitActive("ahk_id " . mainGUI.Hwnd, , 5) = 0)
    {
        Hotkey_openMainGUI()
        MsgBox("The script opened the main GUI for you.`n`nNo worries, you will get the hang of it soon :)",
            "Video Downloader Tutorial - Open Main GUI", "O Iconi T3")
    }
    MsgBox("The main GUI contains a lot of features and menus.`nYou may take some time to explore them by yourself."
        "`n`nPress Okay to continue.", "Video Downloader Tutorial - Use Main GUI", "O Iconi")
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
        "`nand on the other hand, it enables you to select which hotkeys you want to activate or deactivate.",
        "Video Downloader Tutorial - Use Main GUI", "O Iconi")
    MsgBox("If you want to select a video there are multiple options.`nYou either open the video and press : "
        "`n[" . expandHotkey(readConfigFile("URL_COLLECT_HK")) . "].`n`nAlternatively hover over the video thumbnail and press : "
        "`n[" . expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")) . "].",
        "Video Downloader Tutorial - Select Video(s)", "O Iconi")
    MsgBox("It is possible to manually open the URL file`n(with the main GUI) and edit the saved URLs."
        "`n`nThe current location of the URL file is : [" . readConfigFile("URL_FILE_LOCATION") . "].",
        "Video Downloader Tutorial - Find Selected Video(s)", "O Iconi")
    MsgBox("To download the URLs saved in the file this script uses`na python command line application called yt-dlp."
        "`nThe download options GUI is used to pass the parameters`nto the console and specify various download options."
        "`n`nPress [" . expandHotkey(readConfigFile("OPTIONS_GUI_HK")) . "] to open the download options GUI.",
        "Video Downloader Tutorial - Download Selected Video(s)", "O Iconi T25")
    If (WinWaitActive("ahk_id " . downloadOptionsGUI.Hwnd, , 5) = 0)
    {
        Hotkey_openOptionsGUI()
        MsgBox("The script opened the download options GUI for you.`n`nNo worries, you will get the hang of it soon :)",
            "Video Downloader Tutorial - Open Download Options GUI", "O Iconi T3")
    }
    MsgBox("If you see the download options GUI for the very first time,`nit might be a bit overwhelming but once you have"
        "`nused this script a few times it will become more familiar.`n`nQuick tip : "
        "`nHover over an option with the mouse cursor`nin order to gain extra information."
        "`nNote : `nThis does only work if there is `nno download process running at the moment.",
        "Video Downloader Tutorial - Use Download Options GUI", "O Iconi")
    MsgBox("Take a look at the top right corner of the download options GUI."
        "`nPresets can be used to store the current configuration `nand load it later on."
        "`n`nPressing the save button twice will store the current preset"
        "`nas the default one which will be loaded at the beginning.",
        "Video Downloader Tutorial - Use Download Options GUI", "O Iconi")
    MsgBox("Depending on your selected options the script will `nclear the URL file and save the content to a backup"
        "`nfile to possibly restore it.", "Video Downloader Tutorial - After the Finished Download", "O Iconi T10")
    MsgBox("To change the script hotkeys and script file paths`nyou can use the config file to do so."
        "`n`nThe location of the config file is always :`n[" . configFileLocation . "]",
        "Video Downloader Tutorial - Using the Config File", "O Iconi")

    result := MsgBox("You have reached the end of the tutorial.`n`nRemember that you can access all important files"
        "`nfrom the main GUI window.`n`nWould you like to disable this tutorial for the`nnext time you run this script ?"
        "`n`nPress Cancel to start the tutorial again.", "Video Downloader Tutorial - End", "YNC Iconi")


    If (result = "Yes")
    {
        editConfigFile("ASK_FOR_TUTORIAL", false)
    }
    Else If (result = "Cancel")
    {
        scriptTutorial()
    }
}

; Steps to uninstall the script.
uninstallScript()
{
    tmp1 := uninstallYTDLPCheckbox.Value
    tmp2 := uninstallPythonCheckbox.Value
    tmp3 := uninstallAllDownloadedFilesCheckbox.Value
    tmp4 := uninstallAllCreatedFilesCheckbox.Value
    uninstallProgressBarMaxValue := 0

    result := MsgBox("Are you sure that you want to continue`n`nthe script removal process ?",
        "Warning !", "YN Icon! 262144 T10")
    If (result != "Yes")
    {
        Return
    }
    ; Sets the uninstall progress bar max value according to the select uninstall steps.
    Loop (4)
    {
        uninstallProgressBarMaxValue += %"tmp" . A_Index% * 100
    }
    uninstallProgressBar.Opt("Range0-" . uninstallProgressBarMaxValue)
    uninstallStartButton.Opt("+Disabled")
    uninstallCancelButton.Opt("+Disabled")

    ; Uninstalls dependencies and other stuff.
    If (tmp1 = 1)
    {
        uninstallStatusBar.SetText("Currently uninstalling yt-dlp...")
        RunWait(A_ComSpec " /c pip uninstall yt-dlp --no-input")
        uninstallProgressBar.Value += 100
    }
    If (tmp2 = 1)
    {
        If (FileExist(baseFilesLocation . "\config\video_downloader_python_install_log.txt"))
        {
            uninstallStatusBar.SetText("Currently uninstalling python...")
            Loop Read (baseFilesLocation . "\config\video_downloader_python_install_log.txt")
            {
                If (InStr(A_LoopReadLine, "Python"))
                {
                    ; Removes the minor version digit.
                    tmp_fileRead := RegExReplace(A_LoopReadLine, ".[0-9]$")
                    Break
                }
            }
            RunWait(A_ComSpec ' /c winget uninstall "' . tmp_fileRead . '"')
            uninstallProgressBar.Value += 100
        }
        Else
        {
            If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
            {
                Hotkey_openUninstallGUI()
            }
            Else
            {
                WinActivate("ahk_id " . uninstallGUI.Hwnd)
            }
            uninstallStatusBar.SetText("Warning ! Could not uninstall python !")
            Sleep(2500)
            uninstallStatusBar.SetText("You may uninstall it manually.")
            Sleep(2500)
            uninstallProgressBar.Value += 100
        }
    }
    If (tmp3 = 1)
    {
        uninstallStatusBar.SetText("Deleting downloaded files...")
        Try
        {
            FileRecycle(baseFilesLocation . "\download")
        }
        Try
        {
            FileRecycle(readConfigFile("DOWNLOAD_PATH", false))
        }
        Catch
        {
            uninstallStatusBar.SetText("Warning ! Could not delete downloaded files !")
            Sleep(2500)
            uninstallStatusBar.SetText("You may delete them manually.")
            Sleep(2500)
        }
        uninstallProgressBar.Value += 100
    }
    If (tmp4 = 1)
    {
        evacuationError := false
        uninstallStatusBar.SetText("Deleting script files...")
        ; This means that the remaining download files have to be evacuated.
        If (tmp3 = false)
        {
            Try
            {
                DirMove(baseFilesLocation . "\download", A_Desktop . "\yt_dlp_autohotkey_gui_downloads_after_uninstall", 1)
            }
            Catch
            {
                evacuationError := true
                uninstallStatusBar.SetText("Warning ! Could not save downloaded files !")
                Sleep(2500)
                uninstallStatusBar.SetText("The script file deletion process will be skipped.")
                Sleep(2500)
            }
            Try
            {
                If (evacuationError = false)
                {
                    FileRecycle(baseFilesLocation)
                }
            }
            uninstallProgressBar.Value += 100
        }
        Else
        {
            Try
            {
                FileRecycle(baseFilesLocation)
            }
            Catch
            {
                uninstallStatusBar.SetText("Warning ! Could not delete script files !")
                Sleep(2500)
                uninstallStatusBar.SetText("The script file deletion process will be skipped.")
                Sleep(2500)
            }
        }
        uninstallProgressBar.Value += 100
    }
    Sleep(3000)
    uninstallStatusBar.SetText("Finishing removal process...")
    Sleep(2000)
    If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
    {
        Hotkey_openUninstallGUI()
    }
    Else
    {
        WinActivate("ahk_id " . uninstallGUI.Hwnd)
    }
    uninstallStatusBar.SetText("Successfully uninstalled script. Until next time :')")
    Sleep(5000)
    ExitApp()
    ExitApp()
}

; Usefull to avoid invalid file names in the config file.
detectIfWorkingDirIsDrive(pInput)
{
    input := pInput

    SplitPath(input, , &outDir, , , &outDrive)
    ; This means the script working directory is only a drive name.
    If (outDrive = outDir)
    {
        newPath := outDrive . "\yt_dlp_autohotkey_gui_files"
    }
    Else
    {
        newPath := input . "\yt_dlp_autohotkey_gui_files"
    }
    Return newPath
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