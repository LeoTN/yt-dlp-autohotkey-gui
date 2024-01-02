#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

/*
DEBUG SECTION
-------------------------------------------------
Add debug variables here.
*/
; This variable is also written into the config file.
global booleanDebugMode := false
; Stops the annoying tooltip startup when debugging.
disableTooltipStartup := false

;------------------------------------------------

/*
CONFIG VARIABLE TEMPLATE SECTION
-------------------------------------------------
These default variables are used to generate the config file template.
***IMPORTANT NOTE***: Do NOT change the name of these variables!
Otherwise this can lead to fatal errors and failures!
*/

config_onInit()
{
    ; Determines the location of the script's configuration file.
    global configFileLocation := workingBaseFilesLocation . "\config\ytdownloader.ini"
    ; Specifies path for the .txt file which stores the URLs.
    global URL_FILE_LOCATION := workingBaseFilesLocation . "\YT_URLS.txt"
    ; Specifies path for the .txt file which stores the URL backup.
    global URL_BACKUP_FILE_LOCATION := workingBaseFilesLocation . "\YT_URLS_BACKUP.txt"
    ; Specifies path for the .txt file which stores the blacklist file.
    global BLACKLIST_FILE_LOCATION := workingBaseFilesLocation . "\YT_BLACKLIST.txt"
    ; Standard download log file path.
    global DOWNLOAD_LOG_FILE_LOCATION := workingBaseFilesLocation . "\download\download_log.txt"
    ; Default download archive file location.
    global DOWNLOAD_ARCHIVE_LOCATION := workingBaseFilesLocation . "\download\download_archive.txt"
    ; Default preset storage for the download option GUI.
    global DOWNLOAD_PRESET_LOCATION := workingBaseFilesLocation . "\presets"
    ; Standard download path.
    global DOWNLOAD_PATH := workingBaseFilesLocation . "\download"

    ; Defines if the script should ask the user for a brief explaination of it's core functions.
    global ASK_FOR_TUTORIAL := true
    ; Toggle if the main GUI should be shown on launch.
    global SHOW_MAIN_GUI_ON_LAUNCH := true
    ; Toggle if the downnload options GUI should be shown on launch.
    global SHOW_OPTIONS_GUI_ON_LAUNCH := true
    ; This option controls if empty download folders with no media inside should be automatically deleted.
    global DELETE_EMPTY_DOWNLOAD_FOLDERS_AFTER_DOWNLOAD := true
    ; Stores which hotkeys are enabled / disabled via the GUI.
    global HOTKEY_STATE_ARRAY := "[1, 1, 0, 1, 1, 1, 0]"
    ; Just a list of all standard hotkeys.
    global DOWNLOAD_HK := "+^!D"
    global URL_COLLECT_HK := "+^!S"
    global THUMBNAIL_URL_COLLECT_HK := "+^!F"
    global MAIN_GUI_HK := "+^!G"
    global TERMINATE_SCRIPT_HK := "+^!T"
    global RELOAD_SCRIPT_HK := "+^!R"
    global NOT_USED_HK := "+^!P"
    global CLEAR_URL_FILE_HK := "!F1"
    global OPTIONS_GUI_HK := "+^!A"
    ;------------------------------------------------

    ; Will contain all config values matching with each variable name in the array below.
    ; For example configVariableNameArray[2] = "URL_FILE_LOCATION"
    ; and configFileContentArray[2] = "workingBaseFilesLocation . "\YT_URLS.txt""
    ; so basically URL_FILE_LOCATION = "workingBaseFilesLocation . "\YT_URLS.txt"".
    ; NOTE: This had to be done because changing a global variable using a dynamic
    ; expression like global %myGlobalVarName% := "newValue" won't work.
    global configFileContentArray := []

    ; Create an array including all settings variables names.
    ; This array makes it easier to apply certain values from the config file to the configFileContentArray.
    ; IMPORTANT NOTE: Do NOT forget to add each new config variable name into the array !!!
    global configVariableNameArray :=
        [
            "booleanDebugMode",
            "URL_FILE_LOCATION",
            "URL_BACKUP_FILE_LOCATION",
            "BLACKLIST_FILE_LOCATION",
            "DOWNLOAD_LOG_FILE_LOCATION",
            "DOWNLOAD_ARCHIVE_LOCATION",
            "DOWNLOAD_PRESET_LOCATION",
            "DOWNLOAD_PATH",
            "ASK_FOR_TUTORIAL",
            "SHOW_MAIN_GUI_ON_LAUNCH",
            "SHOW_OPTIONS_GUI_ON_LAUNCH",
            "DELETE_EMPTY_DOWNLOAD_FOLDERS_AFTER_DOWNLOAD",
            "HOTKEY_STATE_ARRAY",
            "DOWNLOAD_HK",
            "URL_COLLECT_HK",
            "THUMBNAIL_URL_COLLECT_HK",
            "MAIN_GUI_HK",
            "OPTIONS_GUI_HK",
            "TERMINATE_SCRIPT_HK",
            "RELOAD_SCRIPT_HK",
            "NOT_USED_HK",
            "CLEAR_URL_FILE_HK"
        ]
    ; Create an array including the matching section name for EACH item in the configVariableNameArray.
    ; This makes it easier to read and write the config file.
    ; IMPORTANT NOTE: Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray !!!
    global configSectionNameArray :=
        [
            "DebugSettings",
            "FileLocations",
            "FileLocations",
            "FileLocations",
            "FileLocations",
            "FileLocations",
            "FileLocations",
            "FileLocations",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "GeneralSettings",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys",
            "Hotkeys"
        ]

    checkConfigFileIntegrity()
}

