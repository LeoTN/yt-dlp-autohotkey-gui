#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

; Beginning of the file manager functions.

; Save search bar contents to text file.
saveSearchBarContentsToFile()
{
    A_Clipboard := ""
    tmpConfig := readConfigFile("URL_FILE_LOCATION")

    Loop (3)
    {
        Send("^{l}")
        Sleep(100)
        Send("^{c}")

        If (ClipWait(2) = true)
        {
            clipboardContent := A_Clipboard
            Sleep(100)
            Send("{Escape}")
            Break
        }
    }
    If (FileExist(tmpConfig))
    {
        writeToURLFile(clipboardContent)
    }
    Else
    {
        FileAppend("#Made by Donnerbaer" . "`n", tmpConfig)
        writeToURLFile(clipboardContent)
    }
}

; Saves the video URL directly by hovering over the video thumbnail on the start page.
saveVideoURLDirectlyToFile()
{
    A_Clipboard := ""
    If (pressMatchingBrowserCopyURLHotkey() = false)
    {
        Return
    }
    If (ClipWait(0.4) = true)
    {
        clipboardContent := A_Clipboard
        tmpConfig := readConfigFile("URL_FILE_LOCATION")
        If (!FileExist(tmpConfig))
        {
            FileAppend("#Made by Donnerbaer" . "`n", tmpConfig)
            writeToURLFile(clipboardContent)
            Return
        }
        Else If (clipboardContent != "")
        {
            contentArray := readFile(tmpConfig, true)
            Loop (contentArray.Length)
            {
                If (clipboardContent = contentArray.Get(A_Index))
                {
                    MsgBox("Same URL selected twice.", "VD - Duplicate URL!", "O Iconi T1.5")
                    Return
                }
            }
            writeToURLFile(clipboardContent)
            Return
        }
    }
    MsgBox("No URL detected.", "VD - Missing URL!", "O Iconi T1.5")
}

pressMatchingBrowserCopyURLHotkey()
{
    /*
    Edge DE -> RC I Enter
    Edge ENG -> RC O Enter
    Chrome DE -> RC E
    Chrome ENG -> RC E
    Firefox DE -> RC K
    Firefox ENG -> RC L
    Opera GX DE -> RC L
    Opera GX ENG -> RC E
    */
    static browserName := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "browserName", "")
    static broswerLanguage := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "browserLanguage", "")
    browserHotkeyErrorcode := ""

    MouseClick("Right")
    ; Do not decrease value! May lead to unstable performance.
    Sleep(250)
    Switch (browserName)
    {
        Case "Firefox":
            {
                Switch (broswerLanguage)
                {
                    Case "Deutsch":
                        {
                            Send("k")
                        }
                    Case "English":
                        {
                            Send("l")
                        }
                    Case "Other":
                        {
                            browserHotkeyErrorcode := "no_support"
                        }
                    Default:
                        {
                            MsgBox("Invalid browser language found!", "VD - Browser Language - Warning!", "O Icon!")
                            Return false
                        }
                }
            }
        Case "Chrome":
            {
                Switch (broswerLanguage)
                {
                    Case "Deutsch":
                        {
                            Send("e")
                        }
                    Case "English":
                        {
                            Send("e")
                        }
                    Case "Other":
                        {
                            browserHotkeyErrorcode := "no_support"
                        }
                    Default:
                        {
                            MsgBox("Invalid browser language found!", "VD - Browser Language - Warning!", "O Icon!")
                            Return false
                        }
                }
            }
        Case "Edge":
            {
                Switch (broswerLanguage)
                {
                    Case "Deutsch":
                        {
                            Send("i")
                            ; Special case because the context menu in Edge is different.
                            If (ClipWait(0.4) = false)
                            {
                                Send("{Enter}")
                            }
                        }
                    Case "English":
                        {
                            Send("o")
                            ; Special case because the context menu in Edge is different.
                            If (ClipWait(0.4) = false)
                            {
                                Send("{Enter}")
                            }
                        }
                    Case "Other":
                        {
                            browserHotkeyErrorcode := "no_support"
                        }
                    Default:
                        {
                            MsgBox("Invalid browser language found!", "VD - Browser Language - Warning!", "O Icon!")
                            Return false
                        }
                }
            }
        Case "Opera GX":
            {
                Switch (broswerLanguage)
                {
                    Case "Deutsch":
                        {
                            Send("l")
                        }
                    Case "English":
                        {
                            Send("e")
                        }
                    Case "Other":
                        {
                            browserHotkeyErrorcode := "no_support"
                        }
                    Default:
                        {
                            MsgBox("Invalid browser language found!", "VD - Browser Language - Warning!", "O Icon!")
                            Return false
                        }
                }
            }
        Case "Other":
            {
                browserHotkeyErrorcode := "no_support"
            }
        Default:
            {
                MsgBox("Invalid browser name found!", "VD - Browser Name - Warning!", "O Icon!")
                Return false
            }
    }
    If (browserHotkeyErrorcode = "no_support")
    {
        MsgBox("You have selected a browser configuration that is currently not supported for this hotkey."
            . "`nYou can try changing the browser settings in the [Options] menu of the main GUI and see if the URL is saved. "
            . "If you would like to request support for your browser, please go to the GitHub page and create a request.`n`n"
            . "The request should contain the name of the browser, along with the corresponding download link. "
            . "Additionally, the hotkey to copy the link should be included.`n`nSimply put, when you right-click on a video "
            . "on the YouTube homepage, a browser context menu appears. This menu typically contains an option called [Copy Link]. "
            . "Try to find the key on the keyboard to select this option directly. The link to the video should then be "
            . "saved in the clipboard. If you have any questions, please include them in the request.", "VD - Unsupported Browser!", "O Iconi")
        Return false
    }
}

