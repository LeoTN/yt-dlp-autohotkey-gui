#SingleInstance Force
SendMode "Input"
CoordMode "Mouse", "Client"
#Warn Unreachable, Off

global commandString := ""

createDownloadOptionsGUI()
{
    Global
    downloadOptionsGUI := Gui(, "Download Options")

    generalGroupbox := downloadOptionsGUI.Add("GroupBox", "w300 R3.2", "General Options")

    ignoreErrorsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20", "Ignore errors")
    abortOnErrorCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Abort on error")
    ignoreAllOptionsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Ignore all options")
    hideDownloadCommandPromptCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+110 yp-40", "Download in a background task")
    askForDownloadConfirmationCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Ask for download confirmation")
    enableFastDownloadModeCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Fast download mode")

    downloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-120 yp+20 w394 R9.3", "Download Options")

    limitDownloadRateText1 := downloadOptionsGUI.Add("Text", "xp+10 yp+20", "Maximum download rate `n in MB per second.")
    limitDownloadRateEdit := downloadOptionsGUI.Add("Edit", "yp+30")
    limitDownloadRateUpDown := downloadOptionsGUI.Add("UpDown")
    limitDownloadRateText2 := downloadOptionsGUI.Add("Text", "yp+25", "Enter 0 for no limitations.")
    higherRetryAmountCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Increase retry amount")
    downloadVideoDescriptionCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Download video description")
    downloadVideoCommentsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Download video commentary section")
    downloadVideoThumbnail := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Download video thumbnail")
    downloadVideoSubtitles := downloadOptionsGUI.Add("Checkbox", "yp+20", "Download the video's subtitles")

    chooseVideoFormatText := downloadOptionsGUI.Add("Text", "xp+250 yp-155", "Desired video format")
    downloadVideoFormatArray := ["mp4", "webm", "avi", "flv", "mkv", "mov"]
    chooseVideoFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1", downloadVideoFormatArray)

    downloadAudioOnlyCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5", "Download audio only")
    downloadAudioFormatArray := ["mp3", "wav", "m4a", "flac", "aac", "alac", "opus", "vorbis"]
    chooseAudioFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1", downloadAudioFormatArray)

    alwaysHighestQualityBothCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5 Checked", "Balance quality")
    prioritiseVideoQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Prefer video quality")
    prioritiseAudioQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Prefer audio quality")

    fileSystemGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-260 yp+22.5 w260 R5.2", "File Management")

    useTextFileForURLsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 Checked", "Use collected URLs")
    customURLInputEdit := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled", "Currently downloading collected URLs.")
    useDefaultDownloadLocationCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+30 Checked", "Use default download path")
    customDownloadLocation := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled", "Currently downloading into default directory.")

    startDownloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp+265 yp-90 w205 R5.2", "Start Downloading")

    startDownloadButton := downloadOptionsGUI.Add("Button", "xp+10 yp+20 R1", "Start downloading...")
    cancelDownloadButton := downloadOptionsGUI.Add("Button", "xp+120 w65", "Cancel")
    terminateScriptAfterDownloadCheckbox := downloadOptionsGUI.Add("Checkbox", "xp-120 yp+30", "Terminate script after downloading")

    ignoreErrorsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    abortOnErrorCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    ignoreAllOptionsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    hideDownloadCommandPromptCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    askForDownloadConfirmationCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    enableFastDownloadModeCheckbox.OnEvent("Click", (*) => handleGUI_Checkbox_fastDownload())
    higherRetryAmountCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoDescriptionCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoCommentsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoThumbnail.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoSubtitles.OnEvent("Click", (*) => handleGUI_Checkboxes())
    useTextFileForURLsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    useDefaultDownloadLocationCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadAudioOnlyCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    alwaysHighestQualityBothCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    prioritiseVideoQualityCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    prioritiseAudioQualityCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    terminateScriptAfterDownloadCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())

    limitDownloadRateEdit.OnEvent("Change", (*) => handleGUI_InputFields())
    customURLInputEdit.OnEvent("Change", (*) => handleGUI_InputFields())
    chooseVideoFormatDropDownList.OnEvent("Change", (*) => handleGUI_InputFields())
    chooseAudioFormatDropDownList.OnEvent("Change", (*) => handleGUI_InputFields())

    startDownloadButton.OnEvent("Click", (*) => startDownload(commandString))
    cancelDownloadButton.OnEvent("Click", (*) => cancelDownload())
}

; Runs a few commands when the script is executed.
optionsGUI_onInit()
{
    createDownloadOptionsGUI()
    buildCommandString()
}

; Use embed options for later !!!

cancelDownload()
{
    result := MsgBox("Do you really want to cancel the ongoing download process ?"
        , "Cancel downloading", "YN Icon! 4096 T10")

    If (result = "Yes")
    {
        Try
        {
            ProcessClose(("ahk_pid " . consoleId))
            WinClose(("ahk_pid " . consoleId))
        }
    }
    Return
}

