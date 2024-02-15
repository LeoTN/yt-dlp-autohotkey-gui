#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

global commandString := ""
global downloadTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")

createDownloadOptionsGUI()
{
    Global
    downloadOptionsGUI := Gui(, "VD - Download Options")

    generalGroupbox := downloadOptionsGUI.Add("GroupBox", "w300 R3.2", "General Options")

    unusedCheckbox1 := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 vUnusedCheckbox1", "Not used")
    unusedCheckbox2 := downloadOptionsGUI.Add("Checkbox", "yp+20 vUnusedCheckbox2", "Not used")
    ignoreAllOptionsCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vIgnoreAllOptionsCheckbox", "Ignore all options")
    enableSilentDownloadModeCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+110 yp-40 vEnableSilentDownloadModeCheckbox",
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
    useEmbeddingCheckbox := downloadOptionsGUI.Add("Checkbox", "xp-200 yp+45 Checked vUseEmbeddingCheckbox",
        "Embed options below")
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

    useReencodingCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+27.5 vUseReencodingCheckbox",
        "Recode video")
    prioritiseVideoQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vPrioritiseVideoQualityCheckbox",
        "Prefer video quality")
    prioritiseAudioQualityCheckbox := downloadOptionsGUI.Add("Checkbox", "yp+20 vPrioritiseAudioQualityCheckbox",
        "Prefer audio quality")

    fileSystemGroupbox := downloadOptionsGUI.Add("GroupBox", "xp-344 yp+22.5 w260 R5.2", "File Management")

    useExternalParametersForYTDLPCheckbox := downloadOptionsGUI.Add("Checkbox", "xp+10 yp+20 vUseExternalParametersForYTDLPCheckbox",
        "Enable custom parameters")
    customParamersEdit := downloadOptionsGUI.Add("Edit", "yp+20 w240 Disabled vCustomParamersEdit",
        "Currently not using extra parameters.")
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
        handleDownloadOptionsGUI_RefreshPresetArray())
    savePresetButton := downloadOptionsGUI.Add("Button", "yp+30 vSavePresetButton", "Save Preset")
    loadPresetButton := downloadOptionsGUI.Add("Button", "xp+75 vLoadPresetButton", "Load Preset")

    unusedCheckbox1.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    unusedCheckbox2.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    ignoreAllOptionsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    enableSilentDownloadModeCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    clearURLFileAfterDownloadCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    enableFastDownloadModeCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    useEmbeddingCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadVideoDescriptionCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadVideoCommentsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadVideoThumbnailCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadVideoSubtitlesCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadWholePlaylistsCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    useDownloadArchiveCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    useExternalParametersForYTDLPCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    useDefaultDownloadLocationCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    downloadAudioOnlyCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    useReencodingCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    prioritiseVideoQualityCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    prioritiseAudioQualityCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    terminateScriptAfterDownloadCheckbox.OnEvent("Click", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    limitDownloadRateEdit.OnEvent("Change", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    customParamersEdit.OnEvent("Change", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    customDownloadLocationEdit.OnEvent("Focus", (*) => handleDownloadOptionsGUI_CustomDownloadPath())
    chooseVideoFormatDropDownList.OnEvent("Change", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    chooseAudioFormatDropDownList.OnEvent("Change", (*) => handleDownloadOptionsGUI_ResolveElementConflicts())
    startDownloadButton.OnEvent("Click", (*) => startDownload(buildCommandString()))
    cancelDownloadButton.OnEvent("Click", (*) => cancelDownload())
    savePresetButton.OnEvent("Click", (*) => handleDownloadOptionsGUI_Button_savePreset_waitForSecondClick())
    loadPresetButton.OnEvent("Click", (*) => handleDownloadOptionsGUI_Button_loadPreset_waitForSecondClick())
}

; Runs a few commands when the script is executed.
optionsGUI_onInit()
{
    global downloadOptionsGUITooltipFileLocation

    createDownloadOptionsGUI()
    buildCommandString()
    Sleep(1000)
    ; Checks for the last settings file to restore settings from the last download.
    If (!loadGUISettingsFromPreset("last_settings_(TEMP)", , true))
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
    generateHWNDArrayFile()
    If (ProcessExist("DownloadOptionsGUITooltips.exe"))
    {
        ProcessClose("DownloadOptionsGUITooltips.exe")
    }
    ; If the tooltip executable startup is disabled or the script is not compiled, the tooltip executable won't start.
    If (!readConfigFile("disableTooltipStartup") && A_IsCompiled)
    {
        Try
        {
            Run(downloadOptionsGUITooltipFileLocation . " " . downloadOptionsGUI.Hwnd)
        }
        Catch As error
        {
            displayErrorMessage(error, "This is not a fatal error.", , 10)
        }
    }
}

cancelDownload()
{
    global booleanDownloadTerminated

    result := MsgBox("Do you really want to cancel the running download process ?", "VD - Cancel Download Process?", "YN Icon! 262144")

    If (result = "Yes")
    {
        booleanDownloadTerminated := true
        Try
        {
            ProcessClose(("ahk_pid " . hiddenConsolePID))
            WinClose(("ahk_pid " . hiddenConsolePID))
        }
    }
}

; This function will enable / disable elements accordingly to the user input in the GUI to prevent wrong or impossible inputs.
handleDownloadOptionsGUI_ResolveElementConflicts()
{
    global newDownloadFolder := ""

    Switch (ignoreAllOptionsCheckbox.Value)
    {
        Case true:
        {
            ; Execute a pure download with only necessary parameters while disabeling all other options.
            clearURLFileAfterDownloadCheckbox.Opt("+Disabled")
            enableFastDownloadModeCheckbox.Opt("+Disabled")
            limitDownloadRateEdit.Opt("+Disabled")
            maxDownloadSizeEdit.Opt("+Disabled")
            useEmbeddingCheckbox.Opt("+Disabled")
            downloadVideoDescriptionCheckbox.Opt("+Disabled")
            downloadVideoCommentsCheckbox.Opt("+Disabled")
            downloadVideoThumbnailCheckbox.Opt("+Disabled")
            downloadVideoSubtitlesCheckbox.Opt("+Disabled")
            downloadWholePlaylistsCheckbox.Opt("+Disabled")
            useDownloadArchiveCheckbox.Opt("+Disabled")
            chooseVideoFormatDropDownList.Opt("+Disabled")
            useReencodingCheckbox.Opt("+Disabled")
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("+Disabled")
        }
        Case false:
        {
            ; Do not ignore all possible options.
            clearURLFileAfterDownloadCheckbox.Opt("-Disabled")
            enableFastDownloadModeCheckbox.Opt("-Disabled")
            limitDownloadRateEdit.Opt("-Disabled")
            maxDownloadSizeEdit.Opt("-Disabled")
            useEmbeddingCheckbox.Opt("-Disabled")
            downloadVideoDescriptionCheckbox.Opt("-Disabled")
            downloadVideoCommentsCheckbox.Opt("-Disabled")
            downloadVideoThumbnailCheckbox.Opt("-Disabled")
            downloadVideoSubtitlesCheckbox.Opt("-Disabled")
            downloadWholePlaylistsCheckbox.Opt("-Disabled")
            useDownloadArchiveCheckbox.Opt("-Disabled")
            chooseVideoFormatDropDownList.Opt("-Disabled")
            useReencodingCheckbox.Opt("-Disabled")
            prioritiseVideoQualityCheckbox.Opt("-Disabled")
            prioritiseAudioQualityCheckbox.Opt("-Disabled")
            chooseAudioFormatDropDownList.Opt("-Disabled")
        }
    }
    Switch (enableFastDownloadModeCheckbox.Value)
    {
        Case true:
        {
            ; Disables time consuming parameters.
            limitDownloadRateEdit.Opt("+Disabled")
            useEmbeddingCheckbox.Opt("+Disabled")
            downloadVideoDescriptionCheckbox.Opt("+Disabled")
            downloadVideoCommentsCheckbox.Opt("+Disabled")
            downloadVideoThumbnailCheckbox.Opt("+Disabled")
            downloadVideoSubtitlesCheckbox.Opt("+Disabled")
            chooseVideoFormatDropDownList.Opt("+Disabled")
            useReencodingCheckbox.Opt("+Disabled")
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
            chooseAudioFormatDropDownList.Opt("+Disabled")
        }
        Case false:
        {
            If (!ignoreAllOptionsCheckbox.Value)
            {
                ; Enables time consuming parameters.
                useEmbeddingCheckbox.Opt("-Disabled")
                limitDownloadRateEdit.Opt("-Disabled")
                downloadVideoDescriptionCheckbox.Opt("-Disabled")
                downloadVideoCommentsCheckbox.Opt("-Disabled")
                downloadVideoThumbnailCheckbox.Opt("-Disabled")
                downloadVideoSubtitlesCheckbox.Opt("-Disabled")
                chooseVideoFormatDropDownList.Opt("-Disabled")
                useReencodingCheckbox.Opt("-Disabled")
                prioritiseVideoQualityCheckbox.Opt("-Disabled")
                prioritiseAudioQualityCheckbox.Opt("-Disabled")
                chooseAudioFormatDropDownList.Opt("-Disabled")
            }
        }
    }
    Switch (downloadAudioOnlyCheckbox.Value)
    {
        Case true:
        {
            ; You can only choose a format when not using fast download options.
            If (!enableFastDownloadModeCheckbox.Value && !ignoreAllOptionsCheckbox.Value)
            {
                chooseAudioFormatDropDownList.Opt("-Disabled")
            }
            chooseVideoFormatDropDownList.Opt("+Disabled")
            useReencodingCheckbox.Opt("+Disabled")
            prioritiseVideoQualityCheckbox.Opt("+Disabled")
            prioritiseAudioQualityCheckbox.Opt("+Disabled")
        }
        Case false:
        {
            If (!enableFastDownloadModeCheckbox.Value && !ignoreAllOptionsCheckbox.Value)
            {
                chooseVideoFormatDropDownList.Opt("-Disabled")
                chooseAudioFormatDropDownList.Opt("+Disabled")
                useReencodingCheckbox.Opt("-Disabled")
                prioritiseVideoQualityCheckbox.Opt("-Disabled")
                prioritiseAudioQualityCheckbox.Opt("-Disabled")
            }
            ; This prevents the other options from beeing enabled while on of the checkboxes below is ticked.
            Else If (enableFastDownloadModeCheckbox.Value || ignoreAllOptionsCheckbox.Value)
            {
                chooseAudioFormatDropDownList.Opt("+Disabled")
            }
        }
    }
    ; Prioritizing options will only be enabled when the options below are disabled.
    If (!enableFastDownloadModeCheckbox.Value && !ignoreAllOptionsCheckbox.Value && !downloadAudioOnlyCheckbox.Value)
    {
        Switch (prioritiseVideoQualityCheckbox.Value)
        {
            Case true:
            {
                prioritiseAudioQualityCheckbox.Opt("+Disabled")
            }
            Case false:
            {
                prioritiseAudioQualityCheckbox.Opt("-Disabled")
            }
        }
        Switch (prioritiseAudioQualityCheckbox.Value)
        {
            Case true:
            {
                prioritiseVideoQualityCheckbox.Opt("+Disabled")
            }
            Case false:
            {
                prioritiseVideoQualityCheckbox.Opt("-Disabled")
            }
        }
    }
    ; Prevents issues when the number field has no digits in it.
    Try
    {
        If (limitDownloadRateEdit.Value > 1000 || limitDownloadRateEdit.Value < 0)
        {
            limitDownloadRateEdit.Value := 0
        }
        If (maxDownloadSizeEdit.Value < 0)
        {
            maxDownloadSizeEdit.Value := 0
        }
    }
    Switch (useExternalParametersForYTDLPCheckbox.Value)
    {
        Case true:
        {
            ; Allows for extra parameters to be passed to yt-dlp.
            customParamersEdit.Opt("-Disabled")
            ; Makes sure that a user input will not be overwritten.
            If (customParamersEdit.Value = "Currently not using extra parameters.")
            {
                customParamersEdit.Value := "You can now enter your own parameters."
            }
        }
        Case false:
        {
            ; Uses only internal parameters passed to yt-dlp.
            customParamersEdit.Opt("+Disabled")
            customParamersEdit.Value := "Currently not using extra parameters."
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
}

; This function will take every relevant input from the GUI and process it to create a part from the command string.
handleDownloadOptionsGUI_ProcessCommandStringInputs()
{
    global commandString
    tmpConfig := readConfigFile("DOWNLOAD_PATH")

    Switch (downloadAudioOnlyCheckbox.Value)
    {
        Case 1:
        {
            commandString .= '--format "bestaudio" '
            commandString .= "--extract-audio "
            ; Only extracts the audio with a specific format when there are now fast download options used.
            If (downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] != "Best format for quality"
                && !enableFastDownloadModeCheckbox.Value && !ignoreAllOptionsCheckbox.Value)
            {
                commandString .= '--audio-format "' . downloadAudioFormatArray[chooseAudioFormatDropDownList.Value] . '" '
            }
        }
    }
    If (ignoreAllOptionsCheckbox.Value)
    {
        ; All other options are considered to be ignored.
        Return
    }
    If (maxDownloadSizeEdit.Value != 0)
    {
        ; Limit the download file size to a maximum value in Megabytes.
        commandString .= '--match-filter "filesize_approx<' . maxDownloadSizeEdit.Value . 'M" '
    }
    Switch (downloadWholePlaylistsCheckbox.Value)
    {
        Case 0:
        {
            commandString .= "--no-playlist "
        }
        Case 1:
        {
            ; Useful if you want to download a complete playlist but you have only selected one video.
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
            ; Useful if you want to download a video once.
            ; There is always an option to ignore the archive file.
            commandString .= '--download-archive "' . readConfigFile("DOWNLOAD_ARCHIVE_LOCATION") . '" '
        }
    }
    If (enableFastDownloadModeCheckbox.Value)
    {
        ; All other options are considered to be ignored.
        Return
    }
    ; Beginning of the "casual" options.
    Switch (downloadVideoDescriptionCheckbox.Value)
    {
        Case 0:
        {
            ; Do not download the video description.
            commandString .= "--no-write-description "
        }
        Case 1:
        {
            ; Add the video description to a .DESCRIPTION file.
            commandString .= "--write-description "
            If (useDefaultDownloadLocationCheckbox.Value)
            {
                commandString .= '--paths "description:' . tmpConfig . '\' . downloadTime . '\description(s)" '
            }
            Else
            {
                commandString .= '--paths "description:' . customDownloadLocationEdit.Value . '\description(s)" '
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
            ; Download the video's comment section.
            commandString .= "--write-comments "
            ; Currently not implemeted into yt-dlp.
            ; commandString .= '--paths "comments:' . readConfigFile("DOWNLOAD_PATH") . '\' . downloadTime . '\comments" '
            ; This script contains a work arround for moving the comments to a desired folder.
            ; See startDownload() for more info.
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
            commandString .= "--write-thumbnail "
            If (useEmbeddingCheckbox.Value)
            {
                commandString .= "--embed-thumbnail "
            }
            If (useDefaultDownloadLocationCheckbox.Value)
            {
                commandString .= '--paths "thumbnail:' . tmpConfig . '\' . downloadTime . '\thumbnail(s)" '
            }
            Else
            {
                commandString .= '--paths "thumbnail:' . customDownloadLocationEdit.Value . '\thumbnail(s)" '
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
            ; Download the video's subtitles and embed them into the downloaded video.
            commandString .= "--write-subs "
            commandString .= '--sub-langs "all" '
            If (useEmbeddingCheckbox.Value)
            {
                commandString .= "--embed-subs "
            }
            If (useDefaultDownloadLocationCheckbox.Value)
            {
                commandString .= '--paths "subtitle:' . tmpConfig . '\' . downloadTime . '\subtitle(s)" '
            }
            Else
            {
                commandString .= '--paths "subtitle:' . customDownloadLocationEdit.Value . '\subtitle(s)" '
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
            ; Useful if you want to download a complete playlist but you have only selected one video.
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
            ; Useful if you want to download a video once.
            ; There is always an option to ignore the archive file.
            commandString .= '--download-archive "' . readConfigFile("DOWNLOAD_ARCHIVE_LOCATION") . '" '
        }
    }
    Switch (prioritiseVideoQualityCheckbox.Value)
    {
        Case true:
        {
            commandString .= '--format "bestvideo" '
        }
    }
    Switch (prioritiseAudioQualityCheckbox.Value)
    {
        Case true:
        {
            commandString .= '--format "bestaudio" '
        }
    }
    If (downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] != "Best format for quality")
    {
        Switch (useReencodingCheckbox.Value)
        {
            Case true:
            {
                ; Recodes into a selected format.
                commandString .= '--recode-video "' . downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . '" '
            }
            Case false:
            {
                ; Tries to download the selected format directly (resolution capped at 1080x1920).
                commandString .= '--format "[ext=' .
                    downloadVideoFormatArray[chooseVideoFormatDropDownList.Value] . ']" '
            }
        }
    }
}

; This function will prompt the user to choose a new download path. Saves the last download path.
handleDownloadOptionsGUI_CustomDownloadPath()
{
    global newDownloadFolder
    static newDownloadFolderLocal := ""

    If (customDownloadLocationEdit.Value = "You can now specify your own download path.")
    {
        If (newDownloadFolderLocal = "")
        {
            newDownloadFolderLocal := DirSelect("*" . readConfigFile("DOWNLOAD_PATH"), 3, "Select download folder")
        }
        Else
        {
            newDownloadFolderLocal := DirSelect("*" . newDownloadFolderLocal, 3, "Select download folder")
        }
        If (newDownloadFolderLocal = "")
        {
            MsgBox("Invalid folder selection.", "VD - Invalid Path!", "O IconX T1.5")
            ; Checks the default download location checkbox so that the user loses focus on the input field.
            ; Therefore he can click on it again and the "focus" event will be triggered.
            useDefaultDownloadLocationCheckbox.Value := 1
            handleDownloadOptionsGUI_ResolveElementConflicts()
        }
        Else
        {
            customDownloadLocationEdit.Value := newDownloadFolderLocal
        }
        newDownloadFolder := newDownloadFolderLocal
    }
}

/*
This function parses through all values of the GUI and builds a command string,
which bill be given to the yt-dlp command prompt.
@returns [String] A command string ready to execute with yt-dlp.
*/
buildCommandString()
{
    ; Formats the value of A_Now to give each folder a unique time stamp.
    global downloadTime := FormatTime(A_Now, "dd.MM.yyyy_HH-mm-ss")
    global commandString := "yt-dlp "
    tmpConfig := readConfigFile("DOWNLOAD_PATH")
    ; Makes sure that there are no conflicting options.
    handleDownloadOptionsGUI_ResolveElementConflicts()
    ; The switch below will evaluae if extra parameters will be inserted.
    Switch (useExternalParametersForYTDLPCheckbox.Value)
    {
        Case 1:
        {
            commandString .= '' . customParamersEdit.Value . ' '
        }
    }
    SplitPath(readConfigFile("URL_FILE_LOCATION"), , &outDir)
    commandString .= '--batch-file "' . outDir . '\YT_URLS_CURRENTLY_DOWNLOADING.txt" '
    Switch (useDefaultDownloadLocationCheckbox.Value)
    {
        Case 0:
        {
            commandString .= '--paths "' . customDownloadLocationEdit.Value . '\media" '
        }
        Case 1:
        {
            commandString .= '--paths "' . tmpConfig . '\' . downloadTime . '\media" '
        }
    }
    handleDownloadOptionsGUI_ProcessCommandStringInputs()
    ; This makes sure that the output file does not contain the video URL.
    commandString .= '--output "%(title)s.%(ext)s" '
    ; Sets the temporary directory for yt-dlp.
    commandString .= '--paths "temp:' . tmpConfig . '\temporaryStorage" '
    ; Might help to enforce the max-filesize option.
    commandString .= "--no-part "
    ; Makes the downloading message in the console a little prettier.
    commandString .= '--progress-template "[Downloading...] [%(progress._percent_str)s of %(progress._total_bytes_str)s ' .
        'at %(progress._speed_str)s. Time passed: %(progress._elapsed_str)s]" '
    ; Adds the ffmpeg location for the script to remux videos or extract audio etc.
    commandString .= '--ffmpeg-location "' . ffmpegLocation . '" '
    Return commandString
}

; The function is used to generate necessary information for the download options GUI tooltip executable.
generateHWNDArrayFile()
{
    global downloadOptionsGUI

    elementHWNDArray := []
    tmpArray := []
    arrayCounter := 1
    fileLocation := A_Temp . "\download_options_GUI_HWND_File.txt"
    ; Saves the HWND of all GUI elements into the HWND array.
    For (GUICtrlObj in downloadOptionsGUI)
    {
        ; This condition ignore all other GUI elements except of checkboxes, edits and lists.
        If (InStr(GUICtrlObj.Type, "Checkbox") || InStr(GUICtrlObj.Type, "Edit")
            || InStr(GUICtrlObj.Type, "DDL") || InStr(GUICtrlObj.Type, "Button"))
        {
            tmpArray.InsertAt(arrayCounter, GUICtrlObj.Hwnd)
            arrayCounter++
        }
    }
    ; Prepares empty array slots for the next step.
    Loop (tmpArray.Length)
    {
        elementHWNDArray.InsertAt(A_Index, "")
    }
    ; This Loop inverts the order of the elements inside the tmpArray so that the order is correct when the items are
    ; read again by the file read loop. It makes sense, trust me bro.
    Loop (tmpArray.Length)
    {
        elementHWNDArray.InsertAt(tmpArray.Length - A_Index + 1, tmpArray.Get(A_Index))
    }
    Try
    {
        FileDelete(fileLocation)
    }
    Loop (elementHWNDArray.Length)
    {
        FileAppend(elementHWNDArray.Get(A_Index) . "`n", fileLocation)
    }
}

/*
Saves all options from the download options GUI into a text file for future use.
NOTE: pBooleanTemporary and pBooleanDefault cannot be true at the same time.
@param pPresetName [String] The name of the preset to create.
@param pBooleanTemporary [boolean] If set to true, the preset will created as temporary and deleted once it has been loaded.
@param pBooleanDefault [boolean] If set to true, will make the created preset the default one, which will be loaded
when the script is launched.
@returns [boolean] Depending on the preset creation success.
*/
saveGUISettingsAsPreset(pPresetName, pBooleanTemporary := false, pBooleanDefault := false)
{
    If (pBooleanTemporary && pBooleanDefault)
    {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] pBooleanTemporary and pBooleanDefault cannot be true at the "
            . "same time.", "VD - [" . A_ThisFunc . "()]", "Icon! 262144")
        Return false
    }
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    presetFileArray := handleDownloadOptionsGUI_RefreshPresetArray()

    ; In case the user wants to accidentally create a preset with an empty name.
    If (pPresetName = "")
    {
        Return MsgBox("Please provide a name for your preset.", "VD - No Preset Name!", "O Icon! T2")
    }
    Else If (pBooleanTemporary)
    {
        ; This avoids double "_(TEMP)" pieces.
        If (!InStr(pPresetName, "_(TEMP)", true))
        {
            presetNameWithTag := pPresetName . "_(TEMP)"
        }
    }
    Else If (pBooleanDefault)
    {
        ; This avoids double "_(DEFAULT)" pieces.
        If (!InStr(pPresetName, "_(DEFAULT)", true))
        {
            presetNameWithTag := pPresetName . "_(DEFAULT)"
        }
    }
    ; If there is no special option given.
    Else
    {
        presetNameWithTag := pPresetName
    }
    presetLocationComplete := presetLocation . "\" . pPresetName . ".ini"
    presetLocationCompleteWithTag := presetLocation . "\" . presetNameWithTag . ".ini"

    Loop (presetFileArray.Length)
    {
        ; Searches for an existing default file.
        If (InStr(presetFileArray.Get(A_Index), "_(DEFAULT)", true))
        {
            booleanDefaultPresetExist := true
            defaultPresetOld := presetFileArray.Get(A_Index)
            Break
        }
        Else
        {
            booleanDefaultPresetExist := false
        }
    }

    If (FileExist(presetLocationCompleteWithTag))
    {
        ; This avoids showing the overwrite prompt for _(TEMP) presets.
        If (!pBooleanTemporary)
        {
            result := MsgBox("The preset name [" . presetNameWithTag . "] already exists."
                "`n`nDo you want to overwrite it ?", "VD - Overwrite Existing Preset?", "YN Icon! 262144")
            If (result != "Yes")
            {
                Return false
            }
        }
        Try
        {
            FileDelete(presetLocationCompleteWithTag)
        }
        Catch As error
        {
            displayErrorMessage(error, "This is not a fatal error.", , 10)
        }
        Return saveGUISettingsAsPreset(pPresetName, pBooleanTemporary, pBooleanDefault)
    }
    If (booleanDefaultPresetExist && pBooleanDefault)
    {
        result := MsgBox("An existing default file has been found.`n`nChange default preset file from ["
            . defaultPresetOld . "] to [" . presetNameWithTag . "]?",
            "VD - Change Default Preset File?", "YN Icon! 262144")
        If (result != "Yes")
        {
            Return false
        }
        ; Removes the "_(DEFAULT)" part from the old default preset file.
        tmp1 := presetLocation . "\" . defaultPresetOld . ".ini"
        tmp2 := presetLocation . "\" . StrReplace(defaultPresetOld, "_(DEFAULT)", "", true) . ".ini"
        FileMove(tmp1, tmp2, true)

    }
    ; Important because this means that an existing file will be used to be stored as the new default preset file.
    If (FileExist(presetLocation . "\" . pPresetName . ".ini"))
    {
        FileMove(presetLocationComplete, presetLocationCompleteWithTag, true)
    }
    Else
    {
        i_Input := 1
        i_DropDownList := 1
        ; Creates a new preset file.
        For (GUICtrlObj in downloadOptionsGUI)
        {
            ; Makes sure only checkbox values are extracted.
            If (InStr(GUICtrlObj.Type, "Checkbox"))
            {
                IniWrite(GUICtrlObj.Value, presetLocationCompleteWithTag, "Checkboxes", "{" . GUICtrlObj.Text . "}")
            }
            If (InStr(GUICtrlObj.Type, "Edit"))
            {
                IniWrite(GUICtrlObj.Value, presetLocationCompleteWithTag, "Edits", "{Input_" . i_Input . "}")
                i_Input++
            }
            If (InStr(GUICtrlObj.Type, "DDL"))
            {
                IniWrite(GUICtrlObj.Value, presetLocationCompleteWithTag, "DropDownLists", "{DropDownList_" . i_DropDownList . "}")
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
    selectAndAddPresetsComboBox.Add(handleDownloadOptionsGUI_RefreshPresetArray())
    Return true
}

/*
Loads the saved settings from the preset files.
@param pPresetName [String] The name of the preset to load.
@param pBooleanDeletePreset [boolean] If set to true, tries to delete the preset file.
@param pBooleanSupressWarning [boolean] If set to true, the warning message will be hidden in case a preset does not exist.
@returns [boolean] Depending on the preset load success.
*/
loadGUISettingsFromPreset(pPresetName, pBooleanDeletePreset := false, pBooleanSupressWarning := false)
{
    presetLocation := readConfigFile("DOWNLOAD_PRESET_LOCATION")
    presetLocationComplete := presetLocation . "\" . pPresetName . ".ini"
    i_Input := 1
    i_DropDownList := 1

    If (pPresetName = "")
    {
        If (!pBooleanSupressWarning)
        {
            MsgBox("Please enter a valid preset.", "VD - No Preset Name!", "O Icon! T2")
        }
        Return false
    }
    Else If (!FileExist(presetLocationComplete))
    {
        If (!pBooleanSupressWarning)
        {
            MsgBox("The preset [" . pPresetName . "] does not exist.", "VD - Preset Not Found!", "O Icon! T2")
        }
        Return false
    }
    ; Only tries to load the preset if there is no delete instruction.
    Else If (!pBooleanDeletePreset)
    {
        For (GUICtrlObj in downloadOptionsGUI)
        {
            ; Makes sure only checkbox values are extracted.
            If (InStr(GUICtrlObj.Type, "Checkbox"))
            {
                Try
                {
                    newCheckboxValue := IniRead(presetLocationComplete, "Checkboxes", "{" . GUICtrlObj.Text . "}")
                    GUICtrlObj.Value := newCheckboxValue
                }
                Catch
                {
                    MsgBox("Failed to set value of: " . GUICtrlObj.Text . ".", "VD - Preset Value - Warning!", "O Icon! T3")
                }
            }
            If (InStr(GUICtrlObj.Type, "Edit"))
            {
                Try
                {
                    newEditValue := IniRead(presetLocationComplete, "Edits", "{Input_" . i_Input . "}")
                    GUICtrlObj.Value := newEditValue
                    i_Input++
                }
                Catch
                {
                    MsgBox("Failed to set value of: {Input_ " . i_Input . "}.", "VD - Preset Value - Warning!", "O Icon! T3")
                }
            }
            If (InStr(GUICtrlObj.Type, "DDL"))
            {
                Try
                {
                    newDropDownListValue := IniRead(presetLocationComplete, "DropDownLists", "{DropDownList_" . i_DropDownList . "}")
                    GUICtrlObj.Value := newDropDownListValue
                    i_DropDownList++
                }
                Catch
                {
                    MsgBox("Failed to set value of: {DropDownList_ " . i_DropDownList . "}.", "VD - Preset Value - Warning!", "O Icon! T3")
                }
            }
            ; Counts the number of elements parsed. When it reaches 37 this means that all relevant settings have been loaded.
            ; All remaining GUI elements belong to the preset section and are not meant to be loaded.
            ; REMOVE
            If (A_Index >= 38)
            {
                Break
            }
        }
    }
    ; Deletes the preset either if it is temporary or the instruction to delete it is given.
    If (InStr(pPresetName, "_(TEMP)", true) || pBooleanDeletePreset)
    {
        Try
        {
            FileDelete(presetLocationComplete)
        }
        Catch As error
        {
            displayErrorMessage(error, "This is not a fatal error.", , 10)
        }
    }
    handleDownloadOptionsGUI_ResolveElementConflicts()
    ; This ensures that the preset list is updated in the combo box.
    selectAndAddPresetsComboBox.Delete()
    selectAndAddPresetsComboBox.Add(handleDownloadOptionsGUI_RefreshPresetArray())
    ; Returns false because deleting a preset should not be counted as a loading success.
    If (pBooleanDeletePreset)
    {
        Return false
    }
    Return true
}

/*
Refreshes the download options GUI's preset drop down menu array.
@returns [Array] An array containing all preset names.
*/
handleDownloadOptionsGUI_RefreshPresetArray()
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

; Enables the save preset button to have two functions, if either double clicked or single clicked.
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

; Enables the load preset button to have two functions, if either double clicked or single clicked.
handleDownloadOptionsGUI_Button_loadPreset_waitForSecondClick()
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
            loadGUISettingsFromPreset(selectAndAddPresetsComboBox.Text)
        }
        Else If (click_amount = 2)
        {
            loadGUISettingsFromPreset(selectAndAddPresetsComboBox.Text, true)
        }
        click_amount := 0
    }
}