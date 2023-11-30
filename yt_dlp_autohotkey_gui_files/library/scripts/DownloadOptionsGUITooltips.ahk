#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

onInit()

onInit()
{
    global downloadOptionsGUIHWNDFileLocation := A_Temp . "\download_options_GUI_HWND_File.txt"
    global downloadOptionsGUIID := ""
    global downloadOptionsGUIHWNDArray := []

    ProcessSetPriority("BelowNormal")

    If (!ProcessExist("VideoDownloader.exe"))
    {
        MsgBox("No target application detected.", "VD - Tooltip Manager", "O Iconi T3")
        ExitApp()
    }
    If (!A_Args.Has(1))
    {
        MsgBox("This is a sub script from VideoDownloader which can only be called with specific parameters. "
            . "It is responsible for showing tooltips to the user.`n`nHave a nice day :)", "VD - Tooltip Manager", "O Iconi T6")
        ExitApp()
    }

    ; NOTE: Make sure that the parameter given as the ID is valid!
    downloadOptionsGUIID := A_Args.Get(1)
    downloadOptionsGUIHWNDArray := getHWNDArrayFromFile(downloadOptionsGUIHWNDFileLocation, 30)
    ; Starts the clock.
    clock()
}

; Runs the script at a certain tick rate to trigger the tooltip check.
clock()
{
    global downloadOptionsGUIID

    Loop
    {
        If (!ProcessExist("VideoDownloader.exe"))
        {
            Break
        }
        If (WinActive("ahk_id " . downloadOptionsGUIID))
        {
            handleDownloadOptionsGUI_toolTipLoop()
        }
        Sleep(1000)
    }
    ExitApp()
}

getHWNDArrayFromFile(pFileLocation, pExpectedAmount)
{
    fileLocation := pFileLocation
    ; Serves as a control condition in case something goes wrong.
    expectedAmount := pExpectedAmount
    HWNDArray := []

    If (!FileExist(fileLocation))
    {
        MsgBox("Missing HWND file.", "VD - Tooltip Manager", "O Iconi T3")
        ExitApp()
    }
    ; In this case I cannot use A_LoopIndex because it would break when the loop skips an empty line.
    i := 1
    Loop Read (fileLocation)
    {
        If (A_LoopReadLine != "")
        {
            HWNDArray.InsertAt(i, A_LoopReadLine)
        }
    }
    If (HWNDArray.Length != expectedAmount)
    {
        MsgBox("The amount of buttons does not match the expected amount.", "VD - Tooltip Manager", "O Iconi T3")
    }
    Try
    {
        FileDelete(fileLocation)
    }
    Return HWNDArray
}

; When called checks if the mouse hovers over a GUI element and shows the specific tooltip.
handleDownloadOptionsGUI_toolTipLoop()
{
    global downloadOptionsGUIHWNDArray
    global downloadOptionsGUIID

    elementHWNDArray := downloadOptionsGUIHWNDArray
    GUIID := downloadOptionsGUIID
    ; Contains an individual tooltip for every control that requires one.
    static elementToolTipArray := []
    If (!elementToolTipArray.Has(2))
    {
        tmp1 := "Ignores errors thrown by most events."
        tmp2 := "Generally not recommended, except for debug reasons."
        tmp3 := "Starts the download with the required options only."
        tmp4 := "Hides the PowerShell status window and disables all script notifications concerning the download process."
        tmp5 := "Uncheck this option to prevent the script from deleting the URL file after the download has finished."
        tmp6 := "Disables most time-consuming options to increase download and processing speed."
        tmp7 := "Why would anyone ever do this? Anyway you have the option to do so."
        tmp8 := "This option limits files to a maximum size. If the file is larger, its download will be skipped."
            . "`nThis option is still experimental and might cause weird results."
        tmp9 := "Useful option to try when the download fails too often."
        tmp10 := "Downloads the video discription, what did you expect?"
        tmp11 := "The comment section will be saved as a .JSON file."
        tmp12 := "By default the video thumbnail will be embedded into the video file."
        tmp13 := "The script will try to download every available subtitle`nlanguage and embedd them into the video file."
        tmp14 := "Forces the download of complete playlists if a URL contains a reference to it."
        tmp15 := "Saves downloaded video URLs into an archive file to avoid downloading a video twice."
        tmp16 := "Select a video format. This can increase the download processing time. "
            . "When using options such as thumbnail or subtitle embedding,`nkeep in mind that those are not supported by "
            . "every video format and might cause the operation to fail. Some formats might not be available and require the re-encode option below."
        tmp17 := "In case you only want the audio."
        tmp18 := "Select an audio format. Some audio formats might not be available from a video."
        tmp19 := "Recodes the video to another format using FFmpeg, which will dramatically increase processing time, but allows "
            . "higher resolutions than 1080*1920."
            . " When using options such as thumbnail or subtitle embedding,`nkeep in mind that those are not supported by "
            . "every video format and might cause the operation to fail."
        tmp20 := "So you don't care about audio quality?"
        tmp21 := "*sad video quality noises*"
        tmp22 := "Usually, a text file will be given to yt-dlp to download, but it is also possible to select a single URL."
        tmp23 := "Here you can put your own URL."
        tmp24 := "Saves all downloads to the default path specified in the config file."
        tmp25 := "Keep in mind, that selecting a folder will actually download straight into it without any timestamp subfolders."
        tmp26 := "Starts the download process. The power is in your hands."
        tmp27 := "Stops the download process. Perhaps you were too powerful?"
        tmp28 := "Shows no prompt when download in a background task is activated."
        tmp29 := "Presets allow for settings to be saved and loaded later on again."
            . "`nSingle click to save a preset or double click to save as default."
        tmp30 := "The default preset will be loaded when no previous temporary preset is found."

        Loop (30)
        {
            elementToolTipArray.InsertAt(A_Index, %"tmp" . A_Index%)
            ; Clears the cache to give free space.
            %"tmp" . A_Index% := ""
        }
    }

    If (WinActive("ahk_id " . GUIID))
    {
        MouseGetPos(, , &outWinHWND, &outControlHWND, 2)
        Loop (elementHWNDArray.Length)
        {
            If (elementHWNDArray.Get(A_Index) = outControlHWND && GUIID = outWinHWND)
            {
                ; Saves the index of the outer loop because inside the while loops the value of A_Index will be different.
                tmpIndex := A_Index
                i := 0
                ; In case the cursor is above a control element it will have to stay for 2 seconds to trigger the tooltip.
                While (elementHWNDArray.Get(tmpIndex) = outControlHWND && GUIID = outWinHWND)
                {
                    Sleep(100)
                    i++
                    If (i >= 10)
                    {
                        Break
                    }
                    Else If (!(elementHWNDArray.Get(tmpIndex) = outControlHWND && GUIID = outWinHWND))
                    {
                        Return
                    }
                }
                ToolTip(elementToolTipArray.Get(A_Index))
                ; Waits for the user to read the tooltip as he stays above the control element with the cursor.
                While (elementHWNDArray.Get(tmpIndex) = outControlHWND && GUIID = outWinHWND)
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