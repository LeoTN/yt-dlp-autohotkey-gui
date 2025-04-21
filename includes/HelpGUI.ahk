#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

helpGUI_onInit() {
    createHelpGUI()
}

createHelpGUI() {
    global
    helpGUI := Gui(, "VideoDownloader - Info & Help")

    /*
    ********************************************************************************************************************
    This section creates all the GUI control elements and event handlers.
    ********************************************************************************************************************
    */
    helpGUISearchBarText := helpGUI.Add("Text", , "Search the Help List")
    helpGUISearchBarEdit := helpGUI.Add("Edit", "w150 -WantReturn")
    helpGUISearchBarEdit.OnEvent("Change", handleHelpGUI_helpGUISearchBarEdit_onChange)
    helpGUISearchBarEdit.OnEvent("Focus", handleHelpGUI_helpGUISearchBaredit_onFocus)

    helpGUIListViewArray := Array("Topic", "Type", "Title")
    helpGUIListView := helpGUI.Add("ListView", "yp+40 w400 R10 +Grid -Multi", helpGUIListViewArray)
    helpGUIListView.OnEvent("DoubleClick", handleHelpGUI_helpGUIListView_onDoubleClick)

    helpGUIInfoGroupBox := helpGUI.Add("GroupBox", "xp+170 yp-65 w230 R2", "Application Info")

    local currentVersionLink := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/" . versionFullName
    local currentVersionString := 'Version: <a href="' . currentVersionLink . '">' . versionFullName . '</a>'
    helpGUIApplicationtVersionLink := helpGUI.Add("Link", "xp+10 yp+18", currentVersionString)
    helpGUIApplicationtVersionLink.ToolTip :=
        "Made by LeoTN (https://github.com/LeoTN). © 2025. Licensed under the MIT License."

    ; These links need to be changed when renaming the .YML files for the GitHub issues section.
    local featureRequestLink :=
        "https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues/new?assignees=&labels=enhancement&projects=&template=feature-request.yml&title=Feature+Request"
    local bugReportLink :=
        "https://github.com/LeoTN/yt-dlp-autohotkey-gui/issues/new?assignees=&labels=bug&projects=&template=bug-report.yml&title=Bug+Report"
    local featureAndBugSubmitString := '<a href="' . featureRequestLink . '">Feature Request</a> or <a href="' .
        bugReportLink . '">Bug Report</a>'
    helpGUIFeatureAndBugSubmitLink := helpGUI.Add("Link", "yp+20", featureAndBugSubmitString)

    helpGUIStatusBar := helpGUI.Add("StatusBar", , "Double click an entry to access it's content.")
    helpGUIStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    ; This is used for the easter egg.
    helpGUIStatusBar.OnEvent("Click", handleHelpGUI_helpGUIStatusBar_onClick)
}

handleHelpGUI_helpGUISearchBarEdit_onChange(pEdit, pInfo) {
    global interactiveTutorialEntryMap

    searchString := pEdit.Value
    helpGUIListView.Delete()
    ; Shows all data when the search bar is empty.
    if (searchString == "") {
        for (key, tutorialEntry in interactiveTutorialEntryMap) {
            addInteractiveTutorialListViewEntryToListView(tutorialEntry)
        }
        return
    }

    ; Calls the search function to search in all entries.
    resultArray := searchInHelpListView(searchString)
    for (resultEntry in resultArray) {
        addInteractiveTutorialListViewEntryToListView(resultEntry)
    }
    else {
        /*
        The addInteractiveTutorialListViewEntryToListView() function does not care if the object is a real
        InteractiveTutorialListViewEntry object. Using a real object would cause a lot of unnecessary other issues.
        */
        noEntriesHelpListEntry := Object()
        noEntriesHelpListEntry.topic := "*****"
        noEntriesHelpListEntry.type := "No results found."
        noEntriesHelpListEntry.title := "*****"
        addInteractiveTutorialListViewEntryToListView(noEntriesHelpListEntry)
    }
}

handleHelpGUI_helpGUISearchBaredit_onFocus(pEdit, pInfo) {
    ; Selects the text inside the edit once the user clicks on it again after loosing focus.
    ControlSend("^A", pEdit)
}

handleHelpGUI_helpGUIListView_onDoubleClick(pListView, pSelectedElementIndex) {
    global interactiveTutorialEntryMap

    ; This means the user double clicked on the empty space.
    if (pSelectedElementIndex == 0) {
        return
    }
    ; The identifier string is created by merging the topic, the type and the title.
    entryTopic := helpGUIListView.GetText(pSelectedElementIndex, 1)
    entryType := helpGUIListView.GetText(pSelectedElementIndex, 2)
    entryTitle := helpGUIListView.GetText(pSelectedElementIndex, 3)
    focusedEntryIdentifierString := entryTopic . entryType . entryTitle

    doubleClickedInteractiveTutorialListViewEntry := interactiveTutorialEntryMap.Get(focusedEntryIdentifierString)
    ; Closes the help window.
    if (WinExist("ahk_id " . helpGUI.Hwnd)) {
        WinClose()
    }
    ; Starts the tutorial or information dialogue.
    doubleClickedInteractiveTutorialListViewEntry.start()
}

