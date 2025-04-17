#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

configurationFile_onInit() {
    global scriptMainDirectory

    ; Determines the location of the script's configuration file.
    global configFileLocation := scriptMainDirectory . "\VideoDownloader.ini"
    ; Creates the base set of config file entry objects.
    initializeConfigEntryMap()
    ; Checks the integrity of the config file and repairs it if necessary.
    initializeCurrentConfigFile()
}

/*
Creates all required config file entries and adds them to the config file entry map.
The config file entries will read their actual value from the real config file later.
*/
initializeConfigEntryMap() {
    global versionFullName
    global configFileEntryMap := Map()

    ; [DebugSettings]
    DebugSettings := "DebugSettings"
    ENABLE_DEBUG_HOTKEYS := false
    ENABLE_DEBUG_MODE := false
    CONFIG_FILE_VD_VERSION := versionFullName
    ; [GeneralSettings]
    GeneralSettings := "GeneralSettings"
    START_WITH_WINDOWS := false
    SHOW_VIDEO_LIST_GUI_ON_LAUNCH := true
    CHECK_FOR_UPDATES_AT_LAUNCH := true
    UPDATE_TO_BETA_VERSIONS := false
    ASK_FOR_TUTORIAL := true
    ; [DirectoryPaths]
    DirectoryPaths := "DirectoryPaths"
    DEFAULT_DOWNLOAD_DIRECTORY := scriptMainDirectory . "\download"
    TEMP_DIRECTORY := scriptMainDirectory . "\temp"
    TEMP_DOWNLOAD_DIRECTORY := TEMP_DIRECTORY . "\download_temp"
    ; [NotificationSettings]
    NotificationSettings := "NotificationSettings"
    DISPLAY_STARTUP_NOTIFICATION := true
    DISPLAY_EXIT_NOTIFICATION := true
    DISPLAY_FINISHED_DOWNLOAD_NOTIFICATION := true
    ; [HotkeySettings]
    HotkeySettings := "HotkeySettings"
    START_DOWNLOAD_HK := "+^!D"
    START_DOWNLOAD_HK_ENABLED := true
    URL_COLLECT_HK := "+^!S"
    URL_COLLECT_HK_ENABLED := true
    THUMBNAIL_URL_COLLECT_HK := "+^!F"
    THUMBNAIL_URL_COLLECT_HK_ENABLED := true
    VIDEO_LIST_GUI_HK := "+^!G"
    VIDEO_LIST_GUI_HK_ENABLED := true
    RELOAD_PROGRAM_HK := "+^!R"
    RELOAD_PROGRAM_HK_ENABLED := true
    TERMINATE_PROGRAM_HK := "+^!T"
    TERMINATE_PROGRAM_HK_ENABLED := true
    ; [VideoListDefaultPreferences]
    VideoListDefaultPreferences := "VideoListDefaultPreferences"
    DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX := 1
    DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX := 1
    ADD_VIDEO_URL_IS_A_PLAYLIST := false
    ADD_VIDEO_URL_USE_PLAYLIST_RANGE := false
    ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE := 1
    REMOVE_VIDEO_CONFIRM_DELETION := false
    REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED := false
    EXPORT_ONLY_VALID_URLS := true
    AUTO_EXPORT_VIDEO_LIST := true
    REMOVE_VIDEOS_AFTER_DOWNLOAD := true
    TERMINATE_AFTER_DOWNLOAD := false

    ; [DebugSettings]
    ConfigFileEntry(ENABLE_DEBUG_HOTKEYS, "ENABLE_DEBUG_HOTKEYS", DebugSettings, ENABLE_DEBUG_HOTKEYS, "boolean")
    ConfigFileEntry(ENABLE_DEBUG_MODE, "ENABLE_DEBUG_MODE", DebugSettings, ENABLE_DEBUG_MODE, "boolean")
    ConfigFileEntry(CONFIG_FILE_VD_VERSION, "CONFIG_FILE_VD_VERSION", DebugSettings, CONFIG_FILE_VD_VERSION, "string")
    ; [GeneralSettings]
    ConfigFileEntry(START_WITH_WINDOWS, "START_WITH_WINDOWS", GeneralSettings,
        START_WITH_WINDOWS, "boolean")
    ConfigFileEntry(SHOW_VIDEO_LIST_GUI_ON_LAUNCH, "SHOW_VIDEO_LIST_GUI_ON_LAUNCH", GeneralSettings,
        SHOW_VIDEO_LIST_GUI_ON_LAUNCH, "boolean")
    ConfigFileEntry(CHECK_FOR_UPDATES_AT_LAUNCH, "CHECK_FOR_UPDATES_AT_LAUNCH", GeneralSettings,
        CHECK_FOR_UPDATES_AT_LAUNCH, "boolean")
    ConfigFileEntry(UPDATE_TO_BETA_VERSIONS, "UPDATE_TO_BETA_VERSIONS", GeneralSettings,
        UPDATE_TO_BETA_VERSIONS, "boolean")
    ConfigFileEntry(ASK_FOR_TUTORIAL, "ASK_FOR_TUTORIAL", GeneralSettings, ASK_FOR_TUTORIAL, "boolean")
    ; [DirectoryPaths]
    ConfigFileEntry(DEFAULT_DOWNLOAD_DIRECTORY, "DEFAULT_DOWNLOAD_DIRECTORY", DirectoryPaths,
        DEFAULT_DOWNLOAD_DIRECTORY, "directory")
    ConfigFileEntry(TEMP_DIRECTORY, "TEMP_DIRECTORY", DirectoryPaths, TEMP_DIRECTORY, "directory")
    ConfigFileEntry(TEMP_DOWNLOAD_DIRECTORY, "TEMP_DOWNLOAD_DIRECTORY", DirectoryPaths,
        TEMP_DOWNLOAD_DIRECTORY, "directory")
    ; [NotificationSettings]
    ConfigFileEntry(DISPLAY_STARTUP_NOTIFICATION, "DISPLAY_STARTUP_NOTIFICATION", NotificationSettings,
        DISPLAY_STARTUP_NOTIFICATION, "boolean")
    ConfigFileEntry(DISPLAY_EXIT_NOTIFICATION, "DISPLAY_EXIT_NOTIFICATION", NotificationSettings,
        DISPLAY_EXIT_NOTIFICATION, "boolean")
    ConfigFileEntry(DISPLAY_FINISHED_DOWNLOAD_NOTIFICATION, "DISPLAY_FINISHED_DOWNLOAD_NOTIFICATION",
        NotificationSettings, DISPLAY_FINISHED_DOWNLOAD_NOTIFICATION, "boolean")
    ; [HotkeySettings]
    ConfigFileEntry(START_DOWNLOAD_HK, "START_DOWNLOAD_HK", HotkeySettings, START_DOWNLOAD_HK, "hotkey")
    ConfigFileEntry(START_DOWNLOAD_HK_ENABLED, "START_DOWNLOAD_HK_ENABLED", HotkeySettings,
        START_DOWNLOAD_HK_ENABLED, "boolean")
    ConfigFileEntry(URL_COLLECT_HK, "URL_COLLECT_HK", HotkeySettings, URL_COLLECT_HK, "hotkey")
    ConfigFileEntry(URL_COLLECT_HK_ENABLED, "URL_COLLECT_HK_ENABLED", HotkeySettings,
        URL_COLLECT_HK_ENABLED, "boolean")
    ConfigFileEntry(THUMBNAIL_URL_COLLECT_HK, "THUMBNAIL_URL_COLLECT_HK", HotkeySettings,
        THUMBNAIL_URL_COLLECT_HK, "hotkey")
    ConfigFileEntry(THUMBNAIL_URL_COLLECT_HK_ENABLED, "THUMBNAIL_URL_COLLECT_HK_ENABLED", HotkeySettings,
        THUMBNAIL_URL_COLLECT_HK_ENABLED, "boolean")
    ConfigFileEntry(VIDEO_LIST_GUI_HK, "VIDEO_LIST_GUI_HK", HotkeySettings, VIDEO_LIST_GUI_HK, "hotkey")
    ConfigFileEntry(VIDEO_LIST_GUI_HK_ENABLED, "VIDEO_LIST_GUI_HK_ENABLED", HotkeySettings,
        VIDEO_LIST_GUI_HK_ENABLED, "boolean")
    ConfigFileEntry(RELOAD_PROGRAM_HK, "RELOAD_PROGRAM_HK", HotkeySettings, RELOAD_PROGRAM_HK, "hotkey")
    ConfigFileEntry(RELOAD_PROGRAM_HK_ENABLED, "RELOAD_PROGRAM_HK_ENABLED", HotkeySettings,
        RELOAD_PROGRAM_HK_ENABLED, "boolean")
    ConfigFileEntry(TERMINATE_PROGRAM_HK, "TERMINATE_PROGRAM_HK", HotkeySettings, TERMINATE_PROGRAM_HK, "hotkey")
    ConfigFileEntry(TERMINATE_PROGRAM_HK_ENABLED, "TERMINATE_PROGRAM_HK_ENABLED", HotkeySettings,
        TERMINATE_PROGRAM_HK_ENABLED, "boolean")
    ; [VideoListDefaultPreferences]
    ConfigFileEntry(DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX, "DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX",
        VideoListDefaultPreferences,
        DEFAULT_DESIRED_DOWNLOAD_FORMAT_ARRAY_INDEX, "string")
    ConfigFileEntry(DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX, "DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX",
        VideoListDefaultPreferences,
        DEFAULT_DESIRED_SUBTITLE_ARRAY_INDEX, "string")
    ConfigFileEntry(ADD_VIDEO_URL_IS_A_PLAYLIST, "ADD_VIDEO_URL_IS_A_PLAYLIST", VideoListDefaultPreferences,
        ADD_VIDEO_URL_IS_A_PLAYLIST, "boolean")
    ConfigFileEntry(ADD_VIDEO_URL_USE_PLAYLIST_RANGE, "ADD_VIDEO_URL_USE_PLAYLIST_RANGE",
        VideoListDefaultPreferences, ADD_VIDEO_URL_USE_PLAYLIST_RANGE, "boolean")
    ConfigFileEntry(ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE, "ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE",
        VideoListDefaultPreferences,
        ADD_VIDEO_PLAYLIST_RANGE_INDEX_VALUE, "string")
    ConfigFileEntry(REMOVE_VIDEO_CONFIRM_DELETION, "REMOVE_VIDEO_CONFIRM_DELETION", VideoListDefaultPreferences,
        REMOVE_VIDEO_CONFIRM_DELETION, "boolean")
    ConfigFileEntry(REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED,
        "REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED", VideoListDefaultPreferences,
        REMOVE_VIDEO_CONFIRM_ONLY_WHEN_MULTIPLE_SELECTED, "boolean")
    ConfigFileEntry(EXPORT_ONLY_VALID_URLS, "EXPORT_ONLY_VALID_URLS", VideoListDefaultPreferences,
        EXPORT_ONLY_VALID_URLS, "boolean")
    ConfigFileEntry(AUTO_EXPORT_VIDEO_LIST, "AUTO_EXPORT_VIDEO_LIST", VideoListDefaultPreferences,
        AUTO_EXPORT_VIDEO_LIST, "boolean")
    ConfigFileEntry(REMOVE_VIDEOS_AFTER_DOWNLOAD, "REMOVE_VIDEOS_AFTER_DOWNLOAD", VideoListDefaultPreferences,
        REMOVE_VIDEOS_AFTER_DOWNLOAD, "boolean")
    ConfigFileEntry(TERMINATE_AFTER_DOWNLOAD, "TERMINATE_AFTER_DOWNLOAD", VideoListDefaultPreferences,
        TERMINATE_AFTER_DOWNLOAD, "boolean")
}

