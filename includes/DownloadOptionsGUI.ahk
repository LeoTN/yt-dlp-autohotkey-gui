#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Client"

global commandString := ""
global downloadTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")

createDownloadOptionsGUI()
{
    Global
    downloadOptionsGUI := Gui(, "Download Options")

    generalGroupbox := downloadOptionsGUI.Add("GroupBox", "w300 R3.2", "General Options")

    ignoreErrorsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 vIgnoreErrorsCheckbox", "Ignore errors")
    abortOnErrorCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vAbortOnErrorCheckbox", "Abort on error")
    ignoreAllOptionsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vIgnoreAllOptionsCheckbox", "Ignore all options")
    hideDownloadCommandPromptCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+110 yp-40 vHideDownloadCommandPromptCheckbox",
        "Download in a background task")
    clearURLFileAfterDownloadCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked vClearURLFileAfterDownloadCheckbox",
        "Clear the URL file after download")
    enableFastDownloadModeCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vEnableFastDownloadModeCheckbox",
        "Fast download mode")

    downloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-120 yp+20 w479 R9.3", "Download Options")

    limitDownloadRateText1 := downloadOptionsGUI.Add("Text", "xp+10 yp+20 vLimitDownloadRateText1",
        "Maximum download rate`nin MB per second.")
    limitDownloadRateEdit := downloadOptionsGUI.Add("Edit", "yp+30 Number vLimitDownloadRateEdit")
    limitDownloadRateUpDown := downloadOptionsGUI.Add("UpDown", "vLimitDownloadRateUpDown")
    limitDownloadRateText2 := downloadOptionsGUI.Add("Text", "yp+25 vLimitDownloadRateText2",
        "Enter 0 for no limitations. Applies to both input fields.")
    maxDownloadSizeText1 := downloadOptionsGUI.Add("Text", "xp+200 yp-55 vMaxDownloadSizeText1",
        "Maximum download`nfile size in MB.")
    maxDownloadSizeEdit := downloadOptionsGUI.Add("Edit", "yp+30 Number vMaxDownloadSizeEdit")
    maxDownloadSizeUpDown := downloadOptionsGUI.Add("UpDown", "vMaxDownloadSizeUpDown")
    higherRetryAmountCheckbox := downloadOptionsGUI.Add("Checkbox", "xp-200 yp+45 vHigherRetryAmountCheckbox",
        "Increase retry amount")
    downloadVideoDescriptionCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked vDownloadVideoDescriptionCheckbox",
        "Download video description")
    downloadVideoCommentsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vDownloadVideoCommentsCheckbox",
        "Download video commentary")
    downloadVideoThumbnailCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked vDownloadVideoThumbnailCheckbox",
        "Download video thumbnail")
    downloadVideoSubtitlesCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vDownloadVideoSubtitlesCheckbox",
        "Download video subtitles")
    downloadWholePlaylistsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+160 yp-80 vDownloadWholePlaylistsCheckbox",
        "Download complete playlists")
    useDownloadArchiveCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 Checked vUseDownloadArchiveCheckbox",
        "Use download archive file")

    chooseVideoFormatText := downloadOptionsGUI.Add("Text", "xp+174 yp-95 vChooseVideoFormatText", "Desired video format")
    downloadVideoFormatArray := ["Best format for quality", "mp4", "webm", "avi", "flv", "mkv", "mov"]
    chooseVideoFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1 vChooseVideoFormatDropDownList",
        downloadVideoFormatArray)

    downloadAudioOnlyCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5 vDownloadAudioOnlyCheckbox", "Download audio only")
    downloadAudioFormatArray := ["Best format for quality", "mp3", "wav", "m4a", "flac", "aac", "alac", "opus", "vorbis"]
    chooseAudioFormatDropDownList := downloadOptionsGUI.Add("DropDownList", "y+17 Choose1 vChooseAudioFormatDropDownList",
        downloadAudioFormatArray)

    alwaysHighestQualityBothCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5 Checked vAlwaysHighestQualityBothCheckbox",
        "Balance quality")
    prioritiseVideoQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vPrioritiseVideoQualityCheckbox",
        "Prefer video quality")
    prioritiseAudioQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vPrioritiseAudioQualityCheckbox",
        "Prefer audio quality")

    fileSystemGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-344 yp+22.5 w260 R5.2", "File Management")

    useTextFileForURLsCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 Checked vUseTextFileForURLsCheckbox",
        "Use collected URLs")
    customURLInputEdit := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled vCustomURLInputEdit",
        "Currently downloading collected URLs.")
    useDefaultDownloadLocationCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+30 Checked vUseDefaultDownloadLocationCheckbox",
        "Use default download path")
    customDownloadLocationEdit := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled vCustomDownloadLocationEdit",
        "Currently downloading into default directory.")

    startDownloadGroupbox := downloadOptionsGUI.Add("GroupBox", "xp+265 yp-90 w205 R5.2", "Download Status")

    startDownloadButton := downloadOptionsGUI.Add("Button", "xp+10 yp+20 R1 vStartDownloadButton", "Start downloading...")
    cancelDownloadButton := downloadOptionsGUI.Add("Button", "xp+120 w65 vCancelDownloadButton", "Cancel")
    terminateScriptAfterDownloadCheckbox := downloadOptionsGUI.Add("Checkbox", "xp-119 yp+30 vTerminateScriptAfterDownloadCheckbox",
        "Terminate script after downloading")
    downloadStatusProgressBar := downloadOptionsGUI.Add("Progress", "yp+25 w183 vDownloadStatusProgressBar", 0)
    downloadStatusText := downloadOptionsGUI.Add("Text", "yp+20 w183 vDownloadStatusText", "Currently not downloading.")

    presetSelectionGroupBox := downloadOptionsGUI.Add("GroupBox", "xp+28 yp-371 w165 R3.2", "Presets")

    selectAndAddPresetsComboBox := downloadOptionsGUI.Add("ComboBox", "xp+10 yp+20 w145 vSelectAndAddPresetsComboBox",
        handleDownloadOptionsGUI_refreshPresetArray())
    savePresetButton := downloadOptionsGUI.Add("Button", "yp+30 vSavePresetButton", "Save Preset")
    loadPresetButton := downloadOptionsGUI.Add("Button", "xp+75 vLoadPresetButton", "Load Preset")


    ignoreErrorsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    abortOnErrorCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    ignoreAllOptionsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkbox_ignoreAllOptions())
    hideDownloadCommandPromptCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    clearURLFileAfterDownloadCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    enableFastDownloadModeCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkbox_fastDownload())
    higherRetryAmountCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadVideoDescriptionCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadVideoCommentsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadVideoThumbnailCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadVideoSubtitlesCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadWholePlaylistsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    useDownloadArchiveCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    useTextFileForURLsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes()
        ; Most likely you dont want to download a whole playlist when entering a single URL.
            handleDownloadOptionsGUI_Checkbox_DownloadWholePlaylist())
    useDefaultDownloadLocationCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    downloadAudioOnlyCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    alwaysHighestQualityBothCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    prioritiseVideoQualityCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    prioritiseAudioQualityCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    terminateScriptAfterDownloadCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_Checkboxes())
    limitDownloadRateEdit.OnEvent("Change", (*) => handleDownloadOptionsGUI_InputFields())
    customURLInputEdit.OnEvent("Change", (*) => handleDownloadOptionsGUI_InputFields())
    customDownloadLocationEdit.OnEvent("Focus", (*) => handleDownloadOptionsGUI_InputFields())
    chooseVideoFormatDropDownList.OnEvent("Change", (*) => handleDownloadOptionsGUI_InputFields())
    chooseAudioFormatDropDownList.OnEvent("Change", (*) => handleDownloadOptionsGUI_InputFields())
    startDownloadButton.OnEvent("Click", (*) => startDownload(buildCommandString()))
    cancelDownloadButton.OnEvent("Click", (*) => cancelDownload())
    savePresetButton.OnEvent("Click", (*) => handleDownloadOptionsGUI_Button_savePreset_waitForSecondClick())
    loadPresetButton.OnEvent("Click", (*) => loadGUISettingsFromPreset(selectAndAddPresetsComboBox.Text))
}