writeToURLFile(pContent)
{
    content := pContent
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    tmp := readFile(tmpConfig, true)
    ; Check if the URL already exists in the file.
    i := tmp.Length
    ; Content check loop.
    Loop (i)
    {
        If (content = tmp.Get(A_Index))
        {
            Return
        }
    }
    If (checkBlackListFile(content) = true)
    {
        Return
    }
    FileAppend(content . "`n", tmpConfig)
}

; Reads a specified file and creates an array object with it.
; Based on "`n" it will split the document.
; The parameter booleanCheckIfURL defines if you only want to include
; URLS and other links into the outcomming array.
; Returns the created array.
readFile(pFileLocation, pBooleanCheckIfURL := false)
{
    fileLocation := pFileLocation
    booleanCheckIfURL := pBooleanCheckIfURL
    Try
    {
        ; The loop makes sure, that only URLs are included into the array.
        URLs := FileRead(fileLocation)
        fileArray := []
        i := 1
        For k, v in StrSplit(URLs, "`n")
        {
            If (!InStr(v, "://") && booleanCheckIfURL = true)
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
    Catch
    {
        MsgBox("[" . A_ThisFunc "()] [ERROR] Could not read file!`nTerminating script.", "VD - [" . A_ThisFunc "()]", "IconX 262144")
        ExitApp()
    }
}

; Checks a given input if it exists on the blacklist.
; Returns true if a match was found and false otherwise.
; The parameter booleanShowPrompt sets if the user will receive
; the MsgBox asking about creating a new blacklist file.
checkBlackListFile(pItemToCompare, pBooleanShowPrompt := true)
{
    itemToCompare := pItemToCompare
    booleanShowPrompt := pBooleanShowPrompt
    ; This content will be added to the new created blacklist file.
    ; You can add content to the ignore list by adding it to the .txt file
    ; or directly to the template array.
    templateArray := ["https://www.youtube.com/"]
    If (!FileExist(readConfigFile("BLACKLIST_FILE_LOCATION")))
    {
        ; This creates the blacklist file silently because it is the script setup.
        If (booleanFirstTimeLaunch = true)
        {
            booleanShowPrompt := false
        }
        If (booleanShowPrompt = true)
        {
            result := MsgBox("Could not find blacklist file.`n`nDo you want to create one ?",
                "VD - Missing Blacklist File!", "YN Icon! 262144")
        }
        ; Only so that the if condition down under does not throw an error.
        If (IsSet(result) = false)
        {
            result := ""
        }
        If (result = "Yes" || booleanShowPrompt = false)
        {
            Try
            {
                ; Creates the blacklist file with the template.
                Loop (templateArray.Length)
                {
                    FileAppend(templateArray.Get(A_Index) . "`n", readConfigFile("BLACKLIST_FILE_LOCATION"))
                }
                checkBlackListFile(itemToCompare, booleanShowPrompt)
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
    ; In case something has changed in the blacklist file.
    tmpArray := readFile(readConfigFile("BLACKLIST_FILE_LOCATION"))
    If (!tmpArray.Has(1))
    {
        FileDelete(readConfigFile("BLACKLIST_FILE_LOCATION"))
        Return checkBlackListFile(itemToCompare)
    }
    Loop (templateArray.Length)
    {
        If (templateArray.Get(A_Index) != tmpArray.Get(A_Index))
        {
            FileDelete(readConfigFile("BLACKLIST_FILE_LOCATION"))
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
                MsgBox("Could not create blacklist file!`n`nNo one knows why.", "VD - Blacklist File Status - Error!", "O Icon! 262144")
                ExitApp()
            }
        }
    }
    ; Compare the item if it matches with the blacklist.
    ; NOTE: This search method is not case sensitive and
    ; it does not search like InStr() !
    blacklistArray := readFile(readConfigFile("BLACKLIST_FILE_LOCATION"))

    Loop (blacklistArray.Length)
    {
        If (itemToCompare = blacklistArray.Get(A_Index))
        {
            Return true
        }
    }
    Return false
}

manageURLFile(pBooleanShowPrompt := true)
{
    booleanShowPrompt := pBooleanShowPrompt
    tmpConfig := readConfigFile("URL_FILE_LOCATION")

    If (booleanShowPrompt = true)
    {
        result := MsgBox("Do you want to clear the URL file ?`n`nA backup will be created anyways.",
            "VD - Manage URL File", "YN Icon? 262144")
        ; When there is a prompt it is almost guaranteed not a download running so that this should work.
        If (result = "Yes")
        {
            Try
            {
                FileMove(tmpConfig, readConfigFile("URL_BACKUP_FILE_LOCATION"), true)
            }
            Catch
            {
                MsgBox("The URL file does not exist !`n`nIt was probably already cleared.", "VD - Missing URL File!", "O Icon! T3")
            }
        }
    }
    Else
    {
        Try
        {
            SplitPath(tmpConfig, , &outDir)
            FileMove(outDir . "\YT_URLS_CURRENTLY_DOWNLOADING.txt", readConfigFile("URL_BACKUP_FILE_LOCATION"), true)
        }
    }
}

restoreURLFile()
{
    If (!FileExist(readConfigFile("URL_BACKUP_FILE_LOCATION")))
    {
        MsgBox("The URL backup file does not exist !`n`nIt was probably not generated yet.", "VD - Missing URL Backup File!", "O Icon! T3")
        Return
    }
    tmpConfig := readConfigFile("URL_FILE_LOCATION")
    If (FileExist(tmpConfig))
    {
        result := MsgBox("The URL File already exists."
            "`nPress YES to overwrite or NO to append the`nbackup file to the original file.", "VD - Existing URL File - Warning!", "YNC Icon! 262144")
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