; Uses the config file entry map and each config file entry tries to read out it's value from the current config file.
initializeCurrentConfigFile() {
    global configFileLocation
    global configFileEntryMap

    if (!FileExist(configFileLocation)) {
        return createDefaultConfigFile()
    }

    ; This map will save all config file entries which could not read their value from the current config file.
    nonExistingConfigFileEntryMap := Map()
    for (key, configEntry in configFileEntryMap) {
        ; Tries to extract the value of each config file entry from the current config file.
        currentValue :=
            IniRead(configFileLocation, configEntry.section, configEntry.key, "_result_no_value_found")
        if (currentValue == "_result_no_value_found") {
            ; Writes the config file entry which could not read it's value from the current config file to the map.
            nonExistingConfigFileEntry := configEntry.Clone()
            nonExistingConfigFileEntryMap.Set(key, nonExistingConfigFileEntry)
        }
        else {
            configFileEntryMap.Get(key).value := currentValue
            ; Must be called because the value has changed.
            configFileEntryMap.Get(key).rebuildIdentifierString()
        }
    }
    ; Not every config file entry could read it's value from the current config file.
    if (nonExistingConfigFileEntryMap.Count > 0) {
        currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
        SplitPath(configFileLocation, , &outDir, &outExt, &outNameNoExt)
        ; We use the current time stamp to generate a unique name for the old config file.
        oldConfigFileName := outNameNoExt . "_old_" . currentTime . "." . outExt
        oldConfigFileLocation := outDir . "\" . oldConfigFileName
        /*
        Creates a default config file and saves the backup to the desired location.
        The new file will be created and contain all required config entries.
        We can now try to import the old configuration file to keep as many of the settings as possible.
        */
        createDefaultConfigFile(true, oldConfigFileLocation)
        ; Do not ask for confirmation and do not reload the application.
        importOldConfigFile(oldConfigFileLocation, false, false)
        MsgBox("A corrupted or old config file has been imported.", "VD - Imported Config File", "O Iconi 262144 T3")
    }
}