; Runs a few commands when the script is executed.
optionsGUI_onInit()
{
    createDownloadOptionsGUI()
    buildCommandString()
    Sleep(1000)
    ; Checks for the last settings file to restore settings from the last download.
    If (loadGUISettingsFromPreset("last_settings", true, true) = false)
    {
        ; Load the default file instead.
        Loop Files (readConfigFile("DOWNLOAD_PRESET_LOCATION") . "\*.ini")
        {
            If (InStr(A_LoopFileName, "_(DEFAULT)"))
            {
                SplitPath(A_LoopFileName, , , , &outNameNotExt)
                loadGUISettingsFromPreset(outNameNotExt)
            }
        }
    }
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
}

cancelDownload()
{
    result := MsgBox("Do you really want to cancel the ongoing download process ?"
        , "Cancel downloading", "YN Icon! 4096 T10")

    If (result = "Yes")
    {
        global booleanDownloadTerminated := true
        Try
        {
            ProcessClose(("ahk_pid " . hiddenConsolePID))
            WinClose(("ahk_pid " . hiddenConsolePID))
        }
    }
}

; Function to react to changes made to any checkbox.
handleDownloadOptionsGUI_Checkboxes()
{
    global commandString
    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()

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
            customDownloadLocationEdit.Opt("-Disabled")
            ; Makes sure that a user input will not be overwritten.
            If (customDownloadLocationEdit.Value = "Currently downloading into default directory.")
            {
                customDownloadLocationEdit.Value := "You can now specify your own download path."
            }
        }
        Case 1:
        {
            ; Keeps the default download directory.
            customDownloadLocationEdit.Opt("+Disabled")
            customDownloadLocationEdit.Value := "Currently downloading into default directory."
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
                If (useDefaultDownloadLocationCheckbox.Value = 1)
                {

                    commandString .= '--paths "description:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\description(s)" '

                }
                Else
                {
                    commandString .= '--paths "description:' . customDownloadLocationEdit.Value . '\description(s)" '
                }
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
                ; See startDownload() for more info.
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
        Case 0:
        {
            commandString .= "--no-write-thumbnail "
        }
        Case 1:
        {
            ; Download the video thumbnail and add it to the downloaded video.
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-thumbnail "
                commandString .= "--embed-thumbnail "
                If (useDefaultDownloadLocationCheckbox.Value = 1)
                {

                    commandString .= '--paths "thumbnail:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\thumbnail(s)" '

                }
                Else
                {
                    commandString .= '--paths "thumbnail:' . customDownloadLocationEdit.Value . '\thumbnail(s)" '
                }
            }
            Else
            {
                commandString .= "--no-write-thumbnail "
            }
        }
    }
    Switch (downloadVideoSubtitlesCheckbox.Value)
    {
        Case 0:
        {
            commandString .= "--no-write-subs "
        }
        Case 1:
        {
            ; Download the video's subtitles and embed tem into the downloaded video.
            If (enableFastDownloadModeCheckbox.Value = 0)
            {
                commandString .= "--write-subs "
                commandString .= '--sub-langs "all" '
                commandString .= "--embed-subs "
                If (useDefaultDownloadLocationCheckbox.Value = 1)
                {

                    commandString .= '--paths "subtitle:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\subtitle(s)" '

                }
                Else
                {
                    commandString .= '--paths "subtitle:' . customDownloadLocationEdit.Value . '\subtitle(s)" '
                }
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

; Has to be excluded to avoid disabeling options everytime handleDownloadOptionsGUI_Checkboxes() is called.
handleDownloadOptionsGUI_Checkbox_fastDownload()
{
    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
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
            handleDownloadOptionsGUI_Checkboxes()
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

handleDownloadOptionsGUI_Checkbox_ignoreAllOptions()
{
    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
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
            maxDownloadSizeEdit.Opt("-Disabled")
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
            handleDownloadOptionsGUI_Checkboxes()
            If (enableFastDownloadModeCheckbox.Value = 1)
            {
                handleDownloadOptionsGUI_Checkbox_fastDownload()
            }
        }
        Case 1:
        {
            ; Execute a pure download with only necessary parameters while disabeling all other options.
            ignoreErrorsCheckbox.Opt("+Disabled")
            abortOnErrorCheckbox.Opt("+Disabled")
            clearURLFileAfterDownloadCheckbox.Opt("+Disabled")
            enableFastDownloadModeCheckbox.Opt("+Disabled")
            limitDownloadRateEdit.Opt("+Disabled")
            maxDownloadSizeEdit.Opt("+Disabled")
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
handleDownloadOptionsGUI_InputFields()
{
    global commandString
    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
    static newDownloadFolder := ""

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
    If (maxDownloadSizeEdit.Value != 0)
    {
        ; Limit the download file size to a maximum value in Megabytes.
        commandString .= '--match-filter "filesize_approx<' . maxDownloadSizeEdit.Value . 'M" '
    }
    If (customDownloadLocationEdit.Value = "You can now specify your own download path.")
    {
        If (newDownloadFolder = "")
        {
            newDownloadFolder := DirSelect("*" . readConfigFile("DOWNLOAD_PATH"), 3, "Select download folder")
        }
        Else
        {
            newDownloadFolder := DirSelect("*" . newDownloadFolder, 3, "Select download folder")
        }
        If (newDownloadFolder = "")
        {
            MsgBox("Invalid folder selection.", "Error", "O IconX T1.5")
            ; Checks the default download location checkbox so that the user loses focus on the input field.
            ; Therefore he can click on it again and the "focus" event will be triggered.
            useDefaultDownloadLocationCheckbox.Value := 1
            handleDownloadOptionsGUI_Checkboxes()
        }
        Else
        {
            customDownloadLocationEdit.Value := newDownloadFolder
        }
    }
    ; Handles the desired download formats.
    If (enableFastDownloadModeCheckbox.Value != 1 && downloadAudioOnlyCheckbox.Value != 1 &&
        downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] != "Best format for quality")
    {
        commandString .= '--remux-video "' . downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . '" '
    }
}

handleDownloadOptionsGUI_Checkbox_DownloadWholePlaylist()
{
    ; Collects all data from the download options GUI into the object.
    global downloadOptionsGUI_SubmitObject := downloadOptionsGUI.Submit()
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
    global downloadTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")

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
            commandString .= '--paths "' . customDownloadLocationEdit.Value . '\media" '
        }
        Case 1:
        {
            commandString .= '--paths "' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\media" '
        }
    }
    If (ignoreAllOptionsCheckbox.Value != 1)
    {
        handleDownloadOptionsGUI_Checkboxes()
        handleDownloadOptionsGUI_InputFields()
    }
    ; This makes sure that the output file does not contain any weird letters.
    commandString .= '--output "%(title)s.%(ext)s" '
    ; Sets the temporary directory for yt-dlp.
    commandString .= '--paths "temp:' . readConfigFile("DOWNLOAD_PATH") . '\temporaryStorage" '
    ; Might help to enforce the max-filesize option.
    commandString .= "--no-part "
    ; Makes the downloading message in the console a little prettier.
    commandString .= '--progress-template "[Downloading...] [%(progress._percent_str)s of %(progress._total_bytes_str)s ' .
        'at %(progress._speed_str)s. Time passed : %(progress._elapsed_str)s]" '
    ; Adds the ffmpeg location for the script to remux videos or extract audio etc.
    commandString .= '--ffmpeg-location "' . ffmpegLocation . '" '
    Return commandString
}

; When called it will create and maintain several arrays in order to provide tool tip information for user.
; Can be called with a set timer to react upon the user hovering over a GUI element.
handleDownloadOptionsGUI_toolTipManager(pBooleanRefresh := false)
{
    booleanRefresh := pBooleanRefresh
    static elementHWNDArray := []
    ; Only refreshes if required or if the array is empty (first time call of the function).
    If (booleanRefresh = true || !elementHWNDArray.Has(2))
    {
        arrayCounter := 1
        ; Saves the HWND of all GUI elements into the HWND array.
        For (GuiCtrlObj in downloadOptionsGUI)
        {
            ; This condition ignore all other GUI elements except of checkboxes, edits and lists.
            If (InStr(GuiCtrlObj.Type, "Checkbox") || InStr(GuiCtrlObj.Type, "Edit")
                || InStr(GuiCtrlObj.Type, "DDL") || InStr(GuiCtrlObj.Type, "Button"))
            {
                elementHWNDArray.InsertAt(arrayCounter, GuiCtrlObj.Hwnd)
                arrayCounter++
            }
        }
    }
    ; Checks if the download GUI exists.
    ; The tooltips are disabled while downloads are running because it would interfer with the progress bar.
    ; I know this is a sloppy solution but it might be changed in the future.
    If (WinExist("ahk_id " . downloadOptionsGUI.Hwnd) && isDownloading = false)
    {
        handleDownloadOptionsGUI_toolTipLoop(elementHWNDArray)
    }
}

; When called checks if the mouse hovers over a GUI element and shows the specific tooltip.
handleDownloadOptionsGUI_toolTipLoop(pElementHWNDArray)
{
    elementHWNDArray := pElementHWNDArray
    ; Contains an individual tool tip for every control that requires one.
    static elementToolTipArray := []
    If (!elementToolTipArray.Has(2))
    {
        tmp1 := "Ignores errors thrown by most events."
        tmp2 := ""
        tmp3 := "Starts the download with the required options only."
        tmp4 := "Hides the PowerShell window."
        tmp5 := ""
        tmp6 := "Disables most time-consuming options to increase download and processing speed."
        tmp7 := ""
        tmp8 := "This option is still experimental and might cause weird results."
        tmp9 := "Useful option to try when the download fails too often."
        tmp10 := ""
        tmp11 := ""
        tmp12 := ""
        tmp13 := ""
        tmp14 := "Forces the download of complete playlists if a URL contains a reference to it."
        tmp15 := "Saves downloaded videos into an archive file to avoid downloading a video twice."
        tmp16 := "Select a video format."
        tmp17 := ""
        tmp18 := "Select an audio format."
        tmp19 := "Tries to find a compromise between audio and video quality."
        tmp20 := ""
        tmp21 := ""
        tmp22 := "Usually, a text file will be given to yt-dlp to download, but it is also possible to select a single URL."
        tmp23 := "The current location of the URL file is : [" . readConfigFile("URL_FILE_LOCATION") . "]."
        tmp24 := "Saves all downloads to the default path specified in the config file."
        tmp25 := "The current default download path is: [" . readConfigFile("DOWNLOAD_PATH") . "]." .
            "`nKeep in mind, that selecting a folder will actually download straight into it without any timestamp subfolders."
        tmp26 := ""
        tmp27 := ""
        tmp28 := "Shows no prompt when download in a background task is activated."
        tmp29 := "Single click to save a preset or double click to save as default."
        tmp30 := "The default preset will be loaded when no previous temporary preset is found."
        Loop (30)
        {
            elementToolTipArray.InsertAt(A_Index, %"tmp" . A_Index%)
        }
    }

    If (WinActive("ahk_id " . downloadOptionsGUI.Hwnd))
    {
        MouseGetPos(, , &outWinHWND, &outControlHWND, 2)
        Loop (elementHWNDArray.Length)
        {
            If (elementHWNDArray.Get(A_Index) = outControlHWND && downloadOptionsGUI.Hwnd = outWinHWND)
            {
                ; Saves the index of the outer loop because inside the while loops the value of A_Index will be different.
                tmpIndex := A_Index
                i := 0
                ; In case the cursor is above a control element it will have to stay for 2 seconds to trigger the tool tip.
                While (elementHWNDArray.Get(tmpIndex) = outControlHWND && downloadOptionsGUI.Hwnd = outWinHWND)
                {
                    Sleep(100)
                    i++
                    If (i >= 10)
                    {
                        Break
                    }
                    Else If (!(elementHWNDArray.Get(tmpIndex) = outControlHWND && downloadOptionsGUI.Hwnd = outWinHWND))
                    {
                        Return
                    }
                }
                ToolTip(elementToolTipArray.Get(A_Index))
                ; Waits for the user to read the tool tip as he stays above the control element with the cursor.
                While (elementHWNDArray.Get(tmpIndex) = outControlHWND && downloadOptionsGUI.Hwnd = outWinHWND)
                {
                    MouseGetPos(, , &outWinHWND, &outControlHWND, 2)
                    Sleep(100)
                }
                ToolTip()
                Break
            }
        }
    }
}

; Saves all options from the download options GUI into a text file for future use.
; Returns true when the file has been saved successfully.
saveGUISettingsAsPreset(pPresetName, pBooleanTemporary := false, pBooleanDefault := false)
{
    presetName := pPresetName
    booleanTemporary := pBooleanTemporary
    booleanDefault := pBooleanDefault
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    presetFileArray := handleDownloadOptionsGUI_refreshPresetArray()

    ; In case the user wants to accidentally create a preset with an empty name.
    If (presetName = "")
    {
        Return MsgBox("Please provide a name for your preset.", "Warning !", "O Icon! T2")
    }
    Loop (presetFileArray.Length)
    {
        ; Searches for an existing default file.
        If (InStr(presetFileArray[A_Index], "_(DEFAULT)", true))
        {
            booleanDefaultPresetExist := true
            defaultPresetOld := presetFileArray[A_Index]
            Break
        }
        Else
        {
            booleanDefaultPresetExist := false
        }
    }
    If (booleanTemporary = true)
    {
        If (!InStr(presetName, "_(TEMP)", true))
        {
            presetName .= "_(TEMP)"
        }
    }
    Else If (booleanDefault = true)
    {
        ; This avoids double "_(DEFAULT)" pieces.
        If (!InStr(presetName, "_(DEFAULT)", true))
        {
            presetName .= "_(DEFAULT)"
        }
    }
    presetLocationComplete := presetLocation . "\" . presetName . ".ini"
    i_Input := 1
    i_DropDownList := 1

    If (FileExist(presetLocationComplete))
    {
        ; This avoids showing the overwrite prompt for _(TEMP) presets.
        If (booleanTemporary = false)
        {
            result := MsgBox("The preset name : " . presetName . " already exists."
                "`n`nDo you want to overwrite it ?", "Warning !", "YN Icon! 4096 T10")
            If (result != "Yes")
            {
                Return false
            }
        }
        Try
        {
            FileDelete(presetLocationComplete)
        }
        Return saveGUISettingsAsPreset(presetName, booleanTemporary, booleanDefault)
    }
    Else
    {
        If (booleanDefaultPresetExist = true && booleanDefault = true)
        {
            result := MsgBox("An existing default file has been found."
                "`n`nReplace " . defaultPresetOld . " with " . presetName . " ?", "Warning !",
                "YN Icon! 4096 T10")
            If (result != "Yes")
            {
                Return false
            }
            ; Removes the "_(DEFAULT)" part from the old default preset file.
            tmp1 := presetLocation . "\" . defaultPresetOld . ".ini"
            tmp2 := presetLocation . "\" . StrReplace(defaultPresetOld, "_(DEFAULT)", "", true) . ".ini"
            FileMove(tmp1, tmp2, true)
            ; Important because this means that an existing file will be used.
            If (FileExist(presetLocation . "\" . pPresetName . ".ini"))
            {
                tmp1 := presetLocation . "\" . pPresetName . ".ini"
                tmp2 := presetLocationComplete
                FileMove(tmp1, tmp2, true)
            }
            Else
            {
                Return saveGUISettingsAsPreset(presetName, booleanTemporary, booleanDefault)
            }
        }
        Else If (FileExist(presetLocation . "\" . pPresetName . ".ini"))
        {
            tmp1 := presetLocation . "\" . pPresetName . ".ini"
            tmp2 := presetLocationComplete
            FileMove(tmp1, tmp2, true)
        }
        Else
        {
            ; Creates a new preset file.
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
                ; Counts the number of elements parsed. When it reaches 38 this means that all relevant settings have been saved.
                ; All remaining GUI elements belong to the preset section and are not meant to be saved.
                If (A_Index >= 38)
                {
                    Break
                }
            }
        }
        ; This ensures that the new added preset is visible in the combo box.
        selectAndAddPresetsComboBox.Delete()
        selectAndAddPresetsComboBox.Add(handleDownloadOptionsGUI_refreshPresetArray())
        Return true
    }
}

; Loads the saved settings from the preset files.
; Returns true or false based on the success.
loadGUISettingsFromPreset(pPresetName, pBooleanTemporary := false, pBooleanSupressWarning := false)
{
    presetName := pPresetName
    booleanTemporary := pBooleanTemporary
    booleanSupressWarning := pBooleanSupressWarning
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    If (booleanTemporary = true)
    {
        presetName .= "_(TEMP)"
    }
    presetLocationComplete := presetLocation . "\" . presetName . ".ini"
    i_Input := 1
    i_DropDownList := 1

    If (!FileExist(presetLocationComplete))
    {
        If (booleanSupressWarning = false)
        {
            MsgBox("The preset : " . presetName . " does not exist.", "Warning !", "O Icon! T2")
        }
        Return false
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
                MsgBox("Failed to set value of : " . GuiCtrlObj.Text . ".", "Warning !", "O Icon! T3")
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
                MsgBox("Failed to set value of : {Input_ " . i_Input . "}.", "Warning !", "O Icon! T3")
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
                MsgBox("Failed to set value of : {DropDownList_ " . i_DropDownList . "}.", "Warning !", "O Icon! T3")
            }
        }
        ; Counts the number of elements parsed. When it reaches 37 this means that all relevant settings have been loaded.
        ; All remaining GUI elements belong to the preset section and are not meant to be loaded.
        If (A_Index >= 37)
        {
            Break
        }
    }
    ; Deletes the preset when it has been used.
    If (booleanTemporary = true)
    {
        Try
        {
            FileDelete(presetLocationComplete)
        }
    }
    If (ignoreAllOptionsCheckbox.Value = 1)
    {
        handleDownloadOptionsGUI_Checkbox_ignoreAllOptions()
    }
    Else If (enableFastDownloadModeCheckbox.Value = 1)
    {
        handleDownloadOptionsGUI_Checkbox_fastDownload()
    }
    ; Makes sure all checkboxes are disabled when they would conflict with other active checkboxes.
    handleDownloadOptionsGUI_Checkboxes()
    handleDownloadOptionsGUI_InputFields()
    ; This ensures that the preset list is updated in the combo box.
    selectAndAddPresetsComboBox.Delete()
    selectAndAddPresetsComboBox.Add(handleDownloadOptionsGUI_refreshPresetArray())
    Return true
}

; Returns an array to use for the preset combo box.
handleDownloadOptionsGUI_refreshPresetArray()
{
    presetArray := []
    ; Scanns all preset files and fills the array with the file names.
    Loop Files (readConfigFile("DOWNLOAD_PRESET_LOCATION") . "\*.ini")
    {
        SplitPath(A_LoopFilePath, , , , &outNameNoExt)
        presetArray.InsertAt(A_Index, outNameNoExt)
    }
    Else
    {
        presetArray.InsertAt(1, "No presets found.")
    }
    Return presetArray
}

handleDownloadOptionsGUI_Button_savePreset_waitForSecondClick()
{
    static click_amount := 0
    If (click_amount > 0)
    {
        click_amount += 1
        Return
    }

    click_amount := 1
    SetTimer(After500, -500)

    After500()
    {
        If (click_amount = 1)
        {
            saveGUISettingsAsPreset(selectAndAddPresetsComboBox.Text)
        }
        Else If (click_amount = 2)
        {
            saveGUISettingsAsPreset(selectAndAddPresetsComboBox.Text, , true)
        }
        click_amount := 0
    }
}