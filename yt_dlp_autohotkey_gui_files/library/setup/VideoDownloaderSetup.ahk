#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

global scriptBaseFilesLocation := onInit_handleScriptDirectory()
global workingBaseFilesLocation := onInit_handleWorkingDirectory()
; Only needed for uninstall purposes.
global productCode := ""

onInit()

onInit()
{
    If (A_IsCompiled = false)
    {
        MsgBox("You are using the non compiled version of this script."
            "`n`nPlease continue by using a compiled version.", "Warning !", "O Icon! 262144 T5")
        generateHelpFile()
        ExitApp()
    }
    Else If (A_Args.Has(1) = false)
    {
        MsgBox("You have not provided any parameters."
            "`n`nPlease run this script using the console and valid arguments.", "Warning !", "O Icon! 262144 T5")
        generateHelpFile()
        ExitApp()
    }
    booleanParameterSetup := false
    booleanParameterForceSetup := false
    booleanParameterUninstall := false
    ; Contains the given parameters in a single string for when the script has to restart.
    parameterString := ""

    /*
    List of possible parameters to pass:
        - /run-setup
        The script will install the library files, yt-dlp and other dependencies.
        - /force-run-setup
        Same as above, but it will overwrite all existing files.
        - /run-uninstall
        Will guide the user through the uninstall process.
    */

    Loop A_Args.Length
    {
        parameterString .= A_Args.Get(A_Index) . " "
        ; The RegExMatch is used to find the product code which could be different from time to time.
        If (RegExMatch(A_Args.Get(A_Index), "/run-uninstall-{.*}", &outMatch) != 0)
        {
            outString := outMatch[]
            global productCode := StrReplace(outString, "/run-uninstall-")
            booleanParameterUninstall := true
        }
        Else
        {
            Switch (A_Args.Get(A_Index))
            {
                Case "/run-setup":
                    {
                        booleanParameterSetup := true
                    }
                Case "/force-run-setup":
                    {
                        booleanParameterForceSetup := true
                    }
                Default:
                    {
                        MsgBox("Unsupported parameters given. Specifically: " . A_Args.Get(A_Index),
                            "VideoDownloader Setup Status", "O Icon! 262144")
                        generateHelpFile()
                        ExitApp()
                    }
            }
        }
    }

    If (booleanParameterSetup = true && booleanParameterForceSetup = true)
    {
        MsgBox("/run-setup and /force-run-setup cannot be used together.",
            "VideoDownloader Setup Status", "O Icon! 262144")
        generateHelpFile()
        ExitApp()
    }
    Else If ((booleanParameterSetup = true || booleanParameterForceSetup = true) && booleanParameterUninstall)
    {
        MsgBox("You cannot use setup parameters with /run-uninstall.",
            "VideoDownloader Setup Status", "O Icon! 262144")
        generateHelpFile()
        ExitApp()
    }

    ; Makes sure the setup will be executed with admin permissions.
    fullCommandLine := DllCall("GetCommandLine", "str")
    If not (A_IsAdmin || RegExMatch(fullCommandLine, " /restart(?!\S)"))
    {
        Try
        {
            Run '*RunAs "' A_ScriptFullPath '" /restart ' . parameterString
            ExitApp()
        }
        Catch
        {
            MsgBox("Could not complete action.`n`nTerminating script.", "Error !", "O IconX T1.5")
            ExitApp()
        }
    }
    If (booleanParameterSetup = true)
    {
        run_setup()
    }
    Else If (booleanParameterForceSetup)
    {
        force_run_setup()
    }
    Else If (booleanParameterUninstall)
    {
        run_uninstall()
    }
}