/*
Does what the name implies.
@param pBooleanCreateBackup [boolean] If set to true, the old config file will be saved.
@param pBackupFileLocation [String] An optional path (including the filename) to save the config file backup to.
*/
createDefaultConfigFile(pBooleanCreateBackup := true, pBackupFileLocation?) {
    global configFileLocation
    global configFileEntryMap

    currentTime := FormatTime(A_Now, "yyyy.MM.dd_HH-mm-ss")
    ; Creates backup of the old config file (if it exists).
    if (pBooleanCreateBackup && FileExist(configFileLocation)) {
        ; Moves the backup file to the specified location.
        if (IsSet(pBackupFileLocation)) {
            FileMove(configFileLocation, pBackupFileLocation, true)
        }
        ; Keeps the backup file in the same directory and just renames it.
        else {
            SplitPath(configFileLocation, , &outDir, &outExt, &outNameNoExt)
            ; We use the current time stamp to generate a unique name for the old config file.
            oldConfigFileName := outNameNoExt . "_old_" . currentTime . "." . outExt
            oldConfigFileLocation := outDir . "\" . oldConfigFileName
            FileMove(configFileLocation, oldConfigFileLocation)
        }
    }

    ; Overwrites the already existing map with new entries.
    initializeConfigEntryMap()
    ; Creates the config file with a few comments on top.
    configFileComments .= "; VideoDownloader Configuration File (https://github.com/LeoTN/yt-dlp-autohotkey-gui)"
    configFileComments .= "`n; This config file was created on " . currentTime . "."
    configFileComments .=
        "`n; A hotkey list can be found here (https://www.autohotkey.com/docs/v2/Hotkeys.htm#Symbols)`n"
    FileAppend(configFileComments, configFileLocation, "UTF-16")
    ; Writes each config file entry to the config file.
    for (key, configEntry in configFileEntryMap) {
        configEntry.writeToFile()
    }
}

