#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

; Beginning of the file manager functions.

/*
Save search bar contents to text file.
@returns [boolean] Depending on the function's success.
*/
saveSearchBarContentsToFile()
{
    Loop (3)
    {
        Send("^{l}")
        Sleep(100)
        Send("^{c}")

        If (ClipWait(0.5))
        {
            clipboardContent := A_Clipboard
            Sleep(100)
            Send("{Escape}")
            Break
        }
    }
    If (IsSet(clipboardContent))
    {
        result := writeToURLFile(clipboardContent)
        Switch (result)
        {
            Case "duplicate_url":
                {
                    MsgBox("Same URL selected twice.", "VD - Duplicate URL!", "O Iconi T1.5")
                    Return false
                }
            Case "already_in_blacklist_file":
                {
                    MsgBox("Selected URL is blacklisted.", "VD - Blacklistet URL!", "O Iconi T1.5")
                    Return false
                }
            Case true:
            {
                Return true
            }
            Default:
            {
                MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid return value from writeToURLFile() received [" . result . "]."
                    , "VD - [" . A_ThisFunc . "()]", "Icon! 262144")
                Return false
            }
        }
    }
    Else
    {
        MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T1.5")
    }
}

/*
Saves the video URL directly by hovering over the video thumbnail on the start page.
@returns [boolean] Depending on the function's success.
*/
saveVideoURLDirectlyToFile()
{
    videoURL := getBrowserURLUnderMouseCursor()
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    ; False if URL is invalid or not found.
    If (videoURL)
    {
        result := writeToURLFile(videoURL)
        Switch (result)
        {
            Case "duplicate_url":
                {
                    MsgBox("Same URL selected twice.", "VD - Duplicate URL!", "O Iconi T0.8")
                    Return false
                }
            Case "already_in_blacklist_file":
                {
                    MsgBox("Selected URL is blacklisted.", "VD - Blacklistet URL!", "O Iconi T1")
                    Return false
                }
            Case true:
            {
                Return true
            }
            Default:
            {
                MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid return value from writeToURLFile() received [" . result . "]."
                    , "VD - [" . A_ThisFunc . "()]", "Icon! 262144")
                Return false
            }
        }
    }
    MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T0.8")
    Return false
}

/*
Basically a support function for saveVideoURLDirectlyToFile().
@returns [boolean] false in case of failure and [String] if an URL has been found.
*/
getBrowserURLUnderMouseCursor()
{
    ; These three variables contain the matching values for each role type.
    role_Shortcut := 30
    role_Text := 42
    role_Group := 20

    Try
    {
        Loop (3)
        {
            ; Get the video element.
            videoElementAccOrigin := Acc.ElementFromPoint()
        }
        videoElementAccOriginParent := videoElementAccOrigin.Parent
        ; Child and origin section.
        Try
        {
            ; Added to check if the element directly under the cursor contains an URL.
            videoURL := videoElementAccOrigin.Value
            ; The /@ is located in the youtuber channel link, which should not be selected.
            If ((InStr(videoURL, "https://") || InStr(videoURL, "http://")) && !InStr(videoURL, "/@"))
            {
                Return videoURL
            }
        }
        Try
        {
            ; Looks for the URL in the originally selected element.
            videoElementValue := videoElementAccOrigin.Normalize({ Role: role_Shortcut, not: { Value: "" } })
            videoURL := videoElementValue.Value
            ; The /@ is located in the youtuber channel link, which should not be selected.
            If ((InStr(videoURL, "https://") || InStr(videoURL, "http://")) && !InStr(videoURL, "/@"))
            {
                Return videoURL
            }
        }
        Try
        {
            ; Looks for the URL in the originally selected element.
            videoElementValue := videoElementAccOrigin.Normalize({ Role: role_Text, not: { Value: "" } })
            videoURL := videoElementValue.Value
            ; The /@ is located in the youtuber channel link, which should not be selected.
            If ((InStr(videoURL, "https://") || InStr(videoURL, "http://")) && !InStr(videoURL, "/@"))
            {
                Return videoURL
            }
        }
        ; Parent section.
        Try
        {
            ; Tries to find matching childs in the parent of the originally selected element.
            videoElementAccChildShortcut := videoElementAccOriginParent.FindElement({ Role: role_Shortcut, not: { Value: "" } })
            ; Looks for the URL in the "brothers" of the originally selected element.
            videoElementValue := videoElementAccChildShortcut.Normalize({ Role: role_Shortcut, not: { Value: "" } })
            videoURL := videoElementValue.Value
            ; The /@ is located in the youtuber channel link, which should not be selected.
            If ((InStr(videoURL, "https://") || InStr(videoURL, "http://")) && !InStr(videoURL, "/@"))
            {
                Return videoURL
            }
        }
        Try
        {
            ; Looks for the URL in the "brothers" of the originally selected element.
            videoElementValue := videoElementAccChildShortcut.Normalize({ Role: role_Text, not: { Value: "" } })
            videoURL := videoElementValue.Value
            ; The /@ is located in the youtuber channel link, which should not be selected.
            If ((InStr(videoURL, "https://") || InStr(videoURL, "http://")) && !InStr(videoURL, "/@"))
            {
                Return videoURL
            }
        }
        Return false
    }
    Catch
    {
        Return false
    }
}

