#SingleInstance Force
SendMode "Input"
CoordMode "Mouse", "Client"
#Warn Unreachable, Off

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
    Return
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
    Hotkey(readConfigFile("DOWNLOAD_HK"), (*) => startDownload(commandString), "On")

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
    static flipflop := true
    If (!WinExist("ahk_id " . mainGUI.Hwnd))
    {
        mainGUI.Show("w300 h200")
        flipflop := false
        Return
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
    Return
}

; Hotkey support function to open the script download options GUI.
Hotkey_openOptionsGUI()
{
    static flipflop := true
    If (!WinExist("ahk_id " . downloadOptionsGUI.Hwnd))
    {
        downloadOptionsGUI.Show("w500 h405")
        flipflop := false
        Return
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
    Return
}

/*
FUNCTION SECTION
-------------------------------------------------
*/

; Important function which executes the built command string by pasting it into the console.
startDownload(pCommandString, pBooleanSilent := hideDownloadCommandPromptCheckbox.Value)
{
    global consoleId
    stringToExecute := pCommandString
    booleanSilent := pBooleanSilent

    If (booleanSilent = 1)
    {
        ; Execute the command line command and wait for it to be finished.
        RunWait(A_ComSpec " /c " . stringToExecute, , "Hide")
    }
    Else
    {
        ; Enables the user to access the command and to review potential errors thrown by yt-dlp.
        Run(A_ComSpec, , , &consoleId)
        WinWaitActive("ahk_pid " . consoleId)
        If (WinActive("ahk_pid " . consoleId))
        {
            Send(stringToExecute)
            Sleep(50)
            Send("{Enter}")
        }
        Else
        {
            WinActivate("ahk_pid " . consoleId)
            Sleep(100)
            Send(stringToExecute)
            Sleep(50)
            Send("{Enter}")
        }
        Sleep(1000)
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
    static flipflop := true
    boolean := pBoolean
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
    Hotkey(readConfigFile("DOWNLOAD_HK"), (*) => startDownload(commandString), onOffArray[4])
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
    Return
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
    Return
}

openURLBackUpFile()
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
    Return
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
    Return
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
    Return
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
                        c := 2
                        SplitPath(readConfigFile("URL_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "URL-BackUp-File":
                    {
                        c := 3
                        SplitPath(readConfigFile("URL_BACKUP_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("URL_BACKUP_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "URL-Blacklist-File":
                    {
                        c := 4
                        SplitPath(readConfigFile("BLACKLIST_FILE_LOCATION"), &outFileName)
                        FileMove(readConfigFile("BLACKLIST_FILE_LOCATION"), A_WorkingDir . "\files\deleted\" . outFileName)
                    }
                Case "Downloaded Videos":
                    {
                        c := 5
                        MsgBox("Not implemented yet")
                        ; Possible in the future.
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
    Return
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
        Return
    }
    Catch
    {
        Return
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
        Return
    }
    Catch
    {
        Return
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