; Function to react to changes made to any checkbox.
handleGUI_Checkboxes()
{
    global commandString

    Switch (ignoreErrorsCheckbox.Value)
    {
        Case 0:
        {
            ; Do not ignore most errors while downloading.
            abortOnErrorCheckbox.Opt("-Disabled")
        }
        Case 1:
        {
            ; Do ignore most errors while downloading.
            abortOnErrorCheckbox.Opt("+Disabled")
            commandString .= "--ignore-errors "
        }
    }
    Switch (abortOnErrorCheckbox.Value)
    {
        Case 0:
        {
            ; Do not abort on errors.
            ignoreErrorsCheckbox.Opt("-Disabled")
            commandString .= "--no-abort-on-error "
        }
        Case 1:
        {
            ; Do abort on errors.
            ignoreErrorsCheckbox.Opt("+Disabled")
            commandString .= "--abort-on-error "
        }
    }
    Switch (ignoreAllOptionsCheckbox.Value)
    {
        Case 0:
        {
            ; Do not ignore the config file.
        }
        Case 1:
        {
            ; Do ignore the config file.
        }
    }
    Switch (askForDownloadConfirmationCheckbox.Value)
    {
        Case 0:
        {
            ; Do not show a confirmation prompt before downloading.
        }
        Case 1:
        {
            ; Show a confirmation prompt before downloading.
        }
    }
    Switch (higherRetryAmountCheckbox.Value)
    {
        Case 1:
        {
            ; Increase the maximum download retry amount up to 30.
            commandString .= "--retries 30 "
        }
    }
    Switch (downloadVideoDescriptionCheckbox.Value)
    {
        Case 0:
        {
            ; Do not download the video description.
            commandString .= "--no-write-description "
        }
        Case 1:
        {
            ; Add the video description to a .description file.
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                commandString .= "--write-description "
            }
        }
    }
    Switch (downloadVideoCommentsCheckbox.Value)
    {
        Case 0:
        {
            ; Do not download the video's comment section.
            commandString .= "--no-write-comments "
        }
        Case 1:
        {
            ; Download the video 's comment section.
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                commandString .= "--write-comments "
            }
        }
    }
    Switch (downloadVideoThumbnail.Value)
    {
        Case 1:
        {
            ; Download the video thumbnail and add it to the downloaded video.
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                commandString .= "--write-thumbnail "
                commandString .= "--embed-thumbnail "
            }
        }
    }
    Switch (downloadVideoSubtitles.Value)
    {
        Case 1:
        {
            ; Download the video's subtitles and embed tem into the downloaded video.
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                commandString .= "--write-description "
                commandString .= "--embed-subs "
            }
        }
    }
    Switch (useTextFileForURLsCheckbox.Value)
    {
        Case 0:
        {
            ; Allow the user to download his own URL.
            customURLInputEdit.Opt("-Disabled")
            If (customURLInputEdit.Value = "Currently downloading collected URLs.")
            {
                customURLInputEdit.Value := "You can now enter your own URL."
            }
            commandString .= "--no-batch-file "
            commandString .= customURLInputEdit.Value . " "
        }
        Case 1:
        {
            ; Download selected URLs form the text file.
            customURLInputEdit.Opt("+Disabled")
            customURLInputEdit.Value := "Currently downloading collected URLs."
            ; Gives the .txt file with all youtube URLs to yt-dlp.
            commandString .= "--batch-file " . readConfigFile("URL_FILE_LOCATION") . " "
        }
    }
    Switch (useDefaultDownloadLocationCheckbox.Value)
    {
        Case 0:
        {
            ; Allows the user to select a custom download path.
            customDownloadLocation.Opt("-Disabled")
            ; Makes sure that a user input will not be overwritten.
            If (customDownloadLocation.Value = "Currently downloading into default directory.")
            {
                customDownloadLocation.Value := "You can now specify your own download path."
            }
            commandString .= "--paths " . customDownloadLocation.Value . " "
        }
        Case 1:
        {
            ; Keeps the default download directory.
            customDownloadLocation.Opt("+Disabled")
            customDownloadLocation.Value := "Currently downloading into default directory."
            commandString .= "--paths " . readConfigFile("DEFAULT_DOWNLOAD_PATH") . " "
        }
    }
    Switch (downloadAudioOnlyCheckbox.Value)
    {
        Case 0:
        {
            ; Downloads the video with audio.
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                chooseVideoFormatDropDownList.Opt("-Disabled")
            }
            chooseAudioFormatDropDownList.Opt("+Disabled")
        }
        Case 1:
        {
            ; Only extracts the audio and creates the desired audio file type.
            chooseVideoFormatDropDownList.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
            If (enableFastDownloadModeCheckbox.Value = 1)
            {
                chooseAudioFormatDropDownList.Opt("-Disabled")
            }
            commandString .= "--extract-audio "
            commandString .= '--audio-format "' . downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] . '" '
        }
    }
    Switch (alwaysHighestQualityBothCheckbox.Value)
    {
        Case 0:
        {
            ; Let the user choose a prefered option.
            prioritiseVideoQualityCheckbox.Opt("-Disabled")
            prioritiseAudioQualityCheckbox.Opt("-Disabled")
        }
        Case 1:
        {
            ; Try to choose the best audio quality both audio and video.
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
            If (enableFastDownloadModeCheckbox.Value != 1)
            {
                commandString .= '-f "bestvideo+bestaudio" '
            }
        }
    }
    If (alwaysHighestQualityBothCheckbox.Value != 1)
    {
        Switch (prioritiseVideoQualityCheckbox.Value)
        {
            Case 0:
            {
                ; Let the user choose a prefered option.
                alwaysHighestQualityBothCheckbox.Opt("-Disabled")
                prioritiseAudioQualityCheckbox.Opt("-Disabled")
            }
            Case 1:
            {
                ; Try to choose the best audio quality both audio and video.
                alwaysHighestQualityBothCheckbox.Opt("+Disabled")
                prioritiseAudioQualityCheckbox.Opt("+Disabled")
                If (enableFastDownloadModeCheckbox.Value != 1)
                {
                    commandString .= '-f "bestvideo" '
                }
            }
        }
        If (prioritiseVideoQualityCheckbox.Value != 1)
        {
            Switch (prioritiseAudioQualityCheckbox.Value)
            {
                Case 0:
                {
                    ; Let the user choose a prefered option.
                    alwaysHighestQualityBothCheckbox.Opt("-Disabled")
                    prioritiseVideoQualityCheckbox.Opt("-Disabled")
                }
                Case 1:
                {
                    ; Try to choose the best audio quality both audio and video.
                    alwaysHighestQualityBothCheckbox.Opt("+Disabled")
                    prioritiseVideoQualityCheckbox.Opt("+Disabled")
                    If (enableFastDownloadModeCheckbox.Value != 1)
                    {
                        commandString .= '-f "bestaudio" '
                    }
                }
            }
        }
    }
}