/*
Writes entries to the URL file. It will also create one, if it doesn't exist.
@param pContent [String] Should be a valid URL.
@returns [boolean] true if the operation was successful or [String] depending on the outcome.
*/
writeToURLFile(pContent)
{
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    If (!FileExist(tmpConfig))
    {
        FileAppend("#Made by Donnerbaer`n", tmpConfig)
    }
    tmp := readFile(tmpConfig, true)
    i := tmp.Length
    ; Check if the URL already exists in the file.
    Loop (i)
    {
        If (pContent = tmp.Get(A_Index))
        {
            Return "duplicate_url"
        }
    }
    If (checkBlackListFile(pContent))
    {
        Return "already_in_blacklist_file"
    }
    FileAppend(pContent . "`n", tmpConfig)
    Return true
}

/*
Reads a specified file and creates an array object with it.
Based on "`n" it will split the document.
@param pFileLocation[String] Should be the path to a valid.TXT file.
@param pBooleanCheckIfURL [boolean] If set to true, only valid URLS will be read into the array.
@returns [array] containing each line of the file in a seperate slot.
*/
readFile(pFileLocation, pBooleanCheckIfURL := false)
{
    Try
    {
        URLs := FileRead(pFileLocation)
        fileArray := []
        i := 1
        For (k, v in StrSplit(URLs, "`n"))
        {
            If (!InStr(v, "://") && pBooleanCheckIfURL)
            {
                Continue
            }
            If (v != "")
            {
                fileArray.InsertAt(i, v)
                i++
            }
        }
        Return fileArray
    }
    Catch As error
    {
        displayErrorMessage(error, , true)
    }
}

/*
Checks a given input if it exists on the blacklist.
@param pItemToCompare [String] A string (URL) to search in the blacklist file.
@param pBooleanShowPrompt [boolean] Show a prompt to create a new blacklist file, if necessary.
@returns [boolean] True, if the item was found in the blacklist file. False otherwise.
*/
checkBlackListFile(pItemToCompare, pBooleanShowPrompt := true)
{
    global booleanFirstTimeLaunch

    ; This content will be added to the new created blacklist file.
    ; You can add content to the ignore list by adding it to the .txt file
    ; or directly to the template array.
    templateArray := ["https://www.youtube.com", "https://www.youtube.com/"]
    If (!FileExist(readConfigFile("BLACKLIST_FILE_LOCATION")))
    {
        ; This creates the blacklist file silently because it is the script setup.
        If (booleanFirstTimeLaunch)
        {
            pBooleanShowPrompt := false
        }
        result := ""
        If (pBooleanShowPrompt)
        {
            result := MsgBox("Could not find blacklist file.`n`nDo you want to create one ?",
                "VD - Missing Blacklist File!", "YN Icon! 262144")
        }
        If (result = "Yes" || !pBooleanShowPrompt)
        {
            Try
            {
                ; Creates the blacklist file with the template.
                Loop (templateArray.Length)
                {
                    FileAppend(templateArray.Get(A_Index) . "`n", readConfigFile("BLACKLIST_FILE_LOCATION"))
                }
            }
            Catch
            {
                MsgBox("Could not create blacklist file!`n`nCheck the config file for a valid path.",
                    "VD - Blacklist File Status - Error!", "O Icon! 262144")
                ExitApp()
            }
        }
        Else If (result = "No" || "Timeout")
        {
            Return false
        }
    }
    ; In case the blacklist file is broken.
    tmpArray := readFile(readConfigFile("BLACKLIST_FILE_LOCATION"))
    If (!tmpArray.Has(1))
    {
        FileDelete(readConfigFile("BLACKLIST_FILE_LOCATION"))
        Return checkBlackListFile(pItemToCompare, pBooleanShowPrompt)
    }

    ; Compare the item if it matches with the blacklist.
    ; NOTE: This search method is not case sensitive and
    ; it does not search like InStr()!
    blacklistArray := readFile(readConfigFile("BLACKLIST_FILE_LOCATION"))

    Loop (blacklistArray.Length)
    {
        If (pItemToCompare = blacklistArray.Get(A_Index))
        {
            Return true
        }
    }
    Return false
}

