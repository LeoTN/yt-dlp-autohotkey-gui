; NOTE : This is the main .ahk file which has to be started !!!
#SingleInstance Force
SendMode "Input"
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Client"
#MaxThreadsPerHotkey 1
#Warn Unreachable, Off

; Imports important functions and variables
; Sets the directory for all following files.
#Include "includes\"
#Include "ConfigFileManager.ahk"
#Include "HotKeys & Methods.ahk"
#Include "FileManager.ahk"
#Include "GUI.ahk"
#Include "DownloadOptionsGUI.ahk"
onInit()

/*
DEBUG SECTION
-------------------------------------------------
Add debug hotkeys here.
*/

; Debug hotkey template.
F6::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below.
        A_Clipboard := buildCommandString()
    }
    Return
}

F7::
{
    If (readConfigFile("booleanDebugMode") = true)
    {
        ; Enter code below
        A_Clipboard := A_ComSpec ' /k ' . buildCommandString() . '> "' . readConfigFile("DOWNLOAD_LOG_FILE_LOCATION") . '"'
    }
    Return
}

; Runs a list of commands when the script is launched.
onInit()
{
    global ffmpegLocation := A_WorkingDir . "\files\library\ffmpeg.exe"
    global youTubeBackGroundLocation := A_WorkingDir . "\files\library\YouTubeBackground.jpg"

    If (!FileExist(ffmpegLocation))
    {
        result := MsgBox("No library files detected.`n`nWould you like to run a complete setup?",
            "youtube-dlp-autohotkey-gui setup", "OC Icon? 4096")
        Switch (result)
        {
            Case "OK":
                {
                    setUp()
                }
            Case "Cancel":
                {
                    ExitApp()
                }
        }
    }
    ; To maintain ordinary functionallity the system MUST be restarted after a finished installation of this script!
    If (FileExist(A_WorkingDir . "\NotRestartedYet(do not delete!!!).txt"))
    {
        result := MsgBox("Your system has not been REBOOTED yet.`nFor further use it is mandatory`n to REBOOT your system.",
            "Script setup status", "OC Icon! 262144")
        Switch (result)
        {
            Case "OK":
                {
                    Try
                    {
                        FileDelete(A_WorkingDir . "\NotRestartedYet(do not delete!!!).txt")
                    }
                    If (!FileExist(A_WorkingDir . "\NotRestartedYet(do not delete!!!).txt"))
                    {
                        Run(A_ComSpec . " /c shutdown /r /t 1")
                        ExitApp()
                    }
                    Else
                    {
                        Throw ("Could not find REBOOT file.")
                    }
                }
            Default:
                {
                    FileAppend("Do not delete this file if you do not know what you are doing!", A_WorkingDir . "\NotRestartedYet(do not delete!!!).txt")
                }
        }
        MsgBox("Terminating script.", "Script status", "O Iconi T1.5")
        ExitApp()
    }
    ; Only called to check the config file status.
    readConfigFile("booleanDebugMode")
    checkBlackListFile("createBlackListFile")
    Hotkey_onInit()
    mainGUI_onInit()
    optionsGUI_onInit()
}