; Has to be excluded to avoid disabeling options everytime handleGUI_Checkboxes() is called.
handleGUI_Checkbox_fastDownload()
{
    Switch (enableFastDownloadModeCheckbox.Value)
    {
        Case 0:
        {
            ; Keep every option available.
            limitDownloadRateEdit.Opt("-Disabled")
            downloadVideoDescriptionCheckbox.Opt("-Disabled")
            downloadVideoCommentsCheckbox.Opt("-Disabled")
            downloadVideoThumbnail.Opt("-Disabled")
            downloadVideoSubtitles.Opt("-Disabled")
            chooseVideoFormatDropDownList.Opt("-Disabled")
            alwaysHighestQualityBothCheckbox.Opt("-Disabled")
            prioritiseVideoQualityCheckbox.Opt("-Disabled")
            prioritiseAudioQualityCheckbox.Opt("-Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
            If (downloadAudioOnlyCheckbox.Value = 0)
            {
                chooseAudioFormatDropDownList.Opt("+Disabled")
            }
        }
        Case 1:
        {
            ; Disable all time consuming download variants.
            limitDownloadRateEdit.Opt("+Disabled")
            downloadVideoDescriptionCheckbox.Opt("+Disabled")
            downloadVideoCommentsCheckbox.Opt("+Disabled")
            downloadVideoThumbnail.Opt("+Disabled")
            downloadVideoSubtitles.Opt("+Disabled")
            chooseVideoFormatDropDownList.Opt("+Disabled")
            alwaysHighestQualityBothCheckbox.Opt("+Disabled")
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("+Disabled")
            ; In case the user wants to download music fast.
            If (downloadAudioOnlyCheckbox.Value = 1)
            {
                chooseAudioFormatDropDownList.Opt("-Disabled")
            }
        }
    }
}
; Function that deals with changes made to any input field.
handleGUI_InputFields()
{
    global commandString
    If (limitDownloadRateEdit.Value != 0)
    {
        If (limitDownloadRateEdit.Value > 100)
        {
            limitDownloadRateEdit.Value := 100
        }
        ; Limit the download rate to a maximum value in Megabytes per second.
        If (enableFastDownloadModeCheckbox.Value != 1)
        {
            commandString .= "--limit-rate " . limitDownloadRateEdit.Value . "MB "
        }
    }
    ; Handles the desired download formats.
    If (enableFastDownloadModeCheckbox.Value != 1 && downloadAudioOnlyCheckbox.Value != 1)
    {
        commandString .= '--remux-video "' . downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . '" '
    }
}

; This function parses through all values of the GUI and builds a command string
; which bill be given to the yt-dlp command prompt.
; Returns the string to it's caller.
buildCommandString()
{
    global commandString := "yt-dlp "
    handleGUI_Checkboxes()
    handleGUI_InputFields()
    ; Adds the ffmpeg location for the script to remux / extract audio etc.
    commandString .= "--ffmpeg-location " . ffmpegLocation . " "
    Return commandString
}