/*
Allows to search for elements in the help list view element.
@param pSearchString [String] A string to search for.
@returns [Array] This array contains all InteractiveTutorialListViewEntry objects matching the search string.
*/
searchInHelpListView(pSearchString) {
    global interactiveTutorialEntryMap

    resultArrayCollection := Array()
    ; Iterates through all help list view elements.
    for (key, tutorialEntry in interactiveTutorialEntryMap) {
        ; Search in the topic.
        if (InStr(tutorialEntry.topic, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(tutorialEntry)
        }
        ; Search in the type.
        else if (InStr(tutorialEntry.type, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(tutorialEntry)
        }
        ; Search in the title.
        else if (InStr(tutorialEntry.title, pSearchString)) {
            ; Add the entry to the result array.
            resultArrayCollection.Push(tutorialEntry)
        }
    }
    return resultArrayCollection
}

/*
Adds a interactive tutorial list view entry object to the help list view.
@param pInteractiveTutorialListViewEntry [InteractiveTutorialListViewEntry] The interactive tutorial object to add.
*/
addInteractiveTutorialListViewEntryToListView(pInteractiveTutorialListViewEntry) {
    helpGUIListView.Add("", pInteractiveTutorialListViewEntry.topic, pInteractiveTutorialListViewEntry.type,
        pInteractiveTutorialListViewEntry.title)
    ; Adjust the width accordingly to the content.
    loop (helpGUIListView.GetCount()) {
        helpGUIListView.ModifyCol(A_Index, "AutoHdr")
    }
}

/*
Highlights a control with a colored border.
@param pControlElement [controlElement] Should be a control element (like a button or a checkbox) created within an AutoHotkey GUI.
@param pColor [String] Determines the color of the border.
@param pLineeThickness [int] Defines how thin the border is (in pixels).
@param pLineTransparicy [int] Should be a value between 0 and 255. 0 makes the border invisible and 255 makes it entirely visible.
@returns [RectangleHollowBox] This object can be used to control the border and it's properties.
*/
highlightControl(pControlElement, pColor := "red", pLineThickness := 2, pLineTransparicy := 200) {
    try
    {
        ; Retrieves the control's position relative to the computer screen.
        WinGetClientPos(&screenControlX, &screenControlY, &controlWidth, &controlHeight, pControlElement)
    }
    catch {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] The control with the text [" . pControlElement.Text .
            "] does not exist.",
            "VideoDownloader - [" . A_ThisFunc . "()]", "IconX 262144")
    }
    highlightBox := RectangleHollowBox(screenControlX, screenControlY, controlWidth, controlHeight, pColor,
        pLineThickness, pLineTransparicy)
    highlightBox.draw()
    return highlightBox
}

/*
@param pWindowHWND [int] The unique identifier from a standard windows window with a menu bar.
@param pMenuElementIndex [int] The menu element to retrieve information about. The menu on the left will have an index of one,
the menu next to it an index of 2 and so on. Enter 0 as a parameter to highlight the complete menu bar.
@param pColor [String] Determines the color of the border.
@param pLineeThickness [int] Defines how thin the border is (in pixels).
@param pLineTransparicy [int] Should be a value between 0 and 255. 0 makes the border invisible and 255 makes it entirely visible.
@returns [RectangleHollowBox] This object can be used to control the border and it's properties.
*/
highlightMenuElement(pWindowHWND, pMenuElementIndex, pColor := "red", pLineThickness := 2, pLineTransparicy := 200) {
    menuBarInfo := getMenuBarInfo(pWindowHWND)
    ; This means we are extracting information about the complete menu bar.
    if (pMenuElementIndex == 0) {
        menuElementInfo := menuBarInfo.menuBarInfo
    }
    ; This means we are extracting information about a specific menu element in the menu bar.
    else {
        menuElementInfo := menuBarInfo.%"menuElementInfo_" . pMenuElementIndex%
    }
    highlightedMenuElement := RectangleHollowBox(menuElementInfo.topLeftCornerX, menuElementInfo.topLeftCornerY,
        menuElementInfo.width, menuElementInfo.heigth, pColor, pLineThickness, pLineTransparicy)
    highlightedMenuElement.draw()
    return highlightedMenuElement
}

/*
Retrieves information about a menu bar and it's menu elements from a standard windows window (notepad for example).
@param pWindowHWND [int] The unique identifier from a standard windows window with a menu bar.
@returns [menuBarInfoObject] This object has the following properties:
menuBarInfoObject.menuBarInfo (Contains information about the menu bar)
menuBarInfoObject.menuElementInfo_n (n represents the index of each menu element)

When there is a menu bar with a "File", "Option" and "Help" menu, there will be a
menuBarInfoObject.menuElementInfo_1 (File), menuBarInfoObject.menuElementInfo_2 (Option) and menuBarInfoObject.menuElementInfo_3 (Help) property.

Each property (menuBarInfoObject.menuElementInfo_n and menuBarInfoObject.menuBarInfo) has the following properties:
menuBarInfoObject.menuElementInfo_n.topLeftCornerX (The x coordinate from the top left corner of the menu / menu bar)
menuBarInfoObject.menuElementInfo_n.topLeftCornerY (The y coordinate from the top left corner of the menu / menu bar)
menuBarInfoObject.menuElementInfo_n.width (The width of the menu / menu bar)
menuBarInfoObject.menuElementInfo_n.heigth (The heigth of the menu / menu bar)
*/
getMenuBarInfo(pWindowHWND) {
    ; Get the menu bar info object.
    menuBarInfoDLL := DllCall("GetMenu", "Ptr", pWindowHWND, "Ptr")
    if (!menuBarInfoDLL) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Failed to get menu bar info from window with HWND [" . pWindowHWND .
            "]."
            . "`n`nError description: [`n" . A_LastError . "`n]",
            "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        return
    }
    ; Finds out how many menu elements the menu bar has.
    menuBarMenuAmount := DllCall("GetMenuItemCount", "Ptr", menuBarInfoDLL, "Int")
    if (menuBarMenuAmount == -1) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Failed to get menu bar info from window with HWND [" . pWindowHWND .
            "]."
            . "`n`nError description: [`n" . A_LastError . "`n]",
            "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        return
    }

    ; Collect information about every menu element.
    menuInfoObjectArray := Array()
    loop (menuBarMenuAmount) {
        ; All menu info objects are stored into an array.
        menuInfoObjectArray.Push(getMenuElementInfoObject(A_Index))
    }
    menuBarInfoObject := Object()
    menuBarInfoObject.menuBarInfo := getMenuElementInfoObject(0)
    ; Adds all menu element info objects into the menuBarInfoObject.
    for (menuElementInfoObject in menuInfoObjectArray) {
        menuBarInfoObject.%"menuElementInfo_" . A_Index% := menuElementInfoObject
    }
    return menuBarInfoObject
    ; Passing the index 0 will return info about the menu bar.
    getMenuElementInfoObject(menuElementIndex) {
        menuElementInfoBuffer := Buffer(48, 0)
        NumPut("UInt", 48, menuElementInfoBuffer, 0)

        result := DllCall("GetMenuBarInfo", "Ptr", pWindowHWND, "Int", 0xFFFFFFFD, "Int", menuElementIndex, "Ptr",
            menuElementInfoBuffer)
        if (!result) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Failed to get menu element info from window with HWND [" .
                pWindowHWND . "]."
                . "`n`nError description: [`n" . A_LastError . "`n]",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        }

        menuElementInfo := Object()
        menuElementInfo.topLeftCornerX := NumGet(menuElementInfoBuffer, 4, "int")
        menuElementInfo.topLeftCornerY := NumGet(menuElementInfoBuffer, 8, "int")
        ; Some values we need for calulating the width and height.
        menuTmp1 := NumGet(menuElementInfoBuffer, 12, "int")
        menuTmp2 := NumGet(menuElementInfoBuffer, 16, "int")
        menuElementInfo.width := menuTmp1 - menuElementInfo.topLeftCornerX
        menuElementInfo.heigth := menuTmp2 - menuElementInfo.topLeftCornerY
        return menuElementInfo
    }
}

handleHelpGUI_helpGUIStatusBar_onClick(pStatusBar, pInfo) {
    static i := 0

    i++
    if (i >= 5) {
        i := 0
        fakeErrorObject := Object()
        fakeErrorObject.What := "This is a tribute to my friend Elias who helps me a lot by testing this software :D"
        fakeErrorObject.Message := "Is that an easter egg?"
        fakeErrorObject.Extra := "https://www.youtube.com/watch?v=dQw4w9WgXcQ"
        fakeErrorObject.File := "notavirus.exe"
        fakeErrorObject.Line := "69"
        fakeErrorObject.Stack := "( ˶ˆ꒳ˆ˵ )`n(づ◡﹏◡)づ`n(,,>﹏<,,)"
        displayErrorMessage(fakeErrorObject, "This is a totally real error btw")
    }
}

/*
Creates a hollow rectangle box out of 4 seperate GUIs. This could be used to mark controls on another GUI.
@param pTopLeftCornerX [int] Should be a valid screen coordinate. The x and y coordinates will point to the top left corner
of the hollow box inside the borders.
@param pTopLeftCornerY [int] This is the second paramter used in combination with pTopLeftCornerX.
@param pBoxWidth [int] Defines the width of the inner box enclosed by the borders.
@param pBoxHeight [int] Specifies how high the inner box should be.
@param pOuterLineColor [String] Can be a color in any color format known by AutoHotkey.
@param pOuterLineThickness [int] Defines how thick the outer lines around the inner box will be in pixels.
@param pOuterLineTransparicy [int] Should be a value between 0 and 255. 0 makes the borders invisible and 255 makes them entirely visible.
*/
class RectangleHollowBox {
    __New(pTopLeftCornerX := unset, pTopLeftCornerY := unset, pBoxWidth := 10, pBoxHeight := 10, pOuterLineColor :=
        "red", pOuterLineThickness := 1, pOuterLineTransparicy := 50) {
        ; Both parameters are omitted.
        if (!IsSet(pTopLeftCornerX) && !IsSet(pTopLeftCornerY)) {
            ; We use the current mouse cursor position here.
            MouseGetPos(&mouseX, &mouseY)
            this.topLeftCornerX := mouseX
            this.topLeftCornerY := mouseY
        }
        ; Only one parameter is given and the other one is missing.
        else if (!IsSet(pTopLeftCornerX) || !IsSet(pTopLeftCornerY)) {
            MsgBox("[" . A_ThisFunc .
                "()] [WARNING] Make sure that either both (pTopLeftCornerX and pTopLeftCornerY) are given or omitted entirely.",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            return
        }
        else {
            this.topLeftCornerX := pTopLeftCornerX
            this.topLeftCornerY := pTopLeftCornerY
        }
        this.boxWidth := pBoxWidth
        this.boxHeight := pBoxHeight
        this.outerLineColor := pOuterLineColor
        this.outerLineThickness := pOuterLineThickness
        this.outerLineTransparicy := pOuterLineTransparicy
    }
    ; Creates and shows the rectangle box.
    draw() {
        /*
        ------
        
        
        */
        this.__line1 := Gui("+AlwaysOnTop -Caption +Disabled -DPIScale +ToolWindow", "")
        this.__line1.BackColor := this.outerLineColor
        showWidth := this.boxWidth + this.outerLineThickness * 2
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY - this.outerLineThickness
        showString := "x" . showX . " y" . showY . " w" . showWidth
            . " h" . this.outerLineThickness . " NoActivate"
        this.__line1.Show(showString)

        /*
        |
        |
        |
        */
        this.__line2 := Gui("+AlwaysOnTop -Caption +Disabled -DPIScale +ToolWindow", "")
        this.__line2.BackColor := this.outerLineColor
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY
        showString := "x" . showX . " y" . showY . " w" . this.outerLineThickness
            . " h" . this.boxHeight . " NoActivate"
        this.__line2.Show(showString)

        /*
                |
                |
                |
        */
        this.__line3 := Gui("+AlwaysOnTop -Caption +Disabled -DPIScale +ToolWindow", "")
        this.__line3.BackColor := this.outerLineColor
        showX := this.topLeftCornerX + this.boxWidth
        showY := this.topLeftCornerY
        showString := "x" . showX . " y" . showY . " w" . this.outerLineThickness
            . " h" . this.boxHeight . " NoActivate"
        this.__line3.Show(showString)

        /*
        
        
        -----
        */
        this.__line4 := Gui("+AlwaysOnTop -Caption +Disabled -DPIScale +ToolWindow", "")
        this.__line4.BackColor := this.outerLineColor
        showWidth := this.boxWidth + this.outerLineThickness * 2
        showX := this.topLeftCornerX - this.outerLineThickness
        showY := this.topLeftCornerY + this.boxHeight
        showString := "x" . showX . " y" . showY . " w" . showWidth
            . " h" . this.outerLineThickness . " NoActivate"
        this.__line4.Show(showString)

        WinSetTransparent(this.outerLineTransparicy, this.__line1)
        WinSetTransparent(this.outerLineTransparicy, this.__line2)
        WinSetTransparent(this.outerLineTransparicy, this.__line3)
        WinSetTransparent(this.outerLineTransparicy, this.__line4)
    }
    move(pX, pY) {
        this.topLeftCornerX := pX
        this.topLeftCornerY := pY

        this.destroy()
        this.draw()
    }
    ; This does NOT destroy the object, but the rectangle box instead.
    destroy() {
        this.__line1.Destroy()
        this.__line2.Destroy()
        this.__line3.Destroy()
        this.__line4.Destroy()
    }
    show() {
        this.__line1.Show()
        this.__line2.Show()
        this.__line3.Show()
        this.__line4.Show()
    }
    hide() {
        this.__line1.Hide()
        this.__line2.Hide()
        this.__line3.Hide()
        this.__line4.Hide()
    }
}