/*
CONFIG FILE SECTION
-------------------------------------------------
Creates, reads and manages the script's config file.
*/

; Creates a default config file with the standard parameters. Usually always creates
; a backup file to revert changes if needed.
createDefaultConfigFile(pBooleanCreateBackup := true, pBooleanShowPrompt := false)
{
    booleanCreateBackup := pBooleanCreateBackup
    booleanShowPrompt := pBooleanShowPrompt

    If (booleanShowPrompt = true)
    {
        result := MsgBox("Do you really want to replace the current`nconfig file with a new one ?", "Warning !", "YN Icon! T10")
        If (result = "No" || result = "Timeout")
        {
            Return
        }
    }
    If (booleanCreateBackup = true)
    {
        If (!DirExist(SplitPath(configFileLocation, , &outDir)))
        {
            DirCreate(outDir)
        }
        If (FileExist(configFileLocation))
        {
            FileMove(configFileLocation, configFileLocation . "_old", true)
        }
    }
    FileAppend("#Important note: When changing the config file the script has to be reloaded for the changes to take effect!",
        configFileLocation)
    ; In case you forget to specify a section for EACH new config file entry this will remind you to do so :D
    If (configVariableNameArray.Length != configSectionNameArray.Length)
    {
        MsgBox("Not every config file entry has been asigned to a section !`n`nPlease fix this by checking both arrays.",
            "Error !", "O IconX")
        MsgBox("Script terminated.", "Script Status", "O IconX T1.5")
        ExitApp()
    }
    Else
    {
        /*
        This it what it looked like before using an array to define all parameters.
        IniWrite(URL_FILE_LOCATION, configFileLocation, "FileLocations", "URL_FILE_LOCATION")
        */
        Loop configVariableNameArray.Length
        {
            IniWrite(%configVariableNameArray.Get(A_Index)%, configFileLocation, configSectionNameArray.Get(A_Index),
                configVariableNameArray.Get(A_Index))
        }
        If (booleanShowPrompt = true)
        {
            MsgBox("A default config file has been generated.", "Config File Status", "O Iconi T3")
        }
    }
}