/*
Clears the content of the URL file and writes it to the URL backup file.
@param pBooleanShowPrompt [boolean] Show a prompt to confirm clearing the file.
@returns [boolean] True, if the item was found in the blacklist file. False otherwise.
*/
clearURLFile(pBooleanShowPrompt := true)
{
    tmpConfig := readConfigFile("URL_FILE_LOCATION")

    If (pBooleanShowPrompt)
    {
        If (!FileExist)
        {
            MsgBox("The URL file does not exist!`n`nIt was probably already cleared.", "VD - Missing URL File!", "O Icon! T3")
            Return false
        }
        result := MsgBox("Do you want to clear the URL file ?`n`nA backup will be created anyways.",
            "VD - Manage URL File", "YN Icon? 262144")
        Switch (result)
        {
            Case "Yes":
                {
                    Try
                    {
                        FileMove(tmpConfig, readConfigFile("URL_BACKUP_FILE_LOCATION"), true)
                        Return true
                    }
                    Catch As error
                    {
                        displayErrorMessage(error)
                    }
                }
        }
    }
    Else
    {
        Try
        {
            FileMove(tmpConfig, readConfigFile("URL_BACKUP_FILE_LOCATION"), true)
            Return true
        }
        Catch As error
        {
            displayErrorMessage(error)
        }
    }
}

; Restores the content from the URL backup file to the URL file.
restoreURLFile()
{
    If (!FileExist(readConfigFile("URL_BACKUP_FILE_LOCATION")))
    {
        MsgBox("The URL backup file does not exist!`n`nIt was probably not generated yet.", "VD - Missing URL Backup File!", "O Icon! T3")
        Return
    }
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    If (FileExist(tmpConfig))
    {
        result := MsgBox("The URL File already exists."
            "`nPress [Yes] to overwrite or [No] to append the`nbackup file to the original file.", "VD - Existing URL File - Warning!", "YNC Icon! 262144")
        Switch (result)
        {
            Case "Yes":
                {
                    FileCopy(readConfigFile("URL_BACKUP_FILE_LOCATION"), tmpConfig, true)
                }
            Case "No":
                {
                    If (InStr(FileRead(tmpConfig), "#Made by Donnerbaer"))
                    {
                        ; If the original URL file already contains the line, it will remove the corresponding line
                        ; from the backup file content.
                        tmp := StrReplace(FileRead(readConfigFile("URL_BACKUP_FILE_LOCATION")), "#Made by Donnerbaer", "#Appended here")
                    }
                    Else
                    {
                        tmp := FileRead(readConfigFile("URL_BACKUP_FILE_LOCATION"))
                    }
                    ; Appends the backup file content to the original file.
                    FileAppend(tmp, tmpConfig)
                }
        }
    }
    Else
    {
        FileCopy(readConfigFile("URL_BACKUP_FILE_LOCATION"), tmpConfig, true)
    }
}

