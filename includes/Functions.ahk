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
        if (RegExMatch(v, outNameNoExt . ".*." . outExtension) != 0 && v != A_ScriptName) {
            tmp := StrReplace(allRunningProcessesPathArray.Get(A_Index), '"')
            result := MsgBox("There is currently another instance of this script running."
                "`nName: [" . v . "]`nPath: [" . tmp . "]`nContinue at your own risk!"
                "`nPress [Retry] to terminate the other instance.", "VD - Multiple Script Instances Found!",
                "ARI Icon! 262144")

            switch (result) {
                case "Retry":
                {
                    try
                    {
                        ProcessClose(v)
                        if (ProcessWaitClose(v, 5) != 0) {
                            throw ("Could not close the other process.")
                        }
                    }
                    catch {
                        MsgBox("Could not close process :`n"
                            v . "`nTerminating script.", "VD - Close Process - Error!", "O IconX T3 262144")
                        ExitApp()
                    }
                }
                case "Ignore":
                {
                    ; This option is not recommended because the script is not supposed to run with multiple instances.
                    return
                }
                Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O Iconi T1.5")
                    ExitApp()
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

    oldVersion := versionFullName
    backupDate := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    backupFolderName := "VideoDownloader_backup_from_version_" . oldVersion . "_at_" . backupDate
    sourceDirectory := A_ScriptDir
    destinationDirectory := pBackupParentDirectory . "\" . backupFolderName
    ; All subdirectories and files are copied. The folder "VideoDownloader_old_version_backups" is excluded.
    parameterString := "`"" . sourceDirectory . "`" `"" . destinationDirectory . "`" /E /XD `"" . sourceDirectory .
        "\VideoDownloader_old_version_backups`""
    ; Waits 3 seconds before starting the backup process to ensure that the main script has exited already.
    Run('cmd.exe /c "timeout /t 3 /nobreak && robocopy ' . parameterString . '"', , "Hide")
    exitScriptWithNotification()
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
@returns [String] (alt) "_result_no_update_available", when no update is available.
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
    }
    ; Maybe more cases in the future.
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
