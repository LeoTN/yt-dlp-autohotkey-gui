#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Client"

/*
DEBUG SECTION
-------------------------------------------------
Add debug variables here.
*/
; This variable is also written into the config file.
global booleanDebugMode := false

;------------------------------------------------

/*
CONFIG VARIABLE TEMPLATE SECTION
-------------------------------------------------
These default variables are used to generate the config file template.
***IMPORTANT NOTE*** : Do NOT change the name of these variables !
Otherwise this can lead to fatal errors and failures !
*/

; Determines the location of the script's configuration file.
global configFileLocation := baseFilesLocation . "\config\ytdownloader.ini"
; Specifies path for the .txt file which stores the URLs.
URL_FILE_LOCATION := baseFilesLocation . "\YT_URLS.txt"
; Specifies path for the .txt file which stores the URL backup.
URL_BACKUP_FILE_LOCATION := baseFilesLocation . "\YT_URLS_BACKUP.txt"
; Specifies path for the .txt file which stores the blacklist file.
BLACKLIST_FILE_LOCATION := baseFilesLocation . "\YT_BLACKLIST.txt"
; Standard download log file path.
DOWNLOAD_LOG_FILE_LOCATION := baseFilesLocation . "\download\download_log.txt"
; Default download archive file location.
DOWNLOAD_ARCHIVE_LOCATION := baseFilesLocation . "\download\download_archive.txt"
; Default preset storage for the download option GUI.
DOWNLOAD_PRESET_LOCATION := baseFilesLocation . "\presets"
; Standard download path.
DOWNLOAD_PATH := baseFilesLocation . "\download"

; Defines if the script should ask the user for a brief explaination of it's core functions.
ASK_FOR_TUTORIAL := true

; Stores which hotkeys are enabled / disabled via the GUI.
HOTKEY_STATE_ARRAY := "[1, 1, 0, 1, 1, 1, 0]"
; Just a list of all standard hotkeys.
DOWNLOAD_HK := "+^!D"
URL_COLLECT_HK := "+^!S"
THUMBNAIL_URL_COLLECT_HK := "+^!F"
MAIN_GUI_HK := "+^!G"
TERMINATE_SCRIPT_HK := "+^!T"
RELOAD_SCRIPT_HK := "+^!R"
NOT_USED_HK := "+^!P"
CLEAR_URL_FILE_HK := "!F1"
OPTIONS_GUI_HK := "+^!A"
;------------------------------------------------

; Will contain all config values matching with each variable name in the array below.
; For example configVariableNameArray[2] = "URL_FILE_LOCATION"
; and configFileContentArray[2] = "baseFilesLocation . "\YT_URLS.txt""
; so basically URL_FILE_LOCATION = "baseFilesLocation . "\YT_URLS.txt"".
; NOTE : This had to be done because changing a global variable using a dynamic
; expression like global %myGlobalVarName% := "newValue" won't work.
global configFileContentArray := []

; Create an array including all settings variables names.
; This array makes it easier to apply certain values from the config file to the configFileContentArray.
; IMPORTANT NOTE : Do NOT forget to add each new config variable name into the array !!!
configVariableNameArray :=
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
; IMPORTANT NOTE : Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray !!!
configSectionNameArray :=
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

/*
CONFIG FILE SECTION
-------------------------------------------------
Creates, reads and manages the script's config file.
*/

; Creates a default config file with the standard parameters. Usually always creates
; a backup file to recover changes if needed.
createDefaultConfigFile(pBooleanCreateBackup := true, pBooleanShowPrompt := false)
{
    booleanCreateBackup := pBooleanCreateBackup
    booleanShowPrompt := pBooleanShowPrompt

    If (booleanShowPrompt = true)
    {
        result := MsgBox("Do you really want to replace the current`n`nconfig file with a new one ?", "Warning !", "YN Icon! T10")
        If (result = "No" || result = "Timeout")
        {
            Return
        }
    }
    If (booleanCreateBackup = true)
    {
        If (FileExist(configFileLocation))
        {
            FileMove(configFileLocation, configFileLocation . "_old", true)
        }
        If (!DirExist(SplitPath(configFileLocation, , &outDir)))
        {
            DirCreate(outDir)
        }
        FileAppend("", configFileLocation)
    }
    ; In case you forget to specify a section for EACH new config file entry this will remind you to do so :D
    If (configVariableNameArray.Length != configSectionNameArray.Length)
    {
        MsgBox("Not every config file entry has been asigned to a section !`n`nPlease fix this by checking both arrays.",
            "Error !", "O IconX")
        MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
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
            IniWrite(%configVariableNameArray[A_Index]%, configFileLocation, configSectionNameArray[A_Index],
            configVariableNameArray[A_Index])
        }
        MsgBox("A default config file has been generated.", "Config file status", "O Iconi T3")
    }
}

