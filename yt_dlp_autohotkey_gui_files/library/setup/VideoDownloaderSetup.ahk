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
        createInstallGUI()
        installGUI.Show()
        checkAvailableSetupComponents()
        Sleep(500)
        handleInstallGUI_availableComponents()
    }
    Else If (booleanParameterForceSetup)
    {
        createInstallGUI()
        ; Scans for already existing software.
        checkAvailableSetupComponents()
        force_run_setup()
    }
    Else If (booleanParameterUninstall)
    {
        run_uninstall()
    }
}

; Tries to find a program by searching all directories in PATH and other Windows locations.
; When the program has been found the path will be returned. Otherwise it will return an empty string.
findProgramPath(pProgramName, pPath := "")
{
    programName := pProgramName
    path := pPath

    If (path = "")
    {
        cmd := ComObject("WScript.Shell")
        executeResult := cmd.Exec(A_ComSpec ' /C where "' . programName . '"')
    }
    Else
    {
        cmd := ComObject("WScript.Shell")
        executeResult := cmd.Exec(A_ComSpec ' /C where /R "' . path . '" "' . programName . '"')
    }
    ; This weird piece of code makes sure that only one result is delivered as a path.
    Try
    {
        FileDelete(A_Temp . "\tmp.txt")
    }
    FileAppend(executeResult.StdOut.ReadAll(), A_Temp . "\tmp.txt")
    Loop Read (A_Temp . "\tmp.txt")
    {
        Return A_LoopReadLine
    }
}

createInstallGUI()
{
    Global
    installGUI := Gui(, "Install VideoDownloader")
    installText := installGUI.Add("Text", "xp+10 yp+10 ", "Install VideoDownloader and its dependencies."
        . "`nThe ticked checkboxes are components that are already present on your system.")
    reinstallEverythingCheckbox := installGUI.Add("Checkbox", "yp+35", "Reinstall everything")
    installPythonCheckbox := installGUI.Add("Checkbox", "yp+25 Disabled", "Python installed")
    installYTDLPCheckbox := installGUI.Add("Checkbox", "yp+25 Disabled", "yt-dlp installed")
    installFFmpegCheckbox := installGUI.Add("Checkbox", "yp+25 Disabled", "FFmpeg installed")

    installShowFFmpegPathButton := installGUI.Add("Button", "xp+122 Disabled", "Show path")
    installChangeFFmpegPathButton := installGUI.Add("Button", "xp+72", "Change path")
    installScanAgainButton := installGUI.Add("Button", "xp+87", "Scan again")

    installStartButton := installGUI.Add("Button", "xp-289 yp+35 w80 Default", "Install")
    installCancelButton := installGUI.Add("Button", "xp+85 w80", "Cancel")
    installOpenGitHubIssuesButton := installGUI.Add("Button", "xp+85", "Open GitHub issues")
    installProgressBar := installGUI.Add("Progress", "xp+119 yp+3 Range0-400")
    installStatusBar := installGUI.Add("StatusBar", , "Installation not running...")

    installShowFFmpegPathButton.OnEvent("Click", (*) => handleInstallGUI_showFFmpegPathButton())
    installChangeFFmpegPathButton.OnEvent("Click", (*) => handleInstallGUI_checkFFmpegLocation(DirSelect(, false, "Please select the FFmpeg folder.")))
    installScanAgainButton.OnEvent("Click", (*) => handleInstallGUI_availableComponents())
    installStartButton.OnEvent("Click", (*) => run_setup(reinstallEverythingCheckbox.Value))
    installCancelButton.OnEvent("Click", (*) => handleInstallGUI_cancelInstallationButton())
    installOpenGitHubIssuesButton.OnEvent("Click", (*) => Run("https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues"))
}

handleInstallGUI_showFFmpegPathButton()
{
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation", "")
    If (FileExist(regValue))
    {
        SplitPath(regValue, , &outDir)
        Run(outDir)
    }
}

handleInstallGUI_cancelInstallationButton()
{
    result := MsgBox("Do you really want to cancel the installation process?", "Cancel VideoDownloader Installation", "YN Icon!")
    If (result = "Yes")
    {
        Try
        {
            WinClose('install "python"')
        }
        Try
        {
            WinClose("https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz")
        }
        Try
        {
            WinClose("FFmpeg download running...")
        }
        installGUI.Hide()
        ExitApp()
    }
}

handleInstallGUI_checkFFmpegLocation(pPath)
{
    path := pPath

    If (path = "")
    {
        MsgBox("Invalid folder selection.", "Error", "O IconX T1.5")
        Return
    }
    RegWrite(path, "REG_SZ",
        "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation")
    handleInstallGUI_availableComponents()
}