/*
Opens the URL file.
@returns [boolean] Depeding on the function's success.
*/
openURLFile()
{
    tmpConfig := readConfigFile("URL_FILE_LOCATION")

    Try
    {
        If (FileExist(tmpConfig))
        {
            Run(tmpConfig)
            Return true
        }
        MsgBox("The URL file does not exist!`n`nIt was probably already cleared.", "VD - Missing URL File!", "O Icon! T3")
        Return false
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

/*
Opens the URL backup file.
@returns [boolean] Depeding on the function's success.
*/
openURLBackupFile()
{
    tmpConfig := readConfigFile("URL_BACKUP_FILE_LOCATION")

    Try
    {
        If (FileExist(tmpConfig))
        {
            Run(tmpConfig)
            Return true
        }
        MsgBox("The URL backup file does not exist!`n`nIt was probably not generated yet.", "VD - Missing URL Backup File!", "O Icon! T3")
        Return false
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

/*
Opens the URL blacklist file. Creates it, if necessary.
@param pBooleanShowPrompt [boolean] If set to true, will prompt the user to create a new blacklist file. Otherwise it creates
the file silently.
@returns [boolean] Depeding on the function's success.
*/
openURLBlacklistFile(pBooleanShowPrompt := false)
{
    tmpConfig := readConfigFile("BLACKLIST_FILE_LOCATION")

    If (pBooleanShowPrompt)
    {
        result := MsgBox("Do you really want to replace the current blacklist file with a new one ?", "VD - Replace Existing URL Blacklist File?", "YN Icon! 262144")
        If (result = "Yes")
        {
            Try
            {
                If (!DirExist(scriptBaseFilesLocation . "\deleted"))
                {
                    DirCreate(scriptBaseFilesLocation . "\deleted")
                }
                SplitPath(tmpConfig, &outFileName)
                FileMove(tmpConfig, scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                ; Calls checkBlackListFile() in order to create a new blacklist file.
                checkBlackListFile("generateFile", false)
                Return true
            }
            Catch
            {
                ; Calls checkBlackListFile() in order to create a new blacklist file.
                checkBlackListFile("generateFile", false)
                openURLBlacklistFile(pBooleanShowPrompt)
                Return true
            }
        }
        Else
        {
            MsgBox("The URL blacklist file does not exist!`n`nIt was probably not generated yet.", "VD - Missing URL Blacklist File!", "O Icon! T3")
            Return false
        }
    }
    Try
    {
        If (FileExist(tmpConfig))
        {
            Run(tmpConfig)
            Return true
        }
        Else
        {
            ; Calls checkBlackListFile() in order to create a new blacklist file.
            checkBlackListFile("generateFile")
            openURLBlacklistFile(pBooleanShowPrompt)
        }
    }
    Catch As error
    {
        displayErrorMessage(error)
    }
}

/*
Opens the config file.
@returns [boolean] Depeding on the function's success.
*/
openConfigFile()
{
    global configFileLocation

    Try
    {
        If (FileExist(configFileLocation))
        {
            Run(configFileLocation)
            Return true
        }
        Else
        {
            createDefaultConfigFile()
            Return true
        }
    }
    Catch As error
    {
        displayErrorMessage(error, "This error is rare.", true)
        ; Technically unreachable :D
        Return false
    }
}

/*
Saves a lot of coding by using a switch to determine which MsgBox has to be shown.
@param pFileName [String] Should be a valid code for a file to delete for example "URL-File".
*/
deleteFilePrompt(pFileName)
{
    result := MsgBox("Would you like to delete the " . pFileName . " ?", "VD - Delete " . pFileName . "?", "YN Icon! 262144")
    If (result = "Yes")
    {
        If (!DirExist(scriptBaseFilesLocation . "\deleted"))
        {
            DirCreate(scriptBaseFilesLocation . "\deleted")
        }
        Try
        {
            Switch (pFileName)
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
                Case "latest download":
                    {
                        If (DirExist(lastDownloadPath))
                        {
                            DirMove(lastDownloadPath, scriptBaseFilesLocation . "\deleted\" . downloadTime, true)
                        }
                        Else
                        {
                            MsgBox("No downloaded files from`ncurrent session found.", "VD - Missing File(s)!", "O Icon! T2.5")
                        }
                    }
                Default:
                    {
                        MsgBox("Invalid delete request.", "VD - Delete File Status - Error!", "O IconX T2 262144")
                    }
            }
        }
        ; In case something goes wrong this will try to resolve the issue.
        Catch
        {
            If (FileExist(scriptBaseFilesLocation . "\deleted\" . outFileName) && FileExist(scriptBaseFilesLocation . "\" . outFileName))
            {
                result := MsgBox("The " . pFileName . " was found in the deleted directory."
                    "`n`nDo you want to overwrite it ?", "VD - Overwrite Existing File(s)?", "YN Icon! 262144")
                If (result = "Yes")
                {
                    FileDelete(scriptBaseFilesLocation . "\deleted\" . outFileName)
                    FileMove(readConfigFile(c), scriptBaseFilesLocation . "\deleted\" . outFileName, true)
                }
            }
            Else
            {
                MsgBox("The " . pFileName . " does not exist!`n`nIt was probably not generated yet.", "VD - Missing File(s)!", "O Icon! T3")
            }
        }
    }
}