; Reads the config file and extracts it's values.
; The parameter optionName specifies a specific
; variable's content which you want to return.
; For example '"URL_FILE_LOCATION"' to return URL_FILE_LOCATION's content
; which is 'baseFilesLocation . "\YT_URLS.txt"' by default.
; Returns the value out of the config file.
; The booleanAskForPathCreation should be used with caution because
; it can have unseen consequences if a directory is not created.
readConfigFile(pOptionName, pBooleanAskForPathCreation := true)
{
    optionName := pOptionName
    booleanAskForPathCreation := pBooleanAskForPathCreation

    Loop (configVariableNameArray.Length)
    {
        Try
        {
            ; Replaces every config variable 's value with the config file's content.
            configFileContentArray.InsertAt(A_Index, IniRead(configFileLocation, configSectionNameArray[A_Index]
            , configVariableNameArray[A_Index]))
        }
        Catch
        {
            result := MsgBox("The script's config file seems to be corrupted or unavailable !"
                "`n`nDo you want to create a new one using the template ?"
                , "Error !", "YN IconX 8192 T10")
            If (result = "Yes")
            {
                createDefaultConfigFile()
                ; Gives the information a part of the script asked for even if the config file had to be generated.
                Return readConfigFile(optionName)
            }
            Else If (result = "No" || "Timeout")
            {
                MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
                ExitApp()
            }
        }
    }
    Loop (configVariableNameArray.Length)
    {
        ; Searches in the config file for the given option name to then extract the value.
        If (InStr(configVariableNameArray[A_Index], optionName, 0))
        {
            ; The following code only applies for path values.
            ; Everything else should be excluded.
            If (InStr(configFileContentArray[A_Index], "\"))
            {
                If (validatePath(configFileContentArray[A_Index], booleanAskForPathCreation) = false)
                {
                    MsgBox("Could not create directory !`nCheck the config file for a valid path at : `n "
                        . configVariableNameArray[A_Index], "Error !", "O Icon! T10")
                    MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
                    ExitApp()
                }
                Else
                {
                    ; This means that there was no error with the path given.
                    Return configFileContentArray[A_Index]
                }
            }
            Else
            {
                Return configFileContentArray[A_Index]
            }
        }
    }
    MsgBox("Could not find " . optionName . " in the config file.", "Script status", "O IconX T3")
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
        If (InStr(configVariableNameArray[A_Index], optionName, 0))
        {
            Try
            {
                ; Check just in case the given data is an array.
                If (data.Has(1) = true)
                {
                    dataString := arrayToString(data)
                    IniWrite(dataString, configFileLocation
                        , configSectionNameArray[A_Index]
                        , configVariableNameArray[A_Index])
                    Return
                }
                Else
                {
                    IniWrite(data, configFileLocation
                        , configSectionNameArray[A_Index]
                        , configVariableNameArray[A_Index])
                    Return
                }
            }
            Catch
            {
                ; If the try statement fails the object above can not be an array.
                IniWrite(data, configFileLocation
                    , configSectionNameArray[A_Index]
                    , configVariableNameArray[A_Index])
                Return
            }
        }
    }
    Throw ("Error while editing config file")
}

; Verfies the integrity of a given path or file location.
; It will also ask the user to create the given path if it does not exist yet.
; Returns true if a path is valid and false otherwise.
validatePath(pPath, pBooleanAskForPathCreation := true)
{
    path := pPath
    booleanAskForPathCreation := pBooleanAskForPathCreation

    ; If necessary the directory read in the config file will be created.
    ; SplitPath makes sure the last part of the whole path is removed.
    ; For example it removes the "\YT_URLS.txt"
    SplitPath(path, &outFileName, &outDir, &outExtension)
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*'
    Loop Parse (specialChars)
    {
        If (InStr(outDir, A_LoopField) || InStr(outDir, "\\") || InStr(outDir, "\\\"))
        {
            Return false
        }
    }
    ; This happens when there is no file name given in the config file e.g. at the preset location.
    If (outExtension = "" && !DirExist(path) && booleanAskForPathCreation = true)
    {
        result := MsgBox("The directory :`n" . path
            . "`ndoes not exist. `nWould you like to create it ?", "Warning !", "YN Icon! T10")
        If (result = "Yes")
        {
            Try
            {
                DirCreate(path)
                Sleep(500)
                Return true
            }
            Catch
            {
                Return false
            }
        }
        Else If (result = "No" || "Timeout")
        {
            MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
            ExitApp()
        }
    }
    Else If (!DirExist(outDir))
    {
        ; The download log file location will be created without any prompt to avoid annoying the user e.g.
        ; because the download folder has changed or has been deleted.
        If (outFileName = "download_log.txt")
        {
            Try
            {
                DirCreate(outDir)
                Sleep(500)
                Return true
            }
            Catch
            {
                Return false
            }
        }
        result := MsgBox("The directory :`n" . path
            . "`ndoes not exist. `nWould you like to create it ?", "Warning !", "YN Icon! T10")
        If (result = "Yes")
        {
            Try
            {
                DirCreate(outDir)
                Sleep(500)
                Return true
            }
            Catch
            {
                Return false
            }
        }
        Else If (result = "No" || "Timeout")
        {
            MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
            ExitApp()
        }
    }
}