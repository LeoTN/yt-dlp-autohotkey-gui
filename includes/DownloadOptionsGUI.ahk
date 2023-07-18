#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Client"

global commandString := ""
global downloadTime := FormatTime(A_Now, "HH-mm-ss_dd.MM.yyyy")

createDownloadOptionsGUI()
{
    Global
    downloadOptionsGUI := Gui(, "Download Options")

    generalGroupbox := downloadOptionsGUI.Add("GroupBox", "w300 R3.2", "General Options")

    ignoreErrorsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20", "Ignore errors")
    abortOnErrorCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Abort on error")
    ignoreAllOptionsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Ignore all options")
    hideDownloadCommandPromptCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+110 yp-40", "Download in a background task")
    clearURLFileAfterDownloadCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Clear the URL file after download")
    enableFastDownloadModeCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Fast download mode")

    downloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-120 yp+20 w479 R9.3", "Download Options")

    limitDownloadRateText1 := downloadOptionsGUI.Add("Text", "xp+10 yp+20", "Maximum download rate `n in MB per second.")
    limitDownloadRateEdit := downloadOptionsGUI.Add("Edit", "yp+30")
    limitDownloadRateUpDown := downloadOptionsGUI.Add("UpDown")
    limitDownloadRateText2 := downloadOptionsGUI.Add("Text", "yp+25", "Enter 0 for no limitations.")
    higherRetryAmountCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Increase retry amount")
    downloadVideoDescriptionCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Download video description")
    downloadVideoCommentsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Download video commentary")
    downloadVideoThumbnailCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Download video thumbnail")
    downloadVideoSubtitlesCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Download video subtitles")
    downloadWholePlaylistsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+160 yp-80", "Download complete playlists")
    useDownloadArchiveCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked", "Use download archive file")

    chooseVideoFormatText := downloadOptionsGUI.Add("Text", "xp+174 yp-95", "Desired video format")
    downloadVideoFormatArray := ["Best format for quality", "mp4", "webm", "avi", "flv", "mkv", "mov"]
    chooseVideoFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1", downloadVideoFormatArray)

    downloadAudioOnlyCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5", "Download audio only")
    downloadAudioFormatArray := ["Best format for quality", "mp3", "wav", "m4a", "flac", "aac", "alac", "opus", "vorbis"]
    chooseAudioFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1", downloadAudioFormatArray)

    alwaysHighestQualityBothCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5 Checked", "Balance quality")
    prioritiseVideoQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Prefer video quality")
    prioritiseAudioQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20", "Prefer audio quality")

    fileSystemGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-344 yp+22.5 w260 R5.2", "File Management")

    useTextFileForURLsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 Checked", "Use collected URLs")
    customURLInputEdit := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled", "Currently downloading collected URLs.")
    useDefaultDownloadLocationCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+30 Checked", "Use default download path")
    customDownloadLocation := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled", "Currently downloading into default directory.")

    startDownloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp+265 yp-90 w205 R5.2", "Download Status")

    startDownloadButton := downloadOptionsGUI.Add("Button", "xp+10 yp+20 R1", "Start downloading...")
    cancelDownloadButton := downloadOptionsGUI.Add("Button", "xp+120 w65", "Cancel")
    terminateScriptAfterDownloadCheckbox := downloadOptionsGUI.Add("Checkbox", "xp-119 yp+30", "Terminate script after downloading")
    downloadStatusProgressBar := downloadOptionsGUI.Add("Progress", "yp+25 w183", 0)
    downloadStatusText := downloadOptionsGUI.Add("Text", "yp+20 w183", "Currently not downloading.")

    ignoreErrorsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    abortOnErrorCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    ignoreAllOptionsCheckbox.OnEvent("Click", (*) => handleGUI_Checkbox_ignoreAllOptions())
    hideDownloadCommandPromptCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    clearURLFileAfterDownloadCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    enableFastDownloadModeCheckbox.OnEvent("Click", (*) => handleGUI_Checkbox_fastDownload())
    higherRetryAmountCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoDescriptionCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoCommentsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoThumbnailCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadVideoSubtitlesCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadWholePlaylistsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    useDownloadArchiveCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    useTextFileForURLsCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes()
        ; Most likely you dont want to download a whole playlist when entering a single URL.
            handleGUI_Checkbox_DownloadWholePlaylist())
    useDefaultDownloadLocationCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    downloadAudioOnlyCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    alwaysHighestQualityBothCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    prioritiseVideoQualityCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    prioritiseAudioQualityCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())
    terminateScriptAfterDownloadCheckbox.OnEvent("Click", (*) => handleGUI_Checkboxes())

    limitDownloadRateEdit.OnEvent("Change", (*) => handleGUI_InputFields())
    customURLInputEdit.OnEvent("Change", (*) => handleGUI_InputFields())
    customDownloadLocation.OnEvent("Focus", (*) => handleGUI_InputFields())
    chooseVideoFormatDropDownList.OnEvent("Change", (*) => handleGUI_InputFields())
    chooseAudioFormatDropDownList.OnEvent("Change", (*) => handleGUI_InputFields())

    startDownloadButton.OnEvent("Click", (*) => startDownload(buildCommandString()))
    cancelDownloadButton.OnEvent("Click", (*) => cancelDownload())
}

