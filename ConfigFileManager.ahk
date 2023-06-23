#SingleInstance Force
SendMode "Input"
CoordMode "Mouse", "Client"
#Warn Unreachable, Off

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
***IMPORTANT NOTE*** : Do NOT change the order of these variables !
Otherwise this can lead to fatal erros and failures !
*/

; Determines the location of the script's configuration file.
global configFileLocation := A_WorkingDir . "\files\config\ytdownloader.ini"
; Specifies path for the .txt file which stores the URLs.
URL_FILE_LOCATION := A_ScriptDir . "\files\YT_URLS.txt"
; Specifies path for the .txt file which stores the URL backup.
URL_BACKUP_FILE_LOCATION := A_ScriptDir . "\files\YT_URLS_BACKUP.txt"
; Specifies path for the .txt file which stores the blacklist file.
BLACKLIST_FILE_LOCATION := A_ScriptDir . "\files\YT_BLACKLIST.txt"
; Standard download path.
DEFAULT_DOWNLOAD_PATH := A_ScriptDir . "\files\download"
; Stores which hotkeys are enabled / disabled via the GUI.
HOTKEY_STATE_ARRAY := "[0, 0, 0, 0, 1, 1, 1]"
; Just a list of all standard hotkeys.
DOWNLOAD_HK := "+^!D"
URL_COLLECT_HK := "+^!S"
THUMBNAIL_URL_COLLECT_HK := "+^!F"
MAIN_GUI_HK := "+^!G"
TERMINATE_SCRIPT_HK := "+^!T"
RELOAD_SCRIPT_HK := "+^!R"
PAUSE_CONTINUE_SCRIPT_HK := "+^!P"
CLEAR_URL_FILE_HK := "!F1"
OPTIONS_GUI_HK := "+^!A"
;------------------------------------------------

; Will contain all config values matching with each variable name in the array below.
; For example configVariableNameArray[2] = "URL_FILE_LOCATION"
; and configFileContentArray[2] = "A_ScriptDir . "\files\YT_URLS.txt""
; so basically URL_FILE_LOCATION = "A_ScriptDir . "\files\YT_URLS.txt"".
; NOTE : This had to be done because changing a global variable using a dynamic
; expression like global %myGlobalVarName% := "newValue" won't work.
global configFileContentArray := []

; Create an array including all settings variables names.
; This array makes it easier to apply certain values from the config file to the configFileContentArray.
; IMPORTANT NOTE : Do NOT forget to add each new config variable name into the array !!!
configVariableNameArray := [
    "booleanDebugMode",
    "URL_FILE_LOCATION",
    "URL_BACKUP_FILE_LOCATION",
    "BLACKLIST_FILE_LOCATION",
    "DEFAULT_DOWNLOAD_PATH",
    "HOTKEY_STATE_ARRAY",
    "DOWNLOAD_HK",
    "URL_COLLECT_HK",
    "THUMBNAIL_URL_COLLECT_HK",
    "MAIN_GUI_HK",
    "OPTIONS_GUI_HK",
    "TERMINATE_SCRIPT_HK",
    "RELOAD_SCRIPT_HK",
    "PAUSE_CONTINUE_SCRIPT_HK",
    "CLEAR_URL_FILE_HK"
]
; Create an array including the matching section name for EACH item in the configVariableNameArray.
; This makes it easier to read and write the config file.
; IMPORTANT NOTE : Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray !!!
configSectionNameArray := [
    "DebugSettings",
    "FileLocations",
    "FileLocations",
    "FileLocations",
    "FileLocations",
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
createDefaultConfigFile(pBooleanCreateBackUp := true, pBooleanShowPrompt := false)
{
    booleanCreateBackUp := pBooleanCreateBackUp
    booleanShowPrompt := pBooleanShowPrompt

    If (booleanShowPrompt = true)
    {
        result := MsgBox("Do you really want to replace the current`n`nconfig file with a new one ?", "Warning !", "YN Icon! T10")
        If (result = "No" || result = "Timeout")
        {
            Return
        }
    }
    If (booleanCreateBackUp = true)
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
        MsgBox("A default config file has been generated.", "Information", "O Iconi T3")
    }
    Return
}

; Reads the config file and extracts it's values.
; The parameter optionName specifies a specific
; variable's content which you want to return.
; For example '"URL_FILE_LOCATION"' to return URL_FILE_LOCATION's content
; which is 'A_ScriptDir . "\files\YT_URLS.txt"' by default.
; Returns the value out of the config file.
readConfigFile(pOptionName)
{
    optionName := pOptionName

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
                readConfigFile(optionName)
                Return
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
                ; If necessary the directory read in the config file will be created.
                ; SplitPath makes sure the last part of the whole path is removed.
                ; For example it removes the "\YT_URLS.txt"
                SplitPath(configFileContentArray[A_Index], , &outDir)
                ; Looks for one of the specified characters to identify invalid path names.
                ; Searches for common mistakes in the path name.
                specialChars := '<>"/|?*'
                Loop Parse, specialChars
                {
                    If (InStr(outDir, A_LoopField) || InStr(outDir, "\\") || InStr(outDir, "\\\"))
                    {
                        MsgBox("Could not create directory !`nCheck the config file for a valid path at : `n "
                            . configVariableNameArray[A_Index], "Error !", "O Icon! T10")
                        MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
                        ExitApp()
                    }
                }
                If (!DirExist(outDir))
                {
                    result := MsgBox("The directory :`n" . configFileContentArray[A_Index]
                    . "`ndoes not exist. `nWould you like to create it ?", "Warning !", "YN Icon! T10")
                    If (result = "Yes")
                    {
                        Try
                        {
                            DirCreate(outDir)
                            Return configFileContentArray[A_Index]
                        }
                        Catch
                        {
                            MsgBox("Could not create directory !`nCheck the config file for a valid path at : `n "
                                . configVariableNameArray[A_Index], "Error !", "O Icon! T10")
                            MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
                            ExitApp()
                        }
                    }
                    Else If (result = "No" || "Timeout")
                    {
                        MsgBox("Script has been terminated.", "Script status", "O IconX T1.5")
                        ExitApp()
                    }
                    ExitApp()
                }
            }
            Return configFileContentArray[A_Index]
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
        }
    }
    Throw
}