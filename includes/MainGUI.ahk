#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

createMainGUI() {
    global
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add("URL-File`t1", (*) => openURLFile())
    fileSelectionMenuOpen.SetIcon("URL-File`t1", "shell32.dll", 104)
    fileSelectionMenuOpen.Add("URL-Backup-File`t2", (*) => openURLBackupFile())
    fileSelectionMenuOpen.SetIcon("URL-Backup-File`t2", "shell32.dll", 46)
    fileSelectionMenuOpen.Add("URL-Blacklist-File`t3", (*) => openURLBlacklistFile())
    fileSelectionMenuOpen.SetIcon("URL-Blacklist-File`t3", "shell32.dll", 110)
    fileSelectionMenuOpen.Add("Config-File`t4", (*) => openConfigFile())
    fileSelectionMenuOpen.SetIcon("Config-File`t4", "shell32.dll", 70)
    fileSelectionMenuOpen.Add("Download destination`t5", (*) => handleMainGUI_openDownloadLocation())
    fileSelectionMenuOpen.SetIcon("Download destination`t5", "shell32.dll", 116)

    fileSelectionMenuDelete := Menu()
    fileSelectionMenuDelete.Add("URL-File`tShift+1", (*) => deleteFilePrompt("URL-File"))
    fileSelectionMenuDelete.SetIcon("URL-File`tShift+1", "shell32.dll", 104)
    fileSelectionMenuDelete.Add("URL-Backup-File`tShift+2", (*) => deleteFilePrompt("URL-Backup-File"))
    fileSelectionMenuDelete.SetIcon("URL-Backup-File`tShift+2", "shell32.dll", 46)
    fileSelectionMenuDelete.Add("Latest download`tShift+5", (*) => deleteFilePrompt("latest download"))
    fileSelectionMenuDelete.SetIcon("Latest download`tShift+5", "shell32.dll", 116)

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add("URL-Blacklist-File`tShift+3", (*) => openURLBlacklistFile(true))
    fileSelectionMenuReset.SetIcon("URL-Blacklist-File`tShift+3", "shell32.dll", 110)
    fileSelectionMenuReset.Add("Config-File`tShift+4", (*) => createDefaultConfigFile(, true))
    fileSelectionMenuReset.SetIcon("Config-File`tShift+4", "shell32.dll", 70)

    fileMenu := Menu()
    fileMenu.Add("&Open...", fileSelectionMenuOpen)
    fileMenu.SetIcon("&Open...", "shell32.dll", 127)
    fileMenu.Add("&Delete...", fileSelectionMenuDelete)
    fileMenu.SetIcon("&Delete...", "shell32.dll", 32)
    fileMenu.Add("&Reset...", fileSelectionMenuReset)
    fileMenu.SetIcon("&Reset...", "shell32.dll", 239)

    activeHotkeyMenu := Menu()
    activeHotkeyMenu.Add("Terminate Script → " . expandHotkey(readConfigFile("TERMINATE_SCRIPT_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Terminate Script → " .
        expandHotkey(readConfigFile("TERMINATE_SCRIPT_HK")), 1), "+Radio")

    activeHotkeyMenu.Add("Reload Script → " . expandHotkey(readConfigFile("RELOAD_SCRIPT_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Reload Script → " .
        expandHotkey(readConfigFile("RELOAD_SCRIPT_HK")), 2), "+Radio")

    activeHotkeyMenu.Add("Start Download → " . expandHotkey(readConfigFile("DOWNLOAD_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Start Download → " .
        expandHotkey(readConfigFile("DOWNLOAD_HK")), 3), "+Radio")

    activeHotkeyMenu.Add("Collect URL Searchbar → " . expandHotkey(readConfigFile("URL_COLLECT_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Collect URL Searchbar → " .
        expandHotkey(readConfigFile("URL_COLLECT_HK")), 4), "+Radio")

    activeHotkeyMenu.Add("Collect URL Thumbnail → " . expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Collect URL Thumbnail → " .
        expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")), 5), "+Radio")

    activeHotkeyMenu.Add("Clear URL File → " . expandHotkey(readConfigFile("CLEAR_URL_FILE_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Clear URL File → " .
        expandHotkey(readConfigFile("CLEAR_URL_FILE_HK")), 6), "+Radio")

    activeHotkeyMenu.Add("Restore URL File → " . expandHotkey(readConfigFile("RESTORE_URL_FILE_HK")),
    (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Restore URL File → " .
        expandHotkey(readConfigFile("RESTORE_URL_FILE_HK")), 7), "+Radio")

    activeHotkeyMenu.Add()
    activeHotkeyMenu.Add("Enable All", (*) => handleMainGUI_MenuCheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Enable All", "shell32.dll", 297)
    activeHotkeyMenu.Add("Disable All", (*) => handleMainGUI_MenuUncheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Disable All", "shell32.dll", 132)

    optionsMenu := Menu()
    optionsMenu.Add("&Active Hotkeys...", activeHotkeyMenu)
    optionsMenu.SetIcon("&Active Hotkeys...", "shell32.dll", 177)
    optionsMenu.Add()
    optionsMenu.Add("Clear URL File", (*) => clearURLFile())
    optionsMenu.SetIcon("Clear URL File", "shell32.dll", 43)
    optionsMenu.Add("Restore URL File from Backup", (*) => restoreURLFile())
    optionsMenu.SetIcon("Restore URL File from Backup", "shell32.dll", 240)
    optionsMenu.Add("Open Download Options GUI", (*) => hotkey_openOptionsGUI())
    optionsMenu.SetIcon("Open Download Options GUI", "shell32.dll", 123)
    optionsMenu.Add("Terminate Script", (*) => terminateScriptPrompt())
    optionsMenu.SetIcon("Terminate Script", "shell32.dll", 28)
    optionsMenu.Add("Reload Script", (*) => reloadScriptPrompt())
    optionsMenu.SetIcon("Reload Script", "shell32.dll", 207)
    optionsMenu.Add()
    optionsMenu.Add("Uninstall script", (*) => handleMainGUI_uninstallScript())
    optionsMenu.SetIcon("Uninstall script", "shell32.dll", 245)
    optionsMenu.Add("Repair script", (*) => handleMainGUI_repairScript())
    optionsMenu.SetIcon("Repair script", "shell32.dll", 41)

    helpMenu := Menu()
    helpMenu.Add("Version - " . versionFullName, (*) => handleMainGUI_helpSectionEasterEgg())
    helpMenu.SetIcon("Version - " . versionFullName, "shell32.dll", 79)
    helpMenu.Add("This repository (yt-dlp-autohotkey-gui)",
        (*) => Run("https://github.com/LeoTN/yt-dlp-autohotkey-gui#readme"))
    helpMenu.SetIcon("This repository (yt-dlp-autohotkey-gui)", "shell32.dll", 26)
    helpMenu.Add("Used repository (yt-dlp)",
        (*) => Run("https://github.com/yt-dlp/yt-dlp"))
    helpMenu.SetIcon("Used repository (yt-dlp)", "shell32.dll", 26)
    helpMenu.Add("Original repository (youtube-downloader-using-ahk)",
        (*) => Run("https://github.com/LeoTN/youtube-downloader-using-ahk"))
    helpMenu.SetIcon("Original repository (youtube-downloader-using-ahk)", "shell32.dll", 26)
    helpMenu.Add("Built in Tutorial", (*) => scriptTutorial())
    helpMenu.SetIcon("Built in Tutorial", "shell32.dll", 24)

    allMenus := MenuBar()
    allMenus.Add("&File", fileMenu)
    allMenus.SetIcon("&File", "shell32.dll", 4)
    allMenus.Add("&Options", optionsMenu)
    allMenus.SetIcon("&Options", "shell32.dll", 317)
    allMenus.Add("&Info", helpMenu)
    allMenus.SetIcon("&Info", "shell32.dll", 24)

    mainGUI := Gui(, "VD - Control Panel")
    try
    {
        mainGUI.Add("Picture", "w320 h-1 x-10 y-10 Center", mainGUIBackGroundLocation)
    }
    mainGUI.MenuBar := allMenus
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit() {
    createMainGUI()
    handleMainGUI_ApplyCheckmarksFromConfigFile("activeHotkeyMenu")
}

/*
Necessary in place for the normal way of toggeling the checkmark.
This function also flips the checkMarkArrays values to keep track of the checkmarks.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
@param pMenuItemName [String] Should be a valid menu item name from the menu mentioned above.
@param pMenuItemPosition [int] Should be a valid menu item position. See AHK help for more info about this topic.
*/
handleMainGUI_ToggleCheck(pMenuName, pMenuItemName, pMenuItemPosition) {
    ; Executes the command so that the checkmark becomes visible for the user.
    %pMenuName%.ToggleCheck(pMenuItemName)
    ; Registers the change in the matching array.
    handleMainGUI_MenuCheckHandler(pMenuName, pMenuItemPosition, "toggle")
}

/*
Checks all menu options from the (most likely) hotkey menu.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_MenuCheckAll(pMenuName) {
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %pMenuName%.Handle)

    loop (MenuItemCount - 3) {
        %pMenuName%.Check(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        try
        {
            handleMainGUI_MenuCheckHandler(pMenuName, A_Index, true)
        }
    }
}

/*
Unchecks all menu options from the (most likely) hotkey menu.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_MenuUncheckAll(pMenuName) {
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %pMenuName%.Handle)

    loop (MenuItemCount - 3) {
        %pMenuName%.Uncheck(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        try
        {
            handleMainGUI_MenuCheckHandler(pMenuName, A_Index, true)
        }
    }
}

/*
This function stores all menu items check states. In other words if there is a checkmark next to an option.
Leave only pBooleanState ommited to receive the current value of a submenu item or every parameter to receive the complete array.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
@param pSubMenuPosition [int] Should be the position of a sub menu element from the main menu mentioned above.
@param pBooleanState [boolean] / [String] Defines the state of the checkmarks to set. Pass "toggle" to invert the checkmark's
current state.
*/
handleMainGUI_MenuCheckHandler(pMenuName := unset, pSubMenuPosition := unset, pBooleanState := unset) {
    menuCheckArray_activeHotKeyMenu := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))

    ; Returns the menu check array if those parameters are omitted.
    if (!IsSet(pMenuName) || !isSet(pSubMenuPosition)) {
        return menuCheckArray_activeHotKeyMenu
    }
    try
    {
        if (pMenuName = "activeHotkeyMenu") {
            if (pBooleanState = "toggle") {
                ; Toggles the boolean value at a specific position.
                menuCheckArray_activeHotKeyMenu[pSubMenuPosition] := !menuCheckArray_activeHotKeyMenu[pSubMenuPosition]
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            ; Only if there is a state given to apply to a menu.
            else if (pBooleanState || !pBooleanState) {
                menuCheckArray_activeHotKeyMenu[pSubMenuPosition] := pBooleanState
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            else {
                return menuCheckArray_activeHotKeyMenu[pSubMenuPosition]
            }
            toggleHotkey(menuCheckArray_activeHotKeyMenu)
        }
    }
    catch as error {
        displayErrorMessage(error)
    }
}

/*
Applies the checkmarks stored in the config file so that they become visible to the user in the GUI.
@param pMenuName [String] Should be a valid menu name for example "activeHotkeyMenu".
*/
handleMainGUI_ApplyCheckmarksFromConfigFile(pMenuName) {
    stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))

    if (pMenuName = "activeHotkeyMenu") {
        loop (stateArray.Length) {
            if (stateArray.Get(A_Index)) {
                activeHotkeyMenu.Check(A_Index . "&")
            }
            else if (!stateArray.Get(A_Index)) {
                activeHotkeyMenu.Uncheck(A_Index . "&")
            }
            else {
                throw ("No valid state in state array.")
            }
        }
        stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))
        toggleHotkey(stateArray)
    }
}

; Opens the explorer.
handleMainGUI_openDownloadLocation() {
    try
    {
        switch (useDefaultDownloadLocationCheckbox.Value) {
            case 0:
            {
                Run(customDownloadLocationEdit.Value)
            }
            case 1:
            {
                Run(readConfigFile("DOWNLOAD_PATH"))
            }
        }
    }
    catch as error {
        displayErrorMessage(error)
    }
}

handleMainGUI_helpSectionEasterEgg() {
    static i := 0

    i++
    if (i >= 3) {
        i := 0
        MsgBox("Looks like some found an easter egg!`n`nIt seems you like testing, just like my friend,"
            . " who helps me a lot by testing this script for me.`n`nThank you Elias!", "What's that?", "Iconi")
    }
}

handleMainGUI_uninstallScript() {
    videoDownloaderSetupExecutableLocation := scriptMainDirectory . "\library\setup\VideoDownloader-Setup.exe"

    if (!A_IsCompiled) {
        MsgBox("You are using a non compiled version of this script."
            "`n`nYou cannot uninstall VideoDownloader now.", "VD - Uninstall VideoDownloader - Error!",
            "O IconX 262144 T10")
        return
    }

    result := MsgBox("Uninstall VideoDownloader now?", "VD - Uninstall VideoDownloader", "YN Icon? 262144")
    switch (result) {
        case "Yes":
        {
            if (FileExist(videoDownloaderSetupExecutableLocation)) {
                Run(videoDownloaderSetupExecutableLocation . ' -deploymentType "Uninstall"')
            }
            else {
                MsgBox("Unable to find setup executable at`n[" . videoDownloaderSetupExecutableLocation
                    . "].", "VD - Uninstall VideoDownloader - Error!", "O Icon! 262144")
            }
        }
    }
}

/*
Runs the script setup to repair the application.
@param pBooleanAllowRefuse [boolean] If set to true, the user can cancel the setup and run the script anyway.
*/
handleMainGUI_repairScript(pBooleanAllowRefuse := true) {
    videoDownloaderSetupExecutableLocation := scriptMainDirectory . "\library\setup\VideoDownloader-Setup.exe"

    if (!A_IsCompiled) {
        MsgBox("You are using a non compiled version of this script."
            "`n`nYou cannot repair VideoDownloader now.", "VD - Execute Repair Action - Error!", "O IconX 262144 T10")
        if (pBooleanAllowRefuse) {
            return
        }
        ExitApp()
    }

    if (pBooleanAllowRefuse) {
        result := MsgBox("Repair VideoDownloader now?", "VD - Execute Repair Action", "YN Icon? 262144")
        switch (result) {
            case "Yes":
            {
                if (FileExist(videoDownloaderSetupExecutableLocation)) {
                    Run(videoDownloaderSetupExecutableLocation . ' -deploymentType "Repair"')
                }
                else {
                    MsgBox("Unable to find setup executable at`n[" . videoDownloaderSetupExecutableLocation
                        . "]`nScript terminated.", "VD - Execute Repair Action - Error!", "O Icon! 262144")
                }
                ExitApp()
            }
        }
    }
    else {
        result := MsgBox("Repair VideoDownloader now?", "VD - Repair Action Required!", "YN Icon? 262144")
        switch (result) {
            case "Yes":
            {
                if (FileExist(videoDownloaderSetupExecutableLocation)) {
                    Run(videoDownloaderSetupExecutableLocation . ' -deploymentType "Repair"')
                }
                else {
                    MsgBox("Unable to find setup executable at`n[" . videoDownloaderSetupExecutableLocation
                        . "]`nScript terminated.", "VD - Repair Action Required! - Error!", "O Icon! 262144")
                }
            }
            Default:
            {
                MsgBox("You can repair VideoDownloader at any time.`nScript terminated.",
                    "VD - Repair Action Required! - Canceled", "O Iconi T5")
            }
        }
        ExitApp()
    }
}
