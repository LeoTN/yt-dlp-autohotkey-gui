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

    ; Hotkey to pause / continue the execution of the script.
    Hotkey(readConfigFile("PAUSE_CONTINUE_SCRIPT_HK"), (*) => MsgBox("Not implemented yet"), "Off")

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
            SetTimer(handleGUI_toolTipManager, 1000)
        }
        Else If (flipflop = false && WinActive("ahk_id " . downloadOptionsGUI.Hwnd))
        {
            downloadOptionsGUI.Hide()
            flipflop := true
            ; Stops the tool tip timer.
            SetTimer(handleGUI_toolTipManager, 0)
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
        If (booleanSilent != 1)
        {
            MsgBox("The download process has reached it's end.`n`nTerminating script.", "Download status", "O Iconi 262144 T2")
        }
        ExitApp()
        ExitApp()
    }
    Else
    {
        isDownloading := false
        saveGUISettingsAsPreset("last_settings", true)
        MsgBox("The download process has reached it's end.`n`nReloading script.", "Download status", "O Iconi 262144 T2")
        Reload()
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
        Run("powershell.exe -noExit -ExecutionPolicy Bypass -file " . A_WorkingDir . "\files\library\MonitorHookFile.ps1"
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
        static videoAmount := getCurrentURL(true, true)
        static downloadedVideoAmount := 0
        static maximumBarValue := videoAmount * 100
        parsedLines := 0
        currentBarValue := 0
        oldCurrentBarValue := 0
        partProgress := 0
        downloadStatusProgressBar.Value := 0
        downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
        Try
        {
            FileDelete(A_Temp . "\yt_dlp_download_log.txt")
        }
        ; Waits for the download log file to exist again.
        maxRetries := 10
        While (!FileExist(A_Temp . "\yt_dlp_download_log.txt"))
        {
            Sleep(1000)
            If (maxRetries <= 0)
            {
                MsgBox("Could not find hook file to track progress.`n`nTerminating script.", "Error !", "O IconX T1.5")
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
            outString := outMatch[]
            outStringReady := StrReplace(outString, "%")
            partProgress := Number(outStringReady)
            ; This avoids filling the progress bar to fast because of too many 100% messages from yt-dlp.
            If (partProgress >= 99.99)
            {
                Continue
            }
            currentBarValue := oldCurrentBarValue + partProgress
            downloadStatusProgressBar.Value := currentBarValue
        }
        If (partProgress >= 100 && downloadedVideoAmount <= videoAmount)
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
            downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
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
        MsgBox("Could not write downloag log file.", "Error !", "O IconX T1.5")
    }
    ; When the loop reaches the final video this function is not called again to add +1 to the downloaded video amount.
    ; If all videos are downloaded, the following conditon is therefore true.
    If (downloadedVideoAmount + 1 = videoAmount)
    {
        downloadedVideoAmount := videoAmount
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
        Return
    }
    Else
    {
        downloadStatusProgressBar.Value := maximumBarValue
        downloadStatusText.Text := "Downloaded " . downloadedVideoAmount . " out of " . videoAmount . " videos."
    }
}

; Enter true for the currentArrays length or false to receive the item in the array.
; The second optional boolean defines wether you want to create the currentURL_Array or not.
getCurrentURL(pBooleanGetLength := false, pBooleanCreateArray := false)
{
    booleanGetLength := pBooleanGetLength
    booleanCreateArray := pBooleanCreateArray
    static tmpArray := [""]
    static currentURL_Array := [""]
    If (booleanCreateArray = true)
    {
        currentURL_Array := readFile(readConfigFile("URL_FILE_LOCATION"), true)
    }
    If (booleanGetLength = true)
    {
        Return currentURL_Array.Length
    }
    Else If (getCurrentURL_DownloadSuccess(false) = true)
    {
        If (currentURL_Array.Length >= 1 && booleanGetLength = false)
        {
            tmpArray[1] := currentURL_Array.Pop()
            ; Checks if the item is empty inside the URLarray.
            If (tmpArray[1] = "")
            {
                tmpArray[1] := currentURL_Array.Pop()
                Return tmpArray[1]
            }
            Else
            {
                Return tmpArray[1]
            }
        }
        Else
        {
            Return
        }
    }
    ; Returns the last content of the tmpArray (most likely because download failed).
    Else If (getCurrentURL_DownloadSuccess(false) = false)
    {
        getCurrentURL_DownloadSuccess(true)
        Return tmpArray[1]
    }
}

; getCurrentURL() support function.
; If the download fails, you have to call the getCurrentURL function again, but it would have deleted one link even
; though it was never downloaded.
; This function prevents this error from happening, so that the seemingly deleted link will be reatached to the currentURL_Array.
; Enter true, to trigger the flipflop or false to get the last state.
getCurrentURL_DownloadSuccess(pBoolean)
{
    boolean := pBoolean
    static flipflop := true
    If (boolean = true)
    {
        flipflop := !flipflop
    }
    Return flipflop
}

; Works together with GUI_MenuCheckHandler() to enable / disable certain hotkeys depending on
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
    Hotkey(readConfigFile("PAUSE_CONTINUE_SCRIPT_HK"), (*) => MsgBox("Not implemented yet"), onOffArray[3])
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
                If (!DirExist(A_WorkingDir . "\files\deleted"))
                {
                    DirCreate(A_WorkingDir . "\files\deleted")
                }
                SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName, true)
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
        If (!DirExist(A_WorkingDir . "\files\deleted"))
        {
            DirCreate(A_WorkingDir . "\files\deleted")
        }
        Try
        {
            Switch (fileName)
            {
                Case "URL-File":
                    {
                        c := "URL_FILE_LOCATION"
                        SplitPath(readConfigFile("URL_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "URL-Backup-File":
                    {
                        c := "URL_BACKUP_FILE_LOCATION"
                        SplitPath(readConfigFile("URL_BACKUP_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_BACKUP_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "URL-Blacklist-File":
                    {
                        c := "BLACKLIST_FILE_LOCATION"
                        SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "latest download":
                    {
                        Try
                        {
                            Switch (useDefaultDownloadLocationCheckbox.Value)
                            {
                                Case 0:
                                {
                                    FileMove(customDownloadLocation.Value . '\' . downloadTime, A_WorkingDir
                                        . "\files\deleted\" . downloadTime)
                                }
                                Case 1:
                                {
                                    Run(readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime, A_WorkingDir
                                        . "\files\deleted\" . downloadTime)
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
            If (FileExist(A_WorkingDir . "\files\deleted\" . outFileName) && FileExist(A_WorkingDir . "\files\" . outFileName))
            {
                result := MsgBox("The " . fileName . " was found in the deleted directory."
                    "`n`nDo you want to overwrite it ?", "Warning !", "YN Icon! T10")
                If (result = "Yes")
                {
                    FileDelete(A_WorkingDir . "\files\deleted\" . outFileName)
                    FileMove(readConfigFile(c), A_WorkingDir . "\files\deleted\" . outFileName)
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
        Sleep(100)
        Reload()
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