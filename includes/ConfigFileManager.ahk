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
global disableTooltipStartup := false

;------------------------------------------------

/*
CONFIG VARIABLE TEMPLATE SECTION
-------------------------------------------------
These default variables are used to generate the config file template.
***IMPORTANT NOTE***: Do NOT change the name of these variables!
Otherwise this can lead to fatal errors and failures!
*/

config_onInit() {
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
    ; Toggle if the download options GUI should be shown on launch.
    global SHOW_OPTIONS_GUI_ON_LAUNCH := true
    ; This option controls if empty download folders with no media inside should be automatically deleted.
    global DELETE_EMPTY_DOWNLOAD_FOLDERS_AFTER_DOWNLOAD := true
    ; Stores which hotkeys are enabled / disabled via the GUI.
    global HOTKEY_STATE_ARRAY := "[1, 1, 1, 1, 1, 0, 0]"
    ; Just a list of all standard hotkeys.
    global DOWNLOAD_HK := "+^!D"
    global URL_COLLECT_HK := "+^!S"
    global THUMBNAIL_URL_COLLECT_HK := "+^!F"
    global MAIN_GUI_HK := "+^!G"
    global TERMINATE_SCRIPT_HK := "+^!T"
    global RELOAD_SCRIPT_HK := "+^!R"
    global RESTORE_URL_FILE_HK := "!F2"
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
    ; IMPORTANT NOTE: Do NOT forget to add each new config variable name into the array!!!
    global configVariableNameArray :=
        [
            "booleanDebugMode",
            "disableTooltipStartup",
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
            "RESTORE_URL_FILE_HK",
            "CLEAR_URL_FILE_HK"
        ]
    ; Create an array including the matching section name for EACH item in the configVariableNameArray.
    ; This makes it easier to read and write the config file.
    ; IMPORTANT NOTE: Do NOT forget to add the SECTION NAME for EACH new item added in the configVariableNameArray!!!
    global configSectionNameArray :=
        [
            "DebugSettings",
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

/*
Does what the name implies.
@param pBooleanCreateBackup [boolean] If set to true, the old config file will be saved.
@param pBooleanShowPrompt [boolean] Show a prompt to create the config file or do it silent.
*/
createDefaultConfigFile(pBooleanCreateBackup := true, pBooleanShowPrompt := false) {
    if (pBooleanShowPrompt) {
        result := MsgBox("Do you really want to replace the current config file with a new one ?",
            "VD - Replace Config File?", "YN Icon! 262144")
        if (result = "No" || result = "Timeout") {
            return
        }
    }
    if (pBooleanCreateBackup) {
        if (!DirExist(SplitPath(configFileLocation, , &outDir))) {
            DirCreate(outDir)
        }
        if (FileExist(configFileLocation)) {
            FileMove(configFileLocation, configFileLocation . "_old", true)
        }
    }
    FileAppend(
        "#Important note: When changing the config file, the script has to be reloaded for the changes to take effect!`n"
        . "#You can find a hotkey list here: (https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols)",
        configFileLocation)
    ; In case you forget to specify a section for EACH new config file entry this will remind you to do so :D
    if (configVariableNameArray.Length != configSectionNameArray.Length) {
        MsgBox("Not every config file entry has been asigned to a section!`n`nPlease fix this by checking both arrays.",
            "VD - Config File Status - Error!", "O IconX 262144")
        MsgBox("Script terminated.", "VD - Script Status", "O IconX T1.5")
        ExitApp()
    }
    else {
        /*
        This it what it looked like before using an array to define all parameters.
        IniWrite(URL_FILE_LOCATION, configFileLocation, "FileLocations", "URL_FILE_LOCATION")
        */
        loop configVariableNameArray.Length {
            IniWrite(%configVariableNameArray.Get(A_Index)%, configFileLocation, configSectionNameArray.Get(A_Index),
            configVariableNameArray.Get(A_Index))
        }
        if (pBooleanShowPrompt) {
            MsgBox("A default config file has been generated.", "VD - Config File Status", "O Iconi T3")
        }
    }
}

/*
Reads the config file and extracts it's values.
@param pOptionName [String] Should be the name of an config file option for example "URL_FILE_LOCATION"
@param pBooleanAskForPathCreation [boolean] If set to true, will display a prompt to create the path,
if it does not exist on the current system.
@param pBooleanCheckConfigFileStatus [boolean] If set to true, will check the config file integrity while reading.
@returns [Any] A value from the config file.
*/
readConfigFile(pOptionName, pBooleanAskForPathCreation := true, pBooleanCheckConfigFileStatus := true) {
    ; Thanks to my buddy Elias for testing and helping me debugging this script :)
    global configVariableNameArray
    global configFileContentArray
    global booleanFirstTimeLaunch

    if (pBooleanCheckConfigFileStatus) {
        checkConfigFileIntegrity()
    }

    loop (configVariableNameArray.Length) {
        ; Searches in the config file for the given option name to then extract the value.
        if (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0)) {
            ; The following code only applies for path values.
            ; Everything else should be excluded.
            if (InStr(configFileContentArray.Get(A_Index), "\")) {
                booleanCreatePathSilent := false
                if (booleanFirstTimeLaunch) {
                    pBooleanAskForPathCreation := false
                    booleanCreatePathSilent := true
                }
                if (!validatePath(configFileContentArray.Get(A_Index), pBooleanAskForPathCreation,
                booleanCreatePathSilent)) {
                    MsgBox("Check the config file for a valid path at`n["
                        . configVariableNameArray.Get(A_Index) . "]", "VD - Config File Status - Error!",
                        "O Icon! 262144")
                    MsgBox("Script terminated.", "VD - Script Status", "O IconX T1.5")
                    ExitApp()
                }
                else {
                    ; This means that there was no error with the path given.
                    return configFileContentArray.Get(A_Index)
                }
            }
            else {
                return configFileContentArray.Get(A_Index)
            }
        }
    }
    MsgBox("Could not find " . pOptionName . " in the config file.`nScript terminated.",
        "VD - Config File Status - Error!", "O IconX 262144")
    ExitApp()
}

/*
Changes existing values in the config file.
@param pOptionName [String] Should be the name of a config file option for example "URL_FILE_LOCATION".
@param pData [Any] The data to replace the old value with.
*/
editConfigFile(pOptionName, pData) {
    ; Basically the same as creating the config file.
    try
    {
        loop (configVariableNameArray.Length) {
            ; Searches in the config file for the given option name to then change the value.
            if (InStr(configVariableNameArray.Get(A_Index), pOptionName, 0)) {
                try
                {
                    ; Check just in case the given data is an array.
                    if (pData.Has(1)) {
                        dataString := arrayToString(pData)
                        IniWrite(dataString, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                    else {
                        IniWrite(pData, configFileLocation
                            , configSectionNameArray.Get(A_Index)
                            , configVariableNameArray.Get(A_Index))
                    }
                }
                catch {
                    ; If the try statement fails the object above cannot be an array.
                    IniWrite(pData, configFileLocation
                        , configSectionNameArray.Get(A_Index)
                        , configVariableNameArray.Get(A_Index))
                }
            }
        }
    }
    catch as error {
        displayErrorMessage(error)
    }
}

; Reads the whole config file and throws an error when something is not right.
checkConfigFileIntegrity() {
    global booleanFirstTimeLaunch

    loop (configVariableNameArray.Length) {
        try
        {
            ; Replaces every slot in the configFileContentArray with the value from the config file's content.
            configFileContentArray.InsertAt(A_Index, IniRead(configFileLocation, configSectionNameArray.Get(A_Index)
            , configVariableNameArray.Get(A_Index)))
        }
        catch {
            ; Does not show a prompt when the script is launched for the very first time.
            if (booleanFirstTimeLaunch) {
                createDefaultConfigFile()
                return true
            }
            result := MsgBox("The script config file seems to be corrupted or unavailable!"
                "`n`nDo you want to create a new one using the template?"
                , "VD - Config File Status - Warning!", "YN Icon! 262144")
            switch (result) {
                case "Yes":
                {
                    createDefaultConfigFile()
                    return true
                }
                Default:
                {
                    MsgBox("Script terminated.", "VD - Script Status", "O IconX T1.5")
                    ExitApp()
                }
            }
        }
    }
}

/*
Verfies the integrity of a given path or file location.
NOTE: pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the same time.
@param pPath [String] Should be a path to validate.
@param pBooleanAskForPathCreation [boolean] If set to true, will display a prompt to create the non-existing directory.
@param pBooleanCreatePathSilent [boolean] If set to true, will create any valid directory, if it doesn't exist.
@returns [boolean] True if a path is valid and false otherwise.
*/
validatePath(pPath, pBooleanAskForPathCreation := true, pBooleanCreatePathSilent := false) {
    if (pBooleanAskForPathCreation && pBooleanCreatePathSilent) {
        MsgBox("[" . A_ThisFunc .
            "()] [ERROR] pBooleanAskForPathCreation and pBooleanCreatePathSilent cannot be true at the "
            . "same time.`nTerminating script.", "VD - [" . A_ThisFunc . "()]", "IconX 262144")
        ExitApp()
    }

    ; SplitPath makes sure the last part of the whole path is removed.
    ; For example it removes the "\YT_URLS.txt"
    SplitPath(pPath, &outFileName, &outDir, &outExtension, , &outDrive)
    ; Replaces the drive name with empty space, because the "C:" would trigger the parse loop below mistakenly.
    pathWithoutDrive := StrReplace(pPath, outDrive)
    ; Looks for one of the specified characters to identify invalid path names.
    ; Searches for common mistakes in the path name.
    specialChars := '<>"/|?*:'
    loop parse (specialChars) {
        if (InStr(pathWithoutDrive, A_LoopField)) {
            return false
        }
    }
    ; Checks if the path contains two or more or no "\".
    if (RegExMatch(pPath, "\\{2,}") || !InStr(pPath, "\")) {
        return false
    }

    ; This means the path has no file at the end.
    if (outExtension = "") {
        if (!DirExist(pPath)) {
            if (pBooleanAskForPathCreation) {
                result := MsgBox("The directory`n[" . pPath . "] does not exist."
                    "`nWould you like to create it ?", "VD - Config File Status - Warning!", "YN Icon! 262144")
                switch (result) {
                    case "Yes":
                    {
                        DirCreate(pPath)
                    }
                    Default:
                    {
                        MsgBox("Script terminated.", "VD - Script Status", "O IconX T1.5")
                        ExitApp()
                    }
                }
            }
            else if (pBooleanCreatePathSilent) {
                DirCreate(pPath)
            }
        }
    }
    ; This means the path has a file at the end, which has to be excluded.
    else {
        if (!DirExist(outDir)) {
            if (pBooleanAskForPathCreation) {
                result := MsgBox("The directory`n[" . outDir . "] does not exist."
                    "`nWould you like to create it ?", "VD - Config File Status - Warning!", "YN Icon! 262144")
                switch (result) {
                    case "Yes":
                    {
                        DirCreate(outDir)
                    }
                    Default:
                    {
                        MsgBox("Script terminated.", "VD - Script Status", "O IconX T1.5")
                        ExitApp()
                    }
                }
            }
            else if (pBooleanCreatePathSilent) {
                DirCreate(outDir)
            }
        }
    }
    return true
}