; Runs a few commands when the script is executed.
optionsGUI_onInit()
{
    createDownloadOptionsGUI()
    buildCommandString()
}

cancelDownload()
{
    result := MsgBox("Do you really want to cancel the ongoing download process ?"
        , "Cancel downloading", "YN Icon! 4096 T10")

    If (result = "Yes")
    {
        Try
        {
            ProcessClose(("ahk_pid " . hiddenConsolePID))
            WinClose(("ahk_pid " . hiddenConsolePID))
        }
        global booleanDownloadTerminated := true
    }
    Return
}

; Function to react to changes made to any checkbox.
handleGUI_Checkboxes()
{
    global commandString

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
        }
        Case 1:
        {
            ; Download selected URLs form the text file.
            customURLInputEdit.Opt("+Disabled")
            customURLInputEdit.Value := "Currently downloading collected URLs."
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
        }
        Case 1:
        {
            ; Keeps the default download directory.
            customDownloadLocation.Opt("+Disabled")
            customDownloadLocation.Value := "Currently downloading into default directory."
        }
    }
    ; Stops the script form continuing because all options are considered as ignored.
    If (ignoreAllOptionsCheckbox.Value = 1)
    {
        Return
    }
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
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-description "
                commandString .= '--paths "description:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\description(s)" '
            }
            Else
            {
                ; Do not download the video description.
                commandString .= "--no-write-description "
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
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-comments "
                ; Currently not implemeted into yt-dlp.
                ; commandString .= '--paths "comments:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\comments" '
                ; This script contains a work arround for moving the comments to a desired folder.
            }
            Else
            {
                ; Do not download the video's comment section.
                commandString .= "--no-write-comments "
            }
        }
    }
    Switch (downloadVideoThumbnailCheckbox.Value)
    {
        Case 1:
        {
            ; Download the video thumbnail and add it to the downloaded video.
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-thumbnail "
                commandString .= '--paths "thumbnail:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\thumbnail(s)" '
            }
            Else
            {
                commandString .= "--no-write-thumbnail "
            }
        }
    }
    Switch (downloadVideoSubtitlesCheckbox.Value)
    {
        Case 1:
        {
            ; Download the video's subtitles and embed tem into the downloaded video.
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-subs "
                commandString .= '--paths "subtitle:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\subtitle(s)" '
                commandString .= "--embed-subs "
            }
            Else
            {
                commandString .= "--no-write-subs "
            }
        }
    }
    Switch (downloadWholePlaylistsCheckbox.Value)
    {
        Case 0:
        {
            commandString .= "--no-playlist "
        }
        Case 1:
        {
            ; Usefull if you want to download a complete playlist but you only selected one video.
            commandString .= "--yes-playlist "
        }
    }
    Switch (useDownloadArchiveCheckbox.Value)
    {
        Case 0:
        {
            commandString .= "--no-download-archive "
        }
        Case 1:
        {
            ; Usefull if you want to download a video once.
            ; There is always an option to ignore the archive file.
            commandString .= '--download-archive "' . readConfigFile("DOWNLOAD_ARCHIVE_LOCATION") . '" '
        }
    }
    Switch (downloadAudioOnlyCheckbox.Value)
    {
        Case 0:
        {
            ; Downloads the video with audio.
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                chooseVideoFormatDropDownList.Opt("-Disabled")
                alwaysHighestQualityBothCheckbox.Opt("-Disabled")
                prioritiseVideoQualityCheckbox.Opt("-Disabled")
                prioritiseAudioQualityCheckbox.Opt("-Disabled")
            }
            chooseAudioFormatDropDownList.Opt("+Disabled")
        }
        Case 1:
        {
            ; Only extracts the audio and creates the desired audio file type.
            chooseVideoFormatDropDownList.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                chooseAudioFormatDropDownList.Opt("-Disabled")
                alwaysHighestQualityBothCheckbox.Opt("+Disabled")
                prioritiseVideoQualityCheckbox.Opt("+Disabled")
                prioritiseAudioQualityCheckbox.Opt("+Disabled")
            }
            If (downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] = "Best format for quality")
            {
                commandString .= "--extract-audio "
            }
            Else
            {
                commandString .= "--extract-audio "
                commandString .= '--audio-format "' . downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] . '" '
            }
        }
    }
    If (downloadAudioOnlyCheckbox.Value != 1 && enableFastDownloadModeCheckbox.Value != 1)
    {
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
                If (enableFastDownloadModeCheckbox.Value = 0)
                {
                    commandString .= '--format "bestvideo+bestaudio" '
                }
            }
        }
        If (alwaysHighestQualityBothCheckbox.Value != 1 && downloadAudioOnlyCheckbox.Value != 1)
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
                    If (enableFastDownloadModeCheckbox.Value = 0)
                    {
                        If (downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] = "Best format for quality")
                        {
                            commandString .= '--format "bestvideo" '
                        }
                        Else
                        {
                            commandString .= '--format "bestvideo[ext=' .
                                downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . ']" '
                        }
                    }
                }
            }
            If (prioritiseVideoQualityCheckbox.Value != 1 && downloadAudioOnlyCheckbox.Value != 1)
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
                        If (enableFastDownloadModeCheckbox.Value = 0)
                        {
                            If (downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] = "Best format for quality")
                            {
                                commandString .= '--format "bestaudio" '
                            }
                            Else
                            {
                                commandString .= '--format "bestaudio[ext=' .
                                    downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] . ']" '
                            }
                        }
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
            downloadVideoThumbnailCheckbox.Opt("-Disabled")
            downloadVideoSubtitlesCheckbox.Opt("-Disabled")
            chooseVideoFormatDropDownList.Opt("-Disabled")
            alwaysHighestQualityBothCheckbox.Opt("-Disabled")
            prioritiseVideoQualityCheckbox.Opt("-Disabled")
            prioritiseAudioQualityCheckbox.Opt("-Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
            ; Makes sure all checkboxes are disabled when they would conflict with other active checkboxes.
            handleGUI_Checkboxes()
        }
        Case 1:
        {
            ; Disable all time consuming download variants.
            limitDownloadRateEdit.Opt("+Disabled")
            downloadVideoDescriptionCheckbox.Opt("+Disabled")
            downloadVideoCommentsCheckbox.Opt("+Disabled")
            downloadVideoThumbnailCheckbox.Opt("+Disabled")
            downloadVideoSubtitlesCheckbox.Opt("+Disabled")
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

handleGUI_Checkbox_ignoreAllOptions()
{
    Switch (ignoreAllOptionsCheckbox.Value)
    {
        Case 0:
        {
            ; Do not ignore all possible options.
            ignoreErrorsCheckbox.Opt("-Disabled")
            abortOnErrorCheckbox.Opt("-Disabled")
            clearURLFileAfterDownloadCheckbox.Opt("-Disabled")
            enableFastDownloadModeCheckbox.Opt("-Disabled")
            limitDownloadRateEdit.Opt("-Disabled")
            higherRetryAmountCheckbox.Opt("-Disabled")
            downloadVideoDescriptionCheckbox.Opt("-Disabled")
            downloadVideoCommentsCheckbox.Opt("-Disabled")
            downloadVideoThumbnailCheckbox.Opt("-Disabled")
            downloadVideoSubtitlesCheckbox.Opt("-Disabled")
            downloadWholePlaylistsCheckbox.Opt("-Disabled")
            useDownloadArchiveCheckbox.Opt("-Disabled")
            chooseVideoFormatDropDownList.Opt("-Disabled")
            downloadAudioOnlyCheckbox.Opt("-Disabled")
            alwaysHighestQualityBothCheckbox.Opt("-Disabled")
            prioritiseVideoQualityCheckbox.Opt("-Disabled")
            prioritiseAudioQualityCheckbox.Opt("-Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
            ; Makes sure all checkboxes are disabled when they would conflict with other active checkboxes.
            handleGUI_Checkboxes()
        }
        Case 1:
        {
            ; Execute a pure download with only necessary parameters while disabeling all other options.
            ignoreErrorsCheckbox.Opt("+Disabled")
            abortOnErrorCheckbox.Opt("+Disabled")
            clearURLFileAfterDownloadCheckbox.Opt("+Disabled")
            enableFastDownloadModeCheckbox.Opt("+Disabled")
            limitDownloadRateEdit.Opt("+Disabled")
            higherRetryAmountCheckbox.Opt("+Disabled")
            downloadVideoDescriptionCheckbox.Opt("+Disabled")
            downloadVideoCommentsCheckbox.Opt("+Disabled")
            downloadVideoThumbnailCheckbox.Opt("+Disabled")
            downloadVideoSubtitlesCheckbox.Opt("+Disabled")
            downloadWholePlaylistsCheckbox.Opt("+Disabled")
            useDownloadArchiveCheckbox.Opt("+Disabled")
            chooseVideoFormatDropDownList.Opt("+Disabled")
            downloadAudioOnlyCheckbox.Opt("+Disabled")
            alwaysHighestQualityBothCheckbox.Opt("+Disabled")
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("+Disabled")
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
        If (enableFastDownloadModeCheckbox.Value = 0)
        {
            commandString .= "--limit-rate " . limitDownloadRateEdit.Value . "MB "
        }
    }
    If (customDownloadLocation.Value = "You can now specify your own download path.")
    {
        newDownloadFolder := DirSelect("*" . readConfigFile("DOWNLOAD_PATH"), 3, "Select download folder")
        If (newDownloadFolder = "")
        {
            MsgBox("Invalid folder selection.", "Error", "O IconX T1.5")
            ; Checks the default download location checkbox so that the user loses focus on the input field.
            ; Therefore he can click on it again and the "focus" event will be triggered.
            useDefaultDownloadLocationCheckbox.Value := 1
            handleGUI_Checkboxes()
        }
        Else
        {
            customDownloadLocation.Value := newDownloadFolder
        }
    }
    ; Handles the desired download formats.
    If (enableFastDownloadModeCheckbox.Value != 1 && downloadAudioOnlyCheckbox.Value != 1 &&
        downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] != "Best format for quality")
    {
        commandString .= '--remux-video "' . downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . '" '
    }
}

handleGUI_Checkbox_DownloadWholePlaylist()
{
    If (useTextFileForURLsCheckbox.Value = 0)
    {
        downloadWholePlaylistsCheckbox.Value := 0
    }
}

; This function parses through all values of the GUI and builds a command string
; which bill be given to the yt-dlp command prompt.
; Returns the string to it's caller.
buildCommandString()
{
    ; Formats the value of A_Now to give each folder a unique time stamp.
    global downloadTime := FormatTime(A_Now, "HH-mm-ss_dd.MM.yyyy")

    global commandString := "yt-dlp "
    ; Basic options such as download path and single URL or multiple URLs.
    Switch (useTextFileForURLsCheckbox.Value)
    {
        Case 0:
        {
            commandString .= "--no-batch-file "
            commandString .= '"' . customURLInputEdit.Value . '" '
        }
        Case 1:
        {
            commandString .= '--batch-file "' . readConfigFile("URL_FILE_LOCATION") . '" '
        }
    }
    Switch (useDefaultDownloadLocationCheckbox.Value)
    {
        Case 0:
        {
            commandString .= '--paths "' . customDownloadLocation.Value . '\' . downloadTime . '\media" '
        }
        Case 1:
        {
            commandString .= '--paths "' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\media" '
        }
    }
    If (ignoreAllOptionsCheckbox.Value != 1)
    {

        handleGUI_Checkboxes()
        handleGUI_InputFields()
    }
    ; This makes sure that the output file does not contain any weird letters.
    commandString .= '--output "%(title)s.%(ext)s" '
    ; Makes the downloading message in the console a little prettier.
    commandString .= '--progress-template "[Downloading...] [%(progress._percent_str)s of %(progress._total_bytes_str)s ' .
        'at %(progress._speed_str)s. Time passed : %(progress._elapsed_str)s]" '
    ; Adds the ffmpeg location for the script to remux videos or extract audio etc.
    commandString .= '--ffmpeg-location "' . ffmpegLocation . '" '
    Return commandString
}

; Saves all options from the download options GUI into a text file for future use.
saveGUISettingsAsPreset(pPresetName, pBooleanTemporary := false)
{
    presetName := pPresetName
    booleanTemporary := pBooleanTemporary
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    If (booleanTemporary = true)
    {
        presetLocationComplete := presetLocation . "\" . presetName . "_(TEMP).ini"
    }
    Else
    {
        presetLocationComplete := presetLocation . "\" . presetName . ".ini"
    }
    i_Input := 1
    i_DropDownList := 1

    If (FileExist(presetLocationComplete))
    {
        result := MsgBox("The preset name : " . presetName . " already exists."
            " `n`nDo you want to overwrite it ?", "Warning !", "YN Icon! 4096 T10")
        If (result != "Yes")
        {
            Return false
        }
    }
    Try
    {
        FileDelete(presetLocationComplete)
    }
    For (GuiCtrlObj in downloadOptionsGUI)
    {
        ; Makes sure only checkbox values are extracted.
        If (InStr(GuiCtrlObj.Type, "Checkbox"))
        {
            IniWrite(GuiCtrlObj.Value, presetLocationComplete, "Checkboxes", "{" . GuiCtrlObj.Text . "}")
        }
        If (InStr(GuiCtrlObj.Type, "Edit"))
        {
            IniWrite(GuiCtrlObj.Value, presetLocationComplete, "Edits", "{Input_" . i_Input . "}")
            i_Input++
        }
        If (InStr(GuiCtrlObj.Type, "DDL"))
        {
            IniWrite(GuiCtrlObj.Value, presetLocationComplete, "DropDownLists", "{DropDownList_" . i_DropDownList . "}")
            i_DropDownList++
        }
    }
}

loadGUISettingsFromPreset(pPresetName)
{
    presetName := pPresetName
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    presetLocationComplete := presetLocation . "\" . presetName . ".ini"
    i_Input := 1
    i_DropDownList := 1

    If (!FileExist(presetLocationComplete))
    {
        MsgBox("The preset : " . presetName . " does not exist.`n`nTerminating script.", "Error !", "O IconX T1.5")
        ExitApp()
        ExitApp()
    }
    For (GuiCtrlObj in downloadOptionsGUI)
    {
        ; Makes sure only checkbox values are extracted.
        If (InStr(GuiCtrlObj.Type, "Checkbox"))
        {
            Try
            {
                newCheckboxValue := IniRead(presetLocationComplete, "Checkboxes", "{" . GuiCtrlObj.Text . "}")
                GuiCtrlObj.Value := newCheckboxValue
            }
            Catch
            {
                MsgBox("Failed to set value of : " . GuiCtrlObj.Text . "."
                    "`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
                ExitApp()
            }
        }
        If (InStr(GuiCtrlObj.Type, "Edit"))
        {
            Try
            {
                newEditValue := IniRead(presetLocationComplete, "Edits", "{Input_" . i_Input . "}")
                GuiCtrlObj.Value := newEditValue
                i_Input++
            }
            Catch
            {
                MsgBox("Failed to set value of : {Input_ " . i_Input . "}."
                    "`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
                ExitApp()
            }
        }
        If (InStr(GuiCtrlObj.Type, "DDL"))
        {
            Try
            {
                newDropDownListValue := IniRead(presetLocationComplete, "DropDownLists", "{DropDownList_" . i_DropDownList . "}")
                GuiCtrlObj.Value := newDropDownListValue
                i_DropDownList++
            }
            Catch
            {
                MsgBox("Failed to set value of : {DropDownList_ " . i_DropDownList . "}."
                    "`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
                ExitApp()
            }
        }
    }
    ; Makes sure all checkboxes are disabled when they would conflict with other active checkboxes.
    handleGUI_Checkboxes()
    handleGUI_InputFields()
    If (enableFastDownloadModeCheckbox.Value = 1)
    {
        handleGUI_Checkbox_fastDownload()
    }
    Else If (ignoreAllOptionsCheckbox.Value = 1)
    {
        handleGUI_Checkbox_ignoreAllOptions()
    }
}