/*
Tries to import old VideoDownloader config file even from older versions.
This is required so that users don't loose their configuration between updates.
@param pOldConfigFileLocation [String] The location of the config file to import.
@param pBooleanAskForConfirmation [boolean] If set to true, will prompt the user to confirm any changes.
@param pBooleanReloadAfterImport [boolean] If set to true, will reload the application after importing.
*/
importOldConfigFile(pOldConfigFileLocation, pBooleanAskForConfirmation := true, pBooleanReloadAfterImport := true) {
    global configFileEntryMap

    ; We use a copy because we don't want to modify the live config yet.
    configFileEntryMapCopy := configFileEntryMap.Clone()
    ; This map contains all config file entry objects from the current config file which exist in the old one.
    importableConfigFileEntryMap := Map()
    for (key, configEntry in configFileEntryMapCopy) {
        ; Tries to extract the value of each config file entry from the old config file.
        importedValue :=
            IniRead(pOldConfigFileLocation, configEntry.section, configEntry.key, "_result_no_value_found")
        if (importedValue != "_result_no_value_found") {
            importedConfigEntry := configEntry.Clone()
            importedConfigEntry.value := importedValue
            ; Writes the imported value into the config file entry.
            importableConfigFileEntryMap.Set(key, importedConfigEntry)
        }
    }
    if (importableConfigFileEntryMap.Count > 0 && pBooleanAskForConfirmation) {
        msgText := "Please confirm the import of the config file [" . pOldConfigFileLocation . "]."
        msgText .= "`n********************"
        msgText .= "`nTotal amount of imported entries: " . importableConfigFileEntryMap.Count
        msgText .= "`n********************"
        msgText .= "`n`nYou need to restart the application for the changes to take effect."
        msgText .= "`n`nView details to see which entries of the current config file will be changed."
        msgTitle := "VD - Confirm Config File Import"
        msgHeadLine := "Confirm Config File Import"
        msgButton1 := "Import"
        msgButton2 := "View Details"
        msgButton3 := "Abort"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)
        if (result == msgButton1) {
            ; Leaves the if statement and executes the code at the end of the function.
        }
        else if (result == msgButton2) {
            tempChangesFileLocation := A_Temp . "\VideoDownloader - Current Configuration Changes After Import.txt"
            tempChangesFileContent := "############################################################"
            tempChangesFileContent .= "`nThe following config file entrie(s) will be changed."
            tempChangesFileContent .= "`n############################################################`n"
            for (key, newConfigEntry in importableConfigFileEntryMap) {
                oldConfigFileEntry := configFileEntryMapCopy.Get(key)
                ; Checks if the values have actually changed.
                if (oldConfigFileEntry.value == newConfigEntry.value) {
                    continue
                }
                tempChangesFileContent .= oldConfigFileEntry.key . ": (" . oldConfigFileEntry.value
                tempChangesFileContent .= ") -> (" . newConfigEntry.value . ")`n"
            }
            if (FileExist(tempChangesFileLocation)) {
                FileDelete(tempChangesFileLocation)
            }
            FileAppend(tempChangesFileContent, tempChangesFileLocation)
            Run(tempChangesFileLocation)
            return importOldConfigFile(pOldConfigFileLocation, pBooleanAskForConfirmation, pBooleanReloadAfterImport)
        }
        else {
            return
        }
    }
    ; Replaces the current config file entry objects with the imported ones.
    for (key, configEntry in importableConfigFileEntryMap) {
        configFileEntryMap.Set(key, configEntry)
        configFileEntryMap.Get(key).writeToFile()
    }
    if (pBooleanReloadAfterImport) {
        reloadApplicationPrompt()
    }
}

