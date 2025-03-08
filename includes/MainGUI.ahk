#SingleInstance Force
#MaxThreadsPerHotkey 2
#Warn Unreachable, Off
SendMode "Input"
CoordMode "Mouse", "Client"

createMainGUI() {
    global

    mainGUI := Gui(, "VD - Control Panel")
    try
    {
        mainGUI.Add("Picture", "w320 h-1 x-10 y-10 Center", mainGUIBackGroundLocation)
    }
}

/*
GUI SUPPORT FUNCTIONS
-------------------------------------------------
*/

; Runs a few commands when the script is executed.
mainGUI_onInit() {
    createMainGUI()
    ; handleMainGUI_ApplyCheckmarksFromConfigFile("activeHotkeyMenu")
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