createUninstallGUI()
{
    Global
    uninstallGUI := Gui(, "Uninstall yt-dlp-autohotkey-gui")
    uninstallUntilNextTimeText := uninstallGUI.Add("Text", "xp+10 yp+10 ", "Please select your uninstall options below.")
    uninstallEverythingCheckbox := uninstallGUI.Add("Checkbox", "yp+20 Checked", "Remove everything")
    uninstallPythonCheckbox := uninstallGUI.Add("Checkbox", "yp+20 ", "Uninstall python")
    uninstallYTDLPCheckbox := uninstallGUI.Add("Checkbox", "yp+20 ", "Uninstall yt-dlp")
    uninstallAllCreatedFilesCheckbox := uninstallGUI.Add("Checkbox", "yp+20 ", "Delete all script files")
    uninstallAllDownloadedFilesCheckbox := uninstallGUI.Add("Checkbox", "yp+20 ", "Delete all downloaded files")

    uninstallStartButton := uninstallGUI.Add("Button", "yp+30 w60", "Uninstall")
    uninstallCancelButton := uninstallGUI.Add("Button", "xp+65 w60 Default", "Cancel")
    uninstallOpenGitHubIssuesButton := uninstallGUI.Add("Button", "xp+65", "Open GitHub issues")
    uninstallProgressBar := uninstallGUI.Add("Progress", "xp+120 yp+3")
    uninstallStatusBar := uninstallGUI.Add("StatusBar", , "Until next time :')")

    uninstallProvideReasonEdit := uninstallGUI.Add("Edit", "xp-41 yp-130 r8 w160",
        "Provide feedback (optional)")

    uninstallEverythingCheckbox.OnEvent("Click", (*) => handleUninstallGUI_Checkboxes())
    uninstallStartButton.OnEvent("Click", (*) => uninstallScript())
    uninstallCancelButton.OnEvent("Click", (*) => uninstallGUI.Hide())
    uninstallOpenGitHubIssuesButton.OnEvent("Click", (*) => Run("https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues"))
}

; Disables all other options and marks them as true.
handleUninstallGUI_Checkboxes()
{
    If (uninstallEverythingCheckbox.Value = 1)
    {
        uninstallPythonCheckbox.Value := 1
        uninstallYTDLPCheckbox.Value := 1
        uninstallAllCreatedFilesCheckbox.Value := 1
        uninstallAllDownloadedFilesCheckbox.Value := 1

        uninstallPythonCheckbox.Opt("+Disabled")
        uninstallYTDLPCheckbox.Opt("+Disabled")
        uninstallAllCreatedFilesCheckbox.Opt("+Disabled")
        uninstallAllDownloadedFilesCheckbox.Opt("+Disabled")
    }
    Else
    {
        uninstallPythonCheckbox.Value := 0
        uninstallYTDLPCheckbox.Value := 0
        uninstallAllCreatedFilesCheckbox.Value := 0
        uninstallAllDownloadedFilesCheckbox.Value := 0

        uninstallPythonCheckbox.Opt("-Disabled")
        uninstallYTDLPCheckbox.Opt("-Disabled")
        uninstallAllCreatedFilesCheckbox.Opt("-Disabled")
        uninstallAllDownloadedFilesCheckbox.Opt("-Disabled")
    }
}

; Hotkey support function to open the script uninstall GUI.
Hotkey_openUninstallGUI()
{
    static flipflop := true
    If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
    {
        uninstallGUI.Show("w400 h200")
        flipflop := false
    }
    Else If (flipflop = false && WinActive("ahk_id " . uninstallGUI.Hwnd))
    {
        uninstallGUI.Hide()
        flipflop := true
    }
    Else
    {
        WinActivate("ahk_id " . uninstallGUI.Hwnd)
    }
}