; Guides the user through a bunch of prompts and helps to install the script.
setUp()
{
    ; Makes sure the setup will be executed with admin permissions.
    fullCommandLine := DllCall("GetCommandLine", "str")
    If not (A_IsAdmin || RegExMatch(fullCommandLine, " /restart(?!\S)"))
    {
        result := MsgBox("The script has not been started with `nadministrative permissions.`n`n"
            "A restart is required.", "Warning", "OC Icon! 4096")
        Switch (result)
        {
            Case "OK":
                {
                    Try
                    {
                        If (A_IsCompiled = true)
                        {
                            Run '*RunAs "' A_ScriptFullPath '" /restart'
                        }
                        Else
                        {
                            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
                        }
                    }
                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
            Case "Cancel":
                {
                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
        }
    }
    ; Beginning of the setup.
    result := MsgBox("The next steps require an established Internet connection.`n`nPress Okay to continue.",
        "Script setup status", "OC Iconi 4096")
    Switch (result)
    {
        Case "Cancel":
            {
                MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
            }
    }
    If (setup_checkInternetConnection() = true)
    {
        If (setup_checkPythonVersion() = true)
        {
            Try
            {
                FileDelete(A_Temp . "\video_downloader_install_log.txt")
            }
            ; Will install the latest version of yt-dlp from GitHub.
            ; This was the old way but it would not receive that many updates.
            ; Run(A_ComSpec " /k pip install yt-dlp", , , &consolePID)
            Run(A_ComSpec " /k python -m pip install --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz",
                , , &consolePID)
            Sleep(1500)
            Try
            {
                While (WinGetTitle("ahk_pid " . consolePID) = A_ComSpec . " - python  -m pip install --force-reinstall https://github.com/yt-dlp/yt-dlp/archive/master.tar.gz")
                {
                    Sleep(500)
                }
                Sleep(1500)
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
            ; In case the executable file has not been added to the eviromental variable "PATH".
            Loop Read (A_Temp . "\video_downloader_install_log.txt")
            {
                Loop Parse (A_LoopReadLine)
                {
                    ; Scanns the output from the console and searches for the PATH error.
                    If (RegExMatch(A_LoopReadLine, "'(.+?)' which is not on PATH", &outMatch) != 0)
                    {
                        outString := outMatch[]
                        ; Removes "'" at the beginning and at the end.
                        ; It also deletes " which is not on PATH".
                        outStringReady := StrReplace(StrReplace(outString, " which is not on PATH"), "'")
                        ; Admin rights required.
                        ; Writes the environment variable into the system (not to the local user).
                        RunWait(A_ComSpec ' /c setx Path "%Path%;' . outStringReady . '" /M')
                        RunWait(A_ComSpec ' /c setx Path "%Path%;' . outStringReady . '" /M')
                        RunWait(A_ComSpec ' /c setx Path "%Path%;' . outStringReady . '" /M')
                        MsgBox("Tried to install YT-DLP into PATH.`n`nA potential trouble shooting file`n"
                            "has been generated on your desktop.", "Script setup status", "O Iconi 4096")
                        setup_generatePathHelpFile(outStringReady)
                        ; For Elias :D
                        Break 2
                    }
                }
            }
            If (setup_installLibraryFiles() = true)
            {
                createDefaultConfigFile()
                ; Creates a blacklist file without showing a prompt to the user.
                checkBlackListFile("createBlackListFile", false)

                result := MsgBox("To finish the installation it is`nnecessary`n to REBOOT your system.",
                    "Script setup status", "OC Icon! 262144")
                Switch (result)
                {
                    Case "OK":
                        {
                            Run(A_ComSpec . " /c shutdown /r /t 1")
                            ExitApp()
                        }
                    Default:
                        {
                            FileAppend("Do not delete this file if you do not know what you are doing!", A_WorkingDir . "\NotRestartedYet(do not delete!!!).txt")
                        }
                }
                MsgBox("Terminating script.", "Script status", "O Iconi T1.5")
                ExitApp()
            }
            Else
            {
                MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                ExitApp()
            }
        }
        Else
        {
            MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
            ExitApp()
        }
    }
    Else
    {
        MsgBox("Unable to connect to the Internet.`n`nPlease check your Internet connection.", "Error", "O IconX 4096")
        ExitApp()
    }
}

setup_checkInternetConnection()
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

setup_generatePathHelpFile(pOutStringReady)
{
    outStringReady := pOutStringReady
    Try
    {
        FileDelete(A_Desktop . "\VIDEO_DOWNLOADER_IMPORTANT.txt")
    }
    FileAppend(
        "If the command `"yt-dlp`" typed into the `ncommand prompt refuses to work,`n"
        "a system restart is recommended.`n`nIn case that did not help try to manually add the`n"
        "directory to the environmental variable PATH.`n`nThis manual is for Windows 10 only.`n"
        "1. Open your windows search bar`n2. Type `"systemvar`"`n"
        "3. An option called something like `"Edit environment variables`" should appear. Click on it.`n"
        "4. Look for the button `"Environmental variables`" on the bottom right of the opened window.`n"
        "5. Navigate under the system variables to an option called `"Path`"`n"
        "6. Double click on it and press the `"New`" button.`n7. Paste the following path into the input field : "
        . outStringReady . "`n8. Close all related windows and restart your computer.`n"
        "9. If that didnt work please report this isse at my GitHub page : `"https://github.com/LeoTN/yt-dlp-autohotkey-gui`"",
        A_Desktop . "\VIDEO_DOWNLOADER_IMPORTANT.txt")
}

setup_installLibraryFiles()
{
    If (!DirExist(A_WorkingDir . "\files\library"))
    {
        Try
        {
            DirCreate(A_WorkingDir . "\files\library")
        }
    }
    Try
    {
        FileInstall("files\library\YouTubeBackground.jpg", youTubeBackGroundLocation, 1)
        ; Required for yt-dlp to operate with extra functionallity.
        FileInstall("files\library\ffmpeg.exe", ffmpegLocation, 1)
        FileInstall("files\library\ffplay.exe", A_WorkingDir . "\files\library\ffplay.exe", 1)
        FileInstall("files\library\ffprobe.exe", A_WorkingDir . "\files\library\ffprobe.exe", 1)
    }
    Catch
    {
        MsgBox("Could not install library files.`n`nTerminating script.", "Error", "O IconX T1.5")
        ExitApp()
    }
    MsgBox("Successfully installed library contents.", "Script setup status", "O Iconi T2")
    Return true
}

setup_checkPythonVersion()
{
    Try
    {
        FileDelete(A_Temp . "\video_downloader_python_install_log.txt")
    }
    RunWait(A_ComSpec " /c python --version > " . A_Temp . "\video_downloader_python_install_log.txt")
    Sleep(500)
    ; This occures when the command does not achieve anything => python is not installed.
    If (FileRead(A_Temp . "\video_downloader_python_install_log.txt") = "")
    {
        result := MsgBox("No valid PYTHON installation found.`n`nWould you like to install PYTHON now?",
            "Script setup status", "OC Iconi 4096")
        Switch (result)
        {
            Case "OK":
                {
                    Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements',
                        , , &consolePID)
                    Sleep(1500)
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
                        MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                        ExitApp()
                    }
                    Return setup_checkPythonVersion()
                }
            Case "Cancel":
                {
                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                    ExitApp()
                }
        }
    }
    Loop Read (A_Temp . "\video_downloader_python_install_log.txt")
    {
        Loop Parse (A_LoopReadLine)
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
                        "Found : (Python " . pythonVersion . ")`nRequired : (" . minimumPythonVersion . " or higher)"
                        "`nWould you like to update it?",
                        "Script setup status", "OC Iconi 4096")
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
                                Run(A_ComSpec ' /k winget install "python" --accept-source-agreements --accept-package-agreements || title Completed...',
                                    , , &consolePID)
                                Sleep(2000)
                                Try
                                {
                                    while (WinGetTitle("ahk_pid " . consolePID) = A_ComSpec . ' - winget install "python" --accept-source-agreements --accept-package-agreements')
                                    {
                                        Sleep(500)
                                    }
                                    Sleep(20000)
                                    WinClose("ahk_pid " . consolePID)
                                }
                                Catch
                                {
                                    MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                                    ExitApp()
                                }
                                Return setup_checkPythonVersion()
                            }
                        Case "Cancel":
                            {
                                MsgBox("Could not complete setup.`n`nTerminating script.", "Error !", "O IconX T1.5")
                                ExitApp()
                            }
                    }
                }
                Else If (pythonVersion != "")
                {
                    Return true
                }
                Else
                {
                    Return false
                }
            }
        }
    }
    Return
}