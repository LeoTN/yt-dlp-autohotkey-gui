#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

createMainGUI()
{
    Global
    fileSelectionMenuOpen := Menu()
    fileSelectionMenuOpen.Add("URL-File`tF2", (*) => openURLFile())
    fileSelectionMenuOpen.SetIcon("URL-File`tF2", "shell32.dll", 104)
    fileSelectionMenuOpen.Add("URL-Backup-File`tShift+F2", (*) => openURLBackupFile())
    fileSelectionMenuOpen.SetIcon("URL-Backup-File`tShift+F2", "shell32.dll", 46)
    fileSelectionMenuOpen.Add("URL-Blacklist-File`tCTRL+F2", (*) => openURLBlacklistFile())
    fileSelectionMenuOpen.SetIcon("URL-Blacklist-File`tCTRL+F2", "shell32.dll", 110)
    fileSelectionMenuOpen.Add("Config-File`tAlt+F2", (*) => openConfigFile())
    fileSelectionMenuOpen.SetIcon("Config-File`tAlt+F2", "shell32.dll", 70)
    fileSelectionMenuOpen.Add("Download destination", (*) => handleMainGUI_openDownloadLocation())
    fileSelectionMenuOpen.SetIcon("Download destination", "shell32.dll", 116)

    fileSelectionMenuDelete := Menu()
    fileSelectionMenuDelete.Add("URL-File", (*) => deleteFilePrompt("URL-File"))
    fileSelectionMenuDelete.SetIcon("URL-File", "shell32.dll", 104)
    fileSelectionMenuDelete.Add("URL-Backup-File", (*) => deleteFilePrompt("URL-Backup-File"))
    fileSelectionMenuDelete.SetIcon("URL-Backup-File", "shell32.dll", 46)
    fileSelectionMenuDelete.Add("URL-Blacklist-File", (*) => deleteFilePrompt("URL-Blacklist-File"))
    fileSelectionMenuDelete.SetIcon("URL-Blacklist-File", "shell32.dll", 110)
    fileSelectionMenuDelete.Add("Latest download", (*) => deleteFilePrompt("latest download"))
    fileSelectionMenuDelete.SetIcon("Latest download", "shell32.dll", 116)

    fileSelectionMenuReset := Menu()
    fileSelectionMenuReset.Add("URL-Blacklist-File", (*) => openURLBlacklistFile(true))
    fileSelectionMenuReset.SetIcon("URL-Blacklist-File", "shell32.dll", 110)
    fileSelectionMenuReset.Add("Config-File", (*) => createDefaultConfigFile(, true))
    fileSelectionMenuReset.SetIcon("Config-File", "shell32.dll", 70)

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

    activeHotkeyMenu.Add("Currently not used → " . expandHotkey(readConfigFile("NOT_USED_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Currently not used → " .
            expandHotkey(readConfigFile("NOT_USED_HK")), 3), "+Radio")

    activeHotkeyMenu.Add("Start Download → " . expandHotkey(readConfigFile("DOWNLOAD_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Start Download → " .
            expandHotkey(readConfigFile("DOWNLOAD_HK")), 4), "+Radio")

    activeHotkeyMenu.Add("Collect URL Searchbar → " . expandHotkey(readConfigFile("URL_COLLECT_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Collect URL Searchbar → " .
            expandHotkey(readConfigFile("URL_COLLECT_HK")), 5), "+Radio")

    activeHotkeyMenu.Add("Collect URL Thumbnail → " . expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Collect URL Thumbnail → " .
            expandHotkey(readConfigFile("THUMBNAIL_URL_COLLECT_HK")), 6), "+Radio")

    activeHotkeyMenu.Add("Clear URL File → " . expandHotkey(readConfigFile("CLEAR_URL_FILE_HK")),
        (*) => handleMainGUI_ToggleCheck("activeHotkeyMenu", "Clear URL File → " .
            expandHotkey(readConfigFile("CLEAR_URL_FILE_HK")), 7), "+Radio")

    activeHotkeyMenu.Add()
    activeHotkeyMenu.Add("Enable All", (*) => handleMainGUI_MenuCheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Enable All", "shell32.dll", 297)
    activeHotkeyMenu.Add("Disable All", (*) => handleMainGUI_MenuUncheckAll("activeHotkeyMenu"))
    activeHotkeyMenu.SetIcon("Disable All", "shell32.dll", 132)

    optionsMenu := Menu()
    optionsMenu.Add("&Active Hotkeys...", activeHotkeyMenu)
    optionsMenu.SetIcon("&Active Hotkeys...", "shell32.dll", 177)
    optionsMenu.Add()
    optionsMenu.Add("Clear URL File", (*) => manageURLFile())
    optionsMenu.SetIcon("Clear URL File", "shell32.dll", 43)
    optionsMenu.Add("Restore URL File from Backup", (*) => restoreURLFile())
    optionsMenu.SetIcon("Restore URL File from Backup", "shell32.dll", 240)
    optionsMenu.Add("Open Download Options GUI", (*) => Hotkey_openOptionsGUI())
    optionsMenu.SetIcon("Open Download Options GUI", "shell32.dll", 123)
    optionsMenu.Add("Terminate Script", (*) => terminateScriptPrompt())
    optionsMenu.SetIcon("Terminate Script", "shell32.dll", 28)
    optionsMenu.Add("Reload Script", (*) => reloadScriptPrompt())
    optionsMenu.SetIcon("Reload Script", "shell32.dll", 207)
    optionsMenu.Add()
    optionsMenu.Add("Uninstall script", (*) => handleMainGUI_uninstallScript())
    optionsMenu.SetIcon("Uninstall script", "shell32.dll", 245)

    helpMenu := Menu()
    helpMenu.Add("This repository (yt-dlp-autohotkey-gui)",
        (*) => Run("https://github.com/LeoTN/yt-dlp-autohotkey-gui#readme"))
    helpMenu.Add("Used repository (yt-dlp)", (*) => Run("https://github.com/yt-dlp/yt-dlp"))
    helpMenu.Add("Original repository (youtube-downloader-using-ahk)",
        (*) => Run("https://github.com/LeoTN/youtube-downloader-using-ahk"))
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
    Try
    {
        mainGUI.Add("Picture", "w320 h-1 x-10 y-10", youTubeBackGroundLocation)
    }
    mainGUI.MenuBar := allMenus
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit()
{
    createMainGUI()
    handleMainGUI_ApplyCheckmarksFromConfigFile("activeHotkeyMenu")
}

; Necessary in place for the normal way of toggeling the checkmark.
; This function also flips the checkMarkArrays values to keep track of the checkmarks.
handleMainGUI_ToggleCheck(pMenuName, pMenuItemName, pMenuItemPosition)
{
    menuName := pMenuName
    menuItemName := pMenuItemName
    menuItemPosition := pMenuItemPosition

    ; Executes the command so that the checkmark becomes visible for the user.
    %menuName%.ToggleCheck(menuItemName)
    ; Registers the change in the matching array.
    handleMainGUI_MenuCheckHandler(menuName, menuItemPosition, "toggle")
}

handleMainGUI_MenuCheckAll(pMenuName)
{
    menuName := pMenuName
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %menuName%.Handle)
    Loop (MenuItemCount - 2)
    {
        %menuName%.Check(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        Try
        {
            handleMainGUI_MenuCheckHandler(menuName, A_Index, true)
        }
    }
}

handleMainGUI_MenuUncheckAll(pMenuName)
{
    menuName := pMenuName
    menuItemCount := DllCall("GetMenuItemCount", "ptr", %menuName%.Handle)
    Loop (MenuItemCount - 2)
    {
        %menuName%.Uncheck(A_Index . "&")
        ; Protects the code from the invalid index error caused by the check array further on.
        Try
        {
            handleMainGUI_MenuCheckHandler(menuName, A_Index, false)
        }
    }
}

; This function stores all menu items check states. In other words
; if there is a checkmark next to an option.
; The parameter menuName defines which menu's submenus will be changed.
; Enter "toggle" as pBooleanState to toggle a menu option's boolean value.
; Leave only booleanState ommited to receive the current value of a submenu item or
; every parameter to receive the complete array.
handleMainGUI_MenuCheckHandler(pMenuName := unset, pSubMenuPosition := unset, pBooleanState := unset)
{
    menuCheckArray_activeHotKeyMenu := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))
    Try
    {
        menuName := pMenuName
        subMenuPosition := pSubMenuPosition
    }
    Catch
    {
        Return menuCheckArray_activeHotKeyMenu
    }
    Try
    {
        booleanState := pBooleanState

        If (menuName = "activeHotkeyMenu")
        {
            If (booleanState = "toggle")
            {
                ; Toggles the boolean value at a specific position.
                menuCheckArray_activeHotKeyMenu[subMenuPosition] := !menuCheckArray_activeHotKeyMenu[subMenuPosition]
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            ; Only if there is a state given to apply to a menu.
            Else If (booleanState = true || booleanState = false)
            {
                menuCheckArray_activeHotKeyMenu[subMenuPosition] := booleanState
                editConfigFile("HOTKEY_STATE_ARRAY", menuCheckArray_activeHotKeyMenu)
            }
            Else
            {
                Return menuCheckArray_activeHotKeyMenu[subMenuPosition]
            }
            toggleHotkey(menuCheckArray_activeHotKeyMenu)
        }
    }
}

; Applies the checkmarks stored in the config file so that they become visible to the user in the GUI.
handleMainGUI_ApplyCheckmarksFromConfigFile(pMenuName)
{
    menuName := pMenuName
    stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))

    If (menuName = "activeHotkeyMenu")
    {
        Loop (stateArray.Length)
        {
            If (stateArray.Get(A_Index) = true)
            {
                activeHotkeyMenu.Check(A_Index . "&")
            }
            Else If (stateArray.Get(A_Index) = false)
            {
                activeHotkeyMenu.Uncheck(A_Index . "&")
            }
            Else
            {
                Throw ("No valid state in state array.")
            }
        }
        stateArray := stringToArray(readConfigFile("HOTKEY_STATE_ARRAY"))
        toggleHotkey(stateArray)
    }
}

handleMainGUI_openDownloadLocation()
{
    Try
    {
        Switch (useDefaultDownloadLocationCheckbox.Value)
        {
            Case 0:
            {
                Run(customDownloadLocationEdit.Value)
            }
            Case 1:
            {
                Run(readConfigFile("DOWNLOAD_PATH"))
            }
        }
    }
    Catch
    {
        MsgBox("No downloaded files from`ncurrent session found.", "Warning !", "O Icon! T1.5")
    }
}

handleMainGUI_uninstallScript()
{
    tmpPath := scriptBaseFilesLocation . "\library\setup\uninstall_shortcut.lnk"
    If (FileExist(tmpPath))
    {
        Try
        {
            Run(tmpPath)
        }
    }
    Else
    {
        MsgBox("Could not find the uninstall shortcut folder in [" . tmpPath . "].`n`n"
            "Please repair the installation with the .MSI installer or remove this script by using the windows program "
            . "management option.", "VideoDownloader Uninstall Status", "O Icon!")
    }
}