; Normal setup which installs python and yt-dlp.
run_setup(pBooleanForceInstall := false)
{
    booleanForceInstall := pBooleanForceInstall

    ; Beginning of the setup.
    result := MsgBox("The next steps require an established Internet connection.`n`nPress Okay to continue.",
        "VideoDownloader Setup Status", "OC Iconi 4096")
    Switch (result)
    {
        Case "Cancel":
            {
                MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
            }
    }
    If (checkInternetConnection() = true)
    {
        MsgBox("You can use the computer during the setup. It is recommended to avoid restarting it during the installation process."
            . "Make sure to keep all appearing windows open until they close by themselves.", "Video Downloader Setup Status", "O Iconi")
        If (checkPythonVersion() = true)
        {
            Try
            {
                FileDelete(A_Temp . "\video_downloader_install_log.txt")
            }
            ; Will install the latest version of yt-dlp from GitHub.
            ; This was the old way but it would not receive that many updates.
            ; Run(A_ComSpec " /k pip install yt-dlp", , , &consolePID)
            If (booleanForceInstall = true)
            {
                Run(A_ComSpec ' /k python -m pip install --force-reinstall "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"',
                    , "Min", &consolePID)
                WinWait("ahk_pid " . consolePID)
                Try
                {
                    While (InStr(WinGetTitle("ahk_pid " . consolePID), "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"))
                    {
                        Sleep(1000)
                    }
                    Sleep(1500)
                }
                Catch
                {
                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
            }
            Else If (booleanForceInstall = false)
            {
                Run(A_ComSpec ' /k python -m pip install "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"',
                    , "Min", &consolePID)
                WinWait("ahk_pid " . consolePID)
                Try
                {
                    While (InStr(WinGetTitle("ahk_pid " . consolePID), "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"))
                    {
                        Sleep(1000)
                    }
                    Sleep(1500)
                }
                Catch
                {
                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
            }

            Try
            {
                ; Copies the terminal content to a text file.
                pattern := "Collecting https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"
                maxRetries := 5
                ; Creates an empty file because the loop would not execute whitout a file.
                FileAppend("", A_Temp . "\video_downloader_install_log.txt")
                ; Helps the programm to extract the content better without the user accidentally disturbing the process.
                BlockInput("On")
                While (!InStr(FileRead(A_Temp . "\video_downloader_install_log.txt"), pattern))
                {
                    WinActivate("ahk_pid " . consolePID)
                    WinActivate("ahk_pid " . consolePID)
                    Sleep(300)
                    Send("^a")
                    Sleep(300)
                    Send("^c")
                    If (ClipWait(1) = true)
                    {
                        FileAppend(A_Clipboard, A_Temp . "\video_downloader_install_log.txt")
                    }
                    If (maxRetries <= 0)
                    {
                        MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                        BlockInput("Off")
                        ExitApp()
                    }
                    maxRetries--
                }
                BlockInput("Off")
                WinClose("ahk_pid " . consolePID)
            }
            Catch
            {
                MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
            }
            WinWaitClose("ahk_pid " . consolePID)
            Try
            {
                FileCopy(A_Temp . "\video_downloader_install_log.txt", A_WorkingDir . "\video_downloader_install_log.txt", true)
            }
        }

        If (FileExist(A_WorkingDir . "\AddYTDLPToPath.ps1"))
        {
            RunWait('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\AddYTDLPToPath.ps1"', , "Min")
        }
        Else
        {
            MsgBox("Could not add yt-dlp to system environment variables.`n`nTerminating script.", "Error !", "O IconX T1.5")
            ExitApp()
        }
        If (FileExist(A_WorkingDir . "\FFmpegDownloader.ps1"))
        {
            If (booleanForceInstall = false)
            {
                RunWait('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\FFmpegDownloader.ps1" -pSetupType "/run-setup"', , "Min")
            }
            Else If (booleanForceInstall = true)
            {
                RunWait('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\FFmpegDownloader.ps1" -pSetupType "/force-run-setup"', , "Min")
            }
        }
        Else
        {
            MsgBox("Could not install FFmpeg.`n`nTerminating script.", "Error !", "O IconX T1.5")
            ExitApp()
        }
        ; Disables the forced setup and tells the main script to create any necessary files without prompt.
        RegWrite(1, "REG_DWORD",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanFirstTimeLaunch")
        RegWrite(0, "REG_DWORD",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired")
        MsgBox("The setup has been completed. You can now use the main application and start downloading videos.",
            "VideoDownloader Setup Status", "O Iconi")
        ExitApp()
    }
    Else
    {
        MsgBox("No active Internet connection found. `n`n"
            "Please connect to the Internet to use this setup.", "No Internet Connection", "48 T5")
    }
}

; Like a simple setup but it will overwrite all existing things.
force_run_setup()
{
    ; Currently not used effectively but that might change in the future.
    run_setup(true)
}

; Steps to uninstall the script.
run_uninstall()
{
    createUninstallGUI()
    handleUninstallGUI_Checkboxes()
    Hotkey_openUninstallGUI()
}

; Steps to uninstall the script.
uninstallScript()
{
    tmp1 := uninstallYTDLPCheckbox.Value
    tmp2 := uninstallPythonCheckbox.Value
    tmp3 := uninstallAllDownloadedFilesCheckbox.Value
    tmp4 := uninstallAllCreatedFilesCheckbox.Value
    uninstallProgressBarMaxValue := 0

    result := MsgBox("Are you sure that you want to continue`n`nthe script removal process ?",
        "Warning !", "YN Icon! 262144 T10")
    If (result != "Yes")
    {
        Return
    }
    ; Sets the uninstall progress bar max value according to the select uninstall steps.
    Loop (4)
    {
        uninstallProgressBarMaxValue += %"tmp" . A_Index% * 100
    }
    uninstallProgressBar.Opt("Range0-" . uninstallProgressBarMaxValue)
    uninstallStartButton.Opt("+Disabled")
    uninstallCancelButton.Opt("+Disabled")

    ; Uninstalls dependencies and other stuff.
    If (tmp1 = 1)
    {
        uninstallStatusBar.SetText("Currently uninstalling yt-dlp...")
        RunWait(A_ComSpec ' /c python -m pip uninstall -y "yt-dlp"')
        uninstallProgressBar.Value += 100
    }
    If (tmp2 = 1)
    {
        If (FileExist(scriptBaseFilesLocation . "\library\setup\video_downloader_python_install_log.txt"))
        {
            uninstallStatusBar.SetText("Currently uninstalling python...")
            Loop Read (scriptBaseFilesLocation . "\library\setup\video_downloader_python_install_log.txt")
            {
                If (InStr(A_LoopReadLine, "Python"))
                {
                    ; Removes the minor version digit.
                    tmp_fileRead := RegExReplace(A_LoopReadLine, ".[0-9]$")
                    Break
                }
            }
            RunWait(A_ComSpec ' /c winget uninstall "' . tmp_fileRead . '"')
            uninstallProgressBar.Value += 100
        }
        Else
        {
            If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
            {
                Hotkey_openUninstallGUI()
            }
            Else
            {
                WinActivate("ahk_id " . uninstallGUI.Hwnd)
            }
            uninstallStatusBar.SetText("Warning ! Could not uninstall python !")
            Sleep(2500)
            uninstallStatusBar.SetText("You may uninstall it manually.")
            Sleep(2500)
            uninstallProgressBar.Value += 100
        }
    }
    If (tmp3 = 1)
    {
        uninstallStatusBar.SetText("Deleting downloaded files...")
        Try
        {
            FileRecycle(workingBaseFilesLocation . "\download")
        }
        If (DirExist(workingBaseFilesLocation . "\download"))
        {
            uninstallStatusBar.SetText("Warning ! Could not delete downloaded files !")
            Sleep(2500)
            uninstallStatusBar.SetText("You may delete them manually.")
            Sleep(2500)
        }
        uninstallProgressBar.Value += 100
    }
    If (tmp4 = 1)
    {
        evacuationError := false
        uninstallStatusBar.SetText("Deleting script files...")
        ; This means that the remaining download files have to be evacuated.
        If (tmp3 = false)
        {
            Try
            {
                uninstallStatusBar.SetText("Moving downloaded files to desktop...")
                DirMove(workingBaseFilesLocation . "\download", A_Desktop . "\yt_dlp_autohotkey_gui_downloads_after_uninstall", 1)
            }
            Catch
            {
                If (DirExist(workingBaseFilesLocation . "\download"))
                {
                    evacuationError := true
                    uninstallStatusBar.SetText("Warning ! Could not save downloaded files !")
                    Sleep(2500)
                    uninstallStatusBar.SetText("The script file deletion process will be skipped.")
                    Sleep(2500)
                }
            }
            Try
            {
                If (evacuationError = false)
                {
                    FileRecycle(scriptBaseFilesLocation)
                }
            }
            uninstallProgressBar.Value += 100
        }
        Else
        {
            Try
            {
                FileRecycle(scriptBaseFilesLocation)
            }
            Catch
            {
                uninstallStatusBar.SetText("Warning ! Could not delete script files !")
                Sleep(2500)
                uninstallStatusBar.SetText("The script file deletion process will be skipped.")
                Sleep(2500)
            }
        }
        uninstallProgressBar.Value += 100
    }
    Sleep(3000)
    uninstallStatusBar.SetText("Finishing removal process...")
    Sleep(2000)
    If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
    {
        Hotkey_openUninstallGUI()
    }
    Else
    {
        WinActivate("ahk_id " . uninstallGUI.Hwnd)
    }
    uninstallStatusBar.SetText("Successfully uninstalled script dependencies. Until next time :')")
    Sleep(5000)
    Run(A_ComSpec ' /c msiexec.exe /x "' . productCode . '" /quiet', , "Min")
    If (ProcessExist("VideoDownloader.exe"))
    {
        ProcessClose("VideoDownloader.exe")
    }
    ExitApp()
}

checkPythonVersion()
{
    Try
    {
        FileDelete(A_Temp . "\video_downloader_python_install_log.txt")
    }
    RunWait(A_ComSpec ' /c python --version > "' . A_Temp . '\video_downloader_python_install_log.txt"')
    Sleep(500)
    ; This occures when the command does not achieve anything => python is not installed.
    If (FileRead(A_Temp . "\video_downloader_python_install_log.txt") = "")
    {
        result := MsgBox("No valid PYTHON installation found.`n`nWould you like to install PYTHON now ?",
            "VideoDownloader Setup Status", "OC Icon? 4096")
        Switch (result)
        {
            Case "OK":
                {
                    Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements',
                        , "Min", &consolePID)
                    Sleep(1500)
                    Try
                    {
                        While (InStr(WinGetTitle("ahk_pid " . consolePID), 'install "python"'))
                        {
                            Sleep(1000)
                        }
                        WinClose("ahk_pid " . consolePID)
                        MsgBox("Please wait for PYTHON to be installed completly. The script installation is still running"
                            . " in the background and will continue in a few seconds.", "Video Downloader Setup Status", "O Iconi T5")
                        Sleep(15000)
                        Return checkPythonVersion()
                    }
                    Catch
                    {
                        MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
                        ExitApp()
                    }
                }
            Case "Cancel":
                {
                    MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
        }
    }
    Loop Parse (FileRead(A_Temp . "\video_downloader_python_install_log.txt"))
    {
        ; Scanns the output from the console and extracts the python version.
        If (RegExMatch(A_LoopReadLine, "[0-9]+.[0-9]+.[0-9]+", &outMatch) != 0)
        {
            outString := outMatch[]
            ; The minimum recommended python version to run yt-dlp smooth.
            minimumPythonVersion := "3.8.0"
            pythonVersion := outString
            If (VerCompare(pythonVersion, minimumPythonVersion) < 0)
            {
                result := MsgBox("Outdated PYTHON installation detected.`n"
                    "Found: (Python " . pythonVersion . ")`nRequired: (" . minimumPythonVersion . " or higher)"
                    "`nWould you like to update it ?",
                    "VideoDownloader Setup Status", "OC Iconi 4096")
                Switch (result)
                {
                    Case "OK":
                        {
                            /*
                            This old code is no longer required because the setp now starts with admin permissions.
                            ; Runs the uninstall console with admin rights.
                            tmpString1 := RegExReplace(pythonVersion, ".[0-9]$")
                            tmpString2 := ' /c winget uninstall "python ' . tmpString1 . '"'
                            tmpString3 := '*RunAs "' A_ComSpec . '"' . tmpString2
                            Try
                            {
                                RunWait(tmpString3)
                            }
                            Catch
                            {
                                ExitApp()
                            }
                            */
                            tmpString1 := RegExReplace(pythonVersion, ".[0-9]$")
                            tmpString2 := ' /c winget uninstall "python ' . tmpString1 . '"'
                            RunWait(A_ComSpec . tmpString2)
                            Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements',
                                , "Min", &consolePID)
                            Sleep(2000)
                            Try
                            {
                                While (WinGetTitle("ahk_pid " . consolePID) = A_ComSpec . ' - winget install "python" --accept-source-agreements --accept-package-agreements')
                                {
                                    Sleep(500)
                                }
                                Sleep(20000)
                                WinClose("ahk_pid " . consolePID)
                            }
                            Catch
                            {
                                MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
                                ExitApp()
                            }
                            Return checkPythonVersion()
                        }
                    Case "Cancel":
                        {
                            MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
                            ExitApp()
                        }
                }
            }
            Else
            {
                MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
            }
        }
    }
    ; Copies the installed python version into the setup folder for uninstall purposes.
    Try
    {
        FileCopy(A_Temp . "\video_downloader_python_install_log.txt", scriptBaseFilesLocation . "\library\setup\video_downloader_python_install_log.txt", true)
    }
    Return true
}

checkInternetConnection()
{
    ; Checks if the user has an established Internet connection.
    Try
    {
        httpRequest := ComObject("WinHttp.WinHttpRequest.5.1")
        httpRequest.Open("GET", "http://www.google.com", false)
        httpRequest.Send()

        If (httpRequest.Status = 200)
        {
            Return true
        }
    }

    Return false
}

generateHelpFile()
{
    Try
    {
        FileDelete(A_Desktop . "\VideoDownloaderSetupHelp.txt")
    }
    FileAppend(
        "Available parameters for the VideoDownloaderSetup.exe:`n`n- /run-setup`n"
        "The script will install the library files, yt-dlp and other dependencies.`n- /force-run-setup`n"
        "Same as above, but it will overwrite all existing files.`n- /run-uninstall`n"
        "Will guide the user through the uninstall process.`n`n"
        "Further help at the GitHub page: `"https://github.com/LeoTN/yt-dlp-autohotkey-gui`"",
        A_Desktop . "\VideoDownloaderSetupHelp.txt")
}

onInit_handleWorkingDirectory()
{
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "workingBaseFilesLocation", "")

    If (validatePath(regValue) = false || regValue = "")
    {
        result := MsgBox("Invalid working directory found in the registry editor.`n`n"
            "Press [Retry] to select it manually.", "Invalid Working Directory", "RC Icon!")
        Switch (result)
        {
            Case "Retry":
                {
                    tmpPath := chooseDirectory()
                    result := MsgBox("You have selected:`n[" . tmpPath . "]`nas the working directory.`n`n"
                        "Is this correct?", "Confirm Working Directory", "YN Icon?")
                    Switch (result)
                    {
                        Case "Yes":
                            {
                                Return tmpPath()
                            }
                        Case "No":
                            {
                                Return onInit_handleWorkingDirectory()
                            }
                        Default:
                            {
                                ExitApp()
                            }
                    }
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
    Return regValue
}

onInit_handleScriptDirectory()
{
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "scriptBaseFilesLocation", "")

    If (validatePath(regValue) = false || regValue = "")
    {
        result := MsgBox("Invalid script directory found in the registry editor.`n`n"
            "Press [Retry] to select it manually.", "Invalid Script Directory", "RC Icon!")
        Switch (result)
        {
            Case "Retry":
                {
                    tmpPath := chooseDirectory()
                    result := MsgBox("You have selected:`n[" . tmpPath . "]`nas the script directory.`n`n"
                        "Is this correct?", "Confirm Script Directory", "YN Icon?")
                    Switch (result)
                    {
                        Case "Yes":
                            {
                                Return tmpPath()
                            }
                        Case "No":
                            {
                                Return onInit_handleScriptDirectory()
                            }
                        Default:
                            {
                                ExitApp()
                            }
                    }
                }
            Default:
                {
                    ExitApp()
                }
        }
    }
    Return regValue
}

validatePath(pPath)
{
    path := pPath
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*'
    Loop Parse (specialChars)
    {
        If (InStr(path, A_LoopField) || InStr(path, "\\") || InStr(path, "\\\")) || !InStr(path, "\")
        {
            Return false
        }
    }
}

chooseDirectory()
{
    path := DirSelect(, , "Select the directory.")

    If (!InStr(path, "yt_dlp_autohotkey_gui_files"))
    {
        Return path . "\yt_dlp_autohotkey_gui_files"
    }
    Else
    {
        Return path
    }
}