; Reads the config file and extracts it's values.
; The parameter optionName specifies a specific
; variable's content which you want to return.
; For example '"URL_FILE_LOCATION"' to return URL_FILE_LOCATION's content
; which is 'workingBaseFilesLocation . "\YT_URLS.txt"' by default.
; Returns the value out of the config file.
; The booleanAskForPathCreation should be used with caution because
; it can have unforeseen consequences if a directory is not created.
readConfigFile(pOptionName, pBooleanAskForPathCreation := true, pBooleanCheckConfigFileStatus := true)
{
    ; Thanks to my buddy Elias for testing and helping me debugging this script :)
    optionName := pOptionName
    booleanAskForPathCreation := pBooleanAskForPathCreation
    booleanCheckConfigFileStatus := pBooleanCheckConfigFileStatus

    global configVariableNameArray
    global configFileContentArray
    global booleanFirstTimeLaunch

    If (booleanCheckConfigFileStatus = true)
    {
        checkConfigFileIntegrity()
    }

    Loop (configVariableNameArray.Length)
    {
        ; Searches in the config file for the given option name to then extract the value.
        If (InStr(configVariableNameArray.Get(A_Index), optionName, 0))
        {
            ; The following code only applies for path values.
            ; Everything else should be excluded.
            If (InStr(configFileContentArray.Get(A_Index), "\"))
            {
                booleanCreatePathSilent := false
                If (booleanFirstTimeLaunch)
                {
                    booleanAskForPathCreation := false
                    booleanCreatePathSilent := true
                }
                If (!validatePath(configFileContentArray.Get(A_Index), booleanAskForPathCreation, booleanCreatePathSilent))
                {
                    MsgBox("Could not create directory !`nCheck the config file for a valid path at`n["
                        . configVariableNameArray.Get(A_Index) . "]", "Error !", "O Icon! T10")
                    MsgBox("Script terminated.", "Script Status", "O IconX T1.5")
                    ExitApp()
                }
                Else
                {
                    ; This means that there was no error with the path given.
                    Return configFileContentArray.Get(A_Index)
                }
            }
            Else
            {
                Return configFileContentArray.Get(A_Index)
            }
        }
    }
    MsgBox("Could not find " . optionName . " in the config file.`nScript terminated.", "Config File Status", "O IconX T3")
    ExitApp()
}

; The parameter optionName specifies a specific
; variable's content which you want to edit.
; The parameter data holds the new data for the config file.
editConfigFile(pOptionName, pData)
{
    optionName := pOptionName
    data := pData
    ; Basically the same as creating the config file.
    Loop (configVariableNameArray.Length)
    {
        ; Searches in the config file for the given option name to then change the value.
        If (InStr(configVariableNameArray.Get(A_Index), optionName, 0))
        {
            Try
            {
                ; Check just in case the given data is an array.
                If (data.Has(1) = true)
                {
                    dataString := arrayToString(data)
                    IniWrite(dataString, configFileLocation
                        , configSectionNameArray.Get(A_Index)
                        , configVariableNameArray.Get(A_Index))
                    Return
                }
                Else
                {
                    IniWrite(data, configFileLocation
                        , configSectionNameArray.Get(A_Index)
                        , configVariableNameArray.Get(A_Index))
                    Return
                }
            }
            Catch
            {
                ; If the try statement fails the object above cannot be an array.
                IniWrite(data, configFileLocation
                    , configSectionNameArray.Get(A_Index)
                    , configVariableNameArray.Get(A_Index))
                Return
            }
        }
    }
    Throw ("Error while editing config file")
}

checkConfigFileIntegrity()
{
    Loop (configVariableNameArray.Length)
    {
        Try
        {
            ; Replaces every slot in the configFileContentArray with the value from the config file's content.
            configFileContentArray.InsertAt(A_Index, IniRead(configFileLocation, configSectionNameArray.Get(A_Index)
                , configVariableNameArray.Get(A_Index)))
        }
        Catch
        {
            ; Does not show a prompt when the script is launched for the very first time.
            If (booleanFirstTimeLaunch = true)
            {
                createDefaultConfigFile()
                Return true
            }
            result := MsgBox("The script config file seems to be corrupted or unavailable!"
                "`n`nDo you want to create a new one using the template?"
                , "Warning !", "YN Icon! 8192 T10")
            Switch (result)
            {
                Case "Yes":
                    {
                        createDefaultConfigFile()
                        Return true
                    }
                Default:
                    {
                        MsgBox("Script terminated.", "Script Status", "O IconX T1.5")
                        ExitApp()
                    }
            }
        }
    }
}

; Verfies the integrity of a given path or file location.
; It will also ask the user to create the given path if it does not exist yet.
; Returns true if a path is valid and false otherwise.
validatePath(pPath, pBooleanAskForPathCreation := true, pBooleanCreatePathSilent := false)
{
    path := pPath
    booleanAskForPathCreation := pBooleanAskForPathCreation
    booleanCreatePathSilent := pBooleanCreatePathSilent

    If (booleanAskForPathCreation && booleanCreatePathSilent)
    {
        MsgBox("[" . A_ThisFunc "()] [ERROR] booleanAskForPathCreation and booleanCreatePathSilent cannot be true at the "
            . "same time.`nTerminating script.", "[" . A_ThisFunc "()]", "IconX")
        ExitApp()
    }

    ; SplitPath makes sure the last part of the whole path is removed.
    ; For example it removes the "\YT_URLS.txt"
    SplitPath(path, &outFileName, &outDir, &outExtension, , &outDrive)
    ; Replaces the drive name with empty space, because the "C:" would trigger the parse loop below mistakenly.
    pathWithoutDrive := StrReplace(path, outDrive)
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*:'
    Loop Parse (specialChars)
    {
        If (InStr(pathWithoutDrive, A_LoopField))
        {
            Return false
        }
    }
    ; Checks if the path contains two or more or no "\".
    If (RegExMatch(path, "\\{2,}") || !InStr(path, "\"))
    {
        Return false
    }

    ; This means the path has no file at the end.
    If (outExtension = "")
    {
        If (!DirExist(path))
        {
            If (booleanAskForPathCreation)
            {
                result := MsgBox("The directory`n[" . path . "]`ndoes not exist."
                    "`nWould you like to create it ?", "Warning !", "YN Icon! T10")
                Switch (result)
                {
                    Case "Yes":
                        {
                            DirCreate(path)
                        }
                    Default:
                        {
                            MsgBox("Script terminated.", "Script Status", "O IconX T1.5")
                            ExitApp()
                        }
                }
            }
            Else If (booleanCreatePathSilent)
            {
                DirCreate(path)
            }
        }
    }
    ; This means the path has a file at the end, which has to be excluded.
    Else
    {
        If (!DirExist(outDir))
        {
            If (booleanAskForPathCreation)
            {
                result := MsgBox("The directory`n[" . outDir . "]`ndoes not exist."
                    "`nWould you like to create it ?", "Warning !", "YN Icon! T10")
                Switch (result)
                {
                    Case "Yes":
                        {
                            DirCreate(outDir)
                        }
                    Default:
                        {
                            MsgBox("Script terminated.", "Script Status", "O IconX T1.5")
                            ExitApp()
                        }
                }
            }
            Else If (booleanCreatePathSilent)
            {
                DirCreate(outDir)
            }
        }
    }
    Return true
}