handleInstallGUI_availableComponents()
{
    checkAvailableSetupComponents()

    If (booleanPythonFound = true)
    {
        installPythonCheckbox.Value := true
    }
    Else
    {
        installPythonCheckbox.Value := false
    }
    If (booleanYTDLPFound = true)
    {
        installYTDLPCheckbox.Value := true
    }
    Else
    {
        installYTDLPCheckbox.Value := false
    }
    If (booleanFFmpegFound = true)
    {
        installFFmpegCheckbox.Value := true
        installShowFFmpegPathButton.Opt("-Disabled")
    }
    Else
    {
        installFFmpegCheckbox.Value := false
        installShowFFmpegPathButton.Opt("+Disabled")
    }
}

; Tries to find existing software for example if yt-dlp is already present so that this part is skipped during the setup.
checkAvailableSetupComponents()
{
    global booleanPythonFound := true
    global booleanYTDLPFound := true
    global booleanFFmpegFound := true
    ; Scan for Python.
    RunWait(A_ComSpec ' /c python --version >> "' . A_Temp . '\video_downloader_python_install_log.txt"', , "Hide")
    If (FileExist(A_Temp . "\video_downloader_python_install_log.txt"))
    {
        ; This occures when the command does not achieve anything => Python is not installed.
        If (FileRead(A_Temp . "\video_downloader_python_install_log.txt") = "")
        {
            booleanPythonFound := false
        }
    }
    Else
    {
        booleanPythonFound := false
    }

    ; Scan for yt-dlp.
    RunWait(A_ComSpec ' /c yt-dlp --version >> "' . A_Temp . '\tmp.txt"', , "Hide")
    If (FileExist(A_Temp . "\tmp.txt"))
    {
        ; This means that the command could not be found and yt-dlp is not installed.
        If (FileRead(A_Temp . "\tmp.txt") = "")
        {
            booleanYTDLPFound := false
        }
    }
    Else
    {
        booleanYTDLPFound := false
    }

    ; Tries to find an existing registry entry for the path to FFmpeg.
    regValue := RegRead("HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation", "")
    If (regValue = "")
    {
        ; Scan for FFmpeg.
        tmp := findProgramPath("ffmpeg.exe")
        ; This means a path could be found.
        If (tmp != "")
        {
            RegWrite(tmp, "REG_SZ",
                "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation")
        }
        Else
        {
            booleanFFmpegFound := false
        }
    }
    Else
    {
        ; This removes the ffmpeg.exe from the path to ensure the command will find the executable.
        SplitPath(regValue, &outFileName, &outDir)
        If (InStr(outFileName, "ffmpeg.exe"))
        {
            regValue := outDir
        }
        ; Scan for FFmpeg using the existing path form the registry.
        tmp := findProgramPath("ffmpeg.exe", regValue)
        If (tmp != "")
        {
            RegWrite(tmp, "REG_SZ",
                "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "ffmpegLocation")
        }
        Else
        {
            booleanFFmpegFound := false
        }
    }
}

createUninstallGUI()
{
    Global
    uninstallGUI := Gui(, "Uninstall VideoDownloader")
    uninstallUntilNextTimeText := uninstallGUI.Add("Text", "xp+10 yp+10 ", "Please select your uninstall options below.")
    uninstallEverythingCheckbox := uninstallGUI.Add("Checkbox", "yp+20 Checked", "Remove everything")
    uninstallPythonCheckbox := uninstallGUI.Add("Checkbox", "yp+20 ", "Uninstall Python")
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
    If (uninstallEverythingCheckbox.Value = true)
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

; Normal setup which installs Python and yt-dlp and FFmpeg..
run_setup(pBooleanForceInstall := false)
{
    booleanForceInstall := pBooleanForceInstall

    global booleanPythonFound
    global booleanYTDLPFound
    global booleanFFmpegFound
    global window_1 := ""
    global window_2 := ""
    global window_3 := ""
    global window_4 := ""

    installStatusBar.Text := "Launching setup..."
    ; Beginning of the setup.
    result := MsgBox("The next steps require an established Internet connection.`n`nPress Okay to continue.",
        "VideoDownloader Setup Status", "OC Iconi 4096")
    Switch (result)
    {
        Case "Cancel":
            {
                ExitApp()
            }
    }
    If (checkInternetConnection() = true)
    {
        installStartButton.Opt("+Disabled")
        MsgBox("You can use the computer during the setup. It is recommended to avoid restarting during the installation process."
            . " Make sure to keep all appearing windows open until they close by themselves.", "VideoDownloader Setup Status", "O Iconi")
        ; The setup begins with the FFmpeg files because they take the most time to download.
        If (booleanFFmpegFound = false || booleanForceInstall = true)
        {
            installFFmpeg(booleanForceInstall)
            Sleep(2000)
        }
        If (booleanPythonFound = false || booleanForceInstall = true)
        {
            installPython(booleanForceInstall)
            Sleep(2000)
        }
        If (booleanYTDLPFound = false || booleanForceInstall = true)
        {
            installYTDLP(booleanForceInstall)
            Sleep(2000)
        }
        ; Wait for all installation windows to close.
        WinWaitClose("ahk_pid " . window_1)
        installProgressBar.Value += 100
        WinWaitClose("ahk_pid " . window_2)
        installProgressBar.Value += 100
        WinWaitClose("ahk_pid " . window_3)
        installProgressBar.Value += 100
        WinWaitClose("ahk_pid " . window_4)
        installProgressBar.Value += 100

        installStatusBar.Text := "Testing components..."
        Sleep(2000)
        checkAvailableSetupComponents()
        Sleep(2000)
        checkAvailableSetupComponents()
        If (booleanPythonFound = false || booleanYTDLPFound = false || booleanFFmpegFound = false)
        {
            result := MsgBox("Not every component is functional and / or available !`n`n"
                "Please click Okay to run the advanced installation process.", "VideoDownloader Setup Status", "OC Icon!")
            Switch (result)
            {
                Case "OK":
                    {
                        Run '*RunAs "' A_ScriptFullPath '" /restart /force-run-setup'
                        ExitApp()
                    }
                Default:
                    {
                        MsgBox("Could not complete setup (component malfunction).`n`nTerminating script.", "Error !", "O IconX T1.5")
                        ExitApp()
                    }
            }
        }
        installStatusBar.Text := "Finishing setup..."
        ; Disables the forced setup and tells the main script to create any necessary files without prompt.
        RegWrite(1, "REG_DWORD",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanFirstTimeLaunch")
        RegWrite(0, "REG_DWORD",
            "HKEY_CURRENT_USER\SOFTWARE\LeoTN\VideoDownloader", "booleanSetupRequired")
        Sleep(2000)
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
    ; Force overwrite existing files.
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
    If (tmp1 = true)
    {
        uninstallStatusBar.SetText("Currently uninstalling yt-dlp...")
        RunWait(A_ComSpec ' /c python -m pip uninstall -y "yt-dlp"')
        uninstallProgressBar.Value += 100
    }
    If (tmp2 = true)
    {
        If (FileExist(scriptBaseFilesLocation . "\library\setup\video_downloader_python_install_log.txt"))
        {
            uninstallStatusBar.SetText("Currently uninstalling Python...")
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
            RunWait(A_ComSpec ' /c winget uninstall "Python" --version "latest"')
            If (!WinExist("ahk_id " . uninstallGUI.Hwnd))
            {
                Hotkey_openUninstallGUI()
            }
            Else
            {
                WinActivate("ahk_id " . uninstallGUI.Hwnd)
            }
            uninstallStatusBar.SetText("Warning ! Tried to remove Python alternatively !")
            Sleep(2000)
            uninstallStatusBar.SetText("You might have to uninstall it manually.")
            Sleep(2000)
            uninstallProgressBar.Value += 100
        }
    }
    If (tmp3 = true)
    {
        If (DirExist(workingBaseFilesLocation . "\download"))
        {
            uninstallStatusBar.SetText("Deleting downloaded files...")
            Try
            {
                FileRecycle(workingBaseFilesLocation . "\download")
            }
            Catch
            {
                uninstallStatusBar.SetText("Warning ! Could not delete downloaded files !")
                Sleep(2000)
                uninstallStatusBar.SetText("You have to delete them manually.")
                Sleep(2000)
            }
        }
        Else
        {
            uninstallStatusBar.SetText("No download directory found. !")
            Sleep(2000)
        }
        uninstallProgressBar.Value += 100
    }
    If (tmp4 = true)
    {
        evacuationError := false
        uninstallStatusBar.SetText("Deleting script files...")
        ; This means that the remaining download files have to be saved.
        If (tmp3 = false)
        {
            If (DirExist(workingBaseFilesLocation . "\download"))
            {
                Try
                {
                    uninstallStatusBar.SetText("Moving downloaded files to desktop...")
                    DirMove(workingBaseFilesLocation . "\download", A_Desktop . "\yt_dlp_autohotkey_gui_downloads_after_uninstall", 1)
                }
                Catch
                {
                    evacuationError := true
                    uninstallStatusBar.SetText("Warning ! Could not save downloaded files !")
                    Sleep(2000)
                }
            }
            Try
            {
                ; Views every folder and subfolder to delete the files.
                Loop Files workingBaseFilesLocation . "\*", "RDF"
                {
                    If (A_LoopFileName != A_ScriptName)
                    {
                        If (evacuationError = true)
                        {
                            ; This makes sure that the loop avoids any file or folder in the download folder.
                            If (InStr(A_LoopFileFullPath, workingBaseFilesLocation . "\download"))
                            {
                                Continue
                            }
                        }
                        Try
                        {
                            FileRecycle(A_LoopFileFullPath)
                        }
                    }

                }
            }
            uninstallProgressBar.Value += 100
        }
        Else
        {
            Try
            {
                FileRecycle(workingBaseFilesLocation)
            }
            Catch
            {
                uninstallStatusBar.SetText("Warning ! Could not delete script files !")
                Sleep(2000)
            }
        }
        uninstallProgressBar.Value += 100
    }
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

installPython(pBooleanForceInstall)
{
    booleanForceInstall := pBooleanForceInstall
    global window_1

    installStatusBar.Text := "Installing Python..."
    If (booleanForceInstall = false)
    {
        RunWait(A_ComSpec ' /c python --version >> "' . A_Temp . '\video_downloader_python_install_log.txt"')
        Sleep(500)
        ; This occures when the command finds anything (e.g. Python version) => python is installed.
        If (FileRead(A_Temp . "\video_downloader_python_install_log.txt") != "")
        {
            Return false
        }
    }

    Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements --force --source "msstore"',
        , "Min", &consolePID)
    Sleep(1500)
    Try
    {
        While (InStr(WinGetTitle("ahk_pid " . consolePID), 'install "python"'))
        {
            Sleep(1000)
        }
        window_1 := consolePID
        WinClose("ahk_pid " . consolePID)
        MsgBox("Please wait for Python to be installed completly. The script installation is still running"
            . " in the background and will continue in a few seconds.", "VideoDownloader Setup Status", "O Iconi T5")
        Sleep(15000)
        Return installPython(false)
    }
    Catch
    {
        MsgBox("Could not complete setup (Python installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
        ExitApp()
    }
    ; Copies the installed Python version into the setup folder for uninstall purposes.
    If (FileExist(A_Temp . "\video_downloader_python_install_log.txt"))
    {
        FileCopy(A_Temp . "\video_downloader_python_install_log.txt",
            scriptBaseFilesLocation . "\library\setup\video_downloader_python_install_log.txt", true)
    }
    Return true
}

installYTDLP(pBooleanForceInstall)
{
    booleanForceInstall := pBooleanForceInstall
    global window_2
    global window_3

    installStatusBar.Text := "Installing yt-dlp..."
    If (booleanForceInstall = true)
    {
        ; Will install the latest version of yt-dlp from GitHub.
        Run(A_ComSpec ' /c python -m pip install --force-reinstall "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"',
            , "Min", &consolePID)
    }
    Else
    {
        Run(A_ComSpec ' /c python -m pip install "https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz"',
            , "Min", &consolePID)
    }

    WinWait("ahk_pid " . consolePID)
    window_2 := consolePID
    WinWaitClose("ahk_pid " . consolePID)
    ; Adds yt-dlp executable to system environment variable PATH.
    If (FileExist(A_WorkingDir . "\AddYTDLPToPath.ps1"))
    {
        RunWait('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\AddYTDLPToPath.ps1"', , "Min", &consolePID)
        window_3 := consolePID
    }
    Else
    {
        MsgBox("Could not add yt-dlp to system environment variables.`n`nTerminating script.", "Error !", "O IconX T1.5")
        ExitApp()
    }
    Return true
}

installFFmpeg(pBooleanForceInstall)
{
    booleanForceInstall := pBooleanForceInstall
    global window_4

    installStatusBar.Text := "Installing FFmpeg library..."
    If (FileExist(A_WorkingDir . "\FFmpegDownloader.ps1"))
    {
        If (booleanForceInstall = false)
        {
            Run('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\FFmpegDownloader.ps1" -pSetupType "/run-setup"'
                , , "Min", &consolePID)
        }
        Else If (booleanForceInstall = true)
        {
            Run('powershell.exe -executionPolicy bypass -file "' . A_WorkingDir . '\FFmpegDownloader.ps1" -pSetupType "/force-run-setup"'
                , , "Min", &consolePID)
        }
        window_4 := consolePID
    }
    Else
    {
        MsgBox("Could complete setup (FFmpeg installation).`n`nTerminating script.", "Error !", "O IconX T1.5")
        ExitApp()
    }
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