/*
Simply copies the currently used config file to a specified location.
@param pNewConfigFileLocation [String] The file path (including the name and extension) for the config file copy.
*/
exportConfigFile(pNewConfigFileLocation) {
    global configFileLocation

    FileCopy(configFileLocation, pNewConfigFileLocation, true)
}

/*
Reads the config file and extracts it's values.
@param pKey [String] The key in the config file.
@param pSection [String] An optional section where the key is located.
If there is a chance, that the key name might be used in multiple sections, this parameter should not be omitted.
@returns [String] The value of the config file entry.
*/
readConfigFile(pKey, pSection?) {
    global configFileLocation
    global configFileEntryMap

    matchingEntryArray := Array()
    for (key, configEntry in configFileEntryMap) {
        ; Tries to find the entry using both the section and the key name.
        if (IsSet(pSection) && configEntry.section == pSection && configEntry.key == pKey) {
            matchingEntryArray.Push(configEntry)
        }
        /*
        Tries to find the entry using only the key name.
        This only works when every key has a unique name which should usually be the case.
        */
        else if (!IsSet(pSection) && configEntry.key == pKey) {
            matchingEntryArray.Push(configEntry)
        }
    }
    if (matchingEntryArray.Length == 1) {
        ; Returns the value of the config file entry.
        return matchingEntryArray.Get(1).value
    }
    else if (matchingEntryArray.Length == 0) {
        msgText := "There was a problem while reading the config file."
        msgText .= "`n********************"
        if (IsSet(pSection)) {
            msgText .= "`nThe following section [" . pSection . "] and key [" . pKey . "] could not be found."
        }
        else {
            msgText .= "`nThe following key [" . pKey . "] could not be found."
        }
        msgText .= "`n********************"
        msgText .= "`n`nYou could try to reset the config file at [" . configFileLocation . "]."
        msgText .= "`n********************"
        msgText .= "`nIt is recommended to exit the program."
        msgText .= "`n`nContinue at your own risk."
        msgTitle := "VD - Config File Reading Error"
        msgHeadLine := "Config File Reading Error"
        msgButton1 := "Continue"
        msgButton2 := ""
        msgButton3 := "Exit"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)
        if (result != msgButton1) {
            exitScriptWithNotification(true)
        }
    }
    else {
        msgText := "There was a problem while reading the config file."
        msgText .= "`n********************"
        msgText .= "`nThe following key [" . pKey . "] is duplicate in the config file."
        msgText .= "`n********************"
        msgText .= "`n`nYou could try to reset the config file at [" . configFileLocation . "]."
        msgText .= "`n********************"
        msgText .= "`nIt is recommended to exit the program."
        msgText .= "`n`nContinue at your own risk."
        msgTitle := "VD - Config File Reading Error"
        msgHeadLine := "Config File Reading Error"
        msgButton1 := "Continue"
        msgButton2 := ""
        msgButton3 := "Exit"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)
        if (result != msgButton1) {
            exitScriptWithNotification(true)
        }
    }
}

/*
Changes existing values in the config file.
@param pNewValue [String] The new value for the config file entry.
@param pKey [String] The key in the config file.
@param pSection [String] An optional section where the key is located.
If there is a chance, that the key name might be used in multiple sections, this parameter should not be omitted.
*/
editConfigFile(pNewValue, pKey, pSection?) {
    global configFileLocation
    global configFileEntryMap

    matchingEntryArray := Array()
    for (key, configEntry in configFileEntryMap) {
        ; Tries to find the entry using both the section and the key name.
        if (IsSet(pSection) && configEntry.section == pSection && configEntry.key == pKey) {
            matchingEntryArray.Push(configEntry)
        }
        /*
        Tries to find the entry using only the key name.
        This only works when every key has a unique name which should usually be the case.
        */
        else if (!IsSet(pSection) && configEntry.key == pKey) {
            matchingEntryArray.Push(configEntry)
        }
    }

    if (matchingEntryArray.Length == 1) {
        ; Edits the value of the config file entry.
        matchingEntryArray.Get(1).changeValue(pNewValue)
    }
    else if (matchingEntryArray.Length == 0) {
        msgText := "There was a problem while editing the config file."
        msgText .= "`n********************"
        if (IsSet(pSection)) {
            msgText .= "`nThe following section [" . pSection . "] and key [" . pKey . "] could not be found."
        }
        else {
            msgText .= "`nThe following key [" . pKey . "] could not be found."
        }
        msgText .= "`n********************"
        msgText .= "`n`nYou could try to reset the config file at [" . configFileLocation . "]."
        msgText .= "`n********************"
        msgText .= "`nIt is recommended to exit the program."
        msgText .= "`n`nContinue at your own risk."
        msgTitle := "VD - Config File Editing Error"
        msgHeadLine := "Config File Editing Error"
        msgButton1 := "Continue"
        msgButton2 := ""
        msgButton3 := "Exit"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)
        if (result != msgButton1) {
            exitScriptWithNotification(true)
        }
    }
    else {
        msgText := "There was a problem while editing the config file."
        msgText .= "`n********************"
        msgText .= "`nThe following key [" . pKey . "] is duplicate in the config file."
        msgText .= "`n********************"
        msgText .= "`n`nYou could try to reset the config file at [" . configFileLocation . "]."
        msgText .= "`n********************"
        msgText .= "`nIt is recommended to exit the program."
        msgText .= "`n`nContinue at your own risk."
        msgTitle := "VD - Config File Editing Error"
        msgHeadLine := "Config File Editing Error"
        msgButton1 := "Continue"
        msgButton2 := ""
        msgButton3 := "Exit"
        result := customMsgBox(msgText, msgTitle, msgHeadLine, msgButton1, msgButton2, msgButton3, , true)
        if (result != msgButton1) {
            exitScriptWithNotification(true)
        }
    }
}

class ConfigFileEntry {
    __New(pValue, pKey, pSection, pDefaultValue := pValue, pValueType := "string") {
        global configFileLocation

        ; Used to determine input errors while creating new config file entries.
        allowedValueTypesArray := ["string", "directory", "filepath", "boolean", "hotkey"]
        if (!checkIfStringIsInArray(pValueType, allowedValueTypesArray)) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid value type received: [" . pValueType . "].",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            exitScriptWithNotification(true)
        }

        /*
        This map stores all config file entry objects with their identifier string as key.
        It is used to provide the content for the config file and to easily access each object.
        */
        if (!isSet(configFileEntryMap)) {
            global configFileEntryMap := Map()
        }
        this.section := pSection
        this.key := pKey
        this.value := pValue
        this.defaultValue := pDefaultValue
        this.valueType := pValueType
        this.configFileLocation := configFileLocation
        ; Used to give each entry a unique ID.
        this.identifierString := this.key . this.section
        this.addEntryToMap()
    }
    ; Writes the current value to the config file.
    writeToFile() {
        try
        {
            IniWrite(this.value, this.configFileLocation, this.section, this.key)
        }
        catch as error {
            displayErrorMessage(error, "Please be sure that you have read and write permissions for this file"
                "`n[" . this.configFileLocation . "]`nbefore submitting an issue. Thank you!")
        }
    }
    /*
    Reads the config file entry's value from the config file.
    @Returns [String] The value from the config file.
    @Returns (alt) [String] The error code "_error_config_file_could_not_be_read" in case the file cannot be read.
    */
    readFromFile() {
        try
        {
            return IniRead(this.configFileLocation, this.section, this.key)
        }
        catch as error {
            displayErrorMessage(error, "Please be sure that you have read and write permissions for this file"
                "`n[" . this.configFileLocation . "]`nbefore submitting an issue. Thank you!")
            return "_error_config_file_could_not_be_read"
        }
    }
    ; Deletes the config file entry's value and key from the config file.
    deleteFromFile() {
        try
        {
            IniDelete(this.configFileLocation, this.section, this.key)
        }
        catch as error {
            displayErrorMessage(error, "Please be sure that you have read and write permissions for this file"
                "`n[" . this.configFileLocation . "]`nbefore submitting an issue. Thank you!")
        }
    }
    /*
    Changes the current value of the config file entry.
    @param pBooleanWriteToFileAfterwards [boolean] If set to true, the changes will be written to the config file.
    */
    changeValue(pNewValue, pBooleanWriteToFileAfterwards := true) {
        this.value := pNewValue
        if (pBooleanWriteToFileAfterwards) {
            this.writeToFile()
        }
    }
    /*
    Resets the config file entry's value to the default value.
    @param pBooleanWriteToFileAfterwards [boolean] If set to true, the changes will be written to the config file.
    */
    resetValue(pBooleanWriteToFileAfterwards := true) {
        this.value := this.defaultValue
        if (pBooleanWriteToFileAfterwards) {
            this.writeToFile()
        }
    }
    ; SHOULD be called when the values of this.section or this.key are changed externally.
    rebuildIdentifierString() {
        this.removeEntryFromMap()
        this.identifierString := this.key . this.section
        this.addEntryToMap()
    }
    ; Adds the object to the config file entry map.
    addEntryToMap() {
        global configFileEntryMap
        ; Used to determine input errors while creating new config file entries.
        if (configFileEntryMap.Has(this.identifierString)) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Entry with identifier string [" . this.identifierString .
                "] already exists.", "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            exitScriptWithNotification(true)
        }
        configFileEntryMap.Set(this.identifierString, this)
    }
    ; Removes the object from the config file entry map.
    removeEntryFromMap() {
        global configFileEntryMap
        if (configFileEntryMap.Has(this.identifierString)) {
            configFileEntryMap.Delete(this.identifierString)
        }
    }
}
