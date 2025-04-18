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
    helpGUISearchBarEdit.OnEvent("Change", (*) => updateListViewAccordinglyToSearch(helpGUISearchBarEdit.Text))
    ; This selects the text inside the edit once the user clicks on it again after loosing focus.
    helpGUISearchBarEdit.OnEvent("Focus", (*) => ControlSend("^A", helpGUISearchBarEdit))

    helpGUIListViewArray := Array("Topic", "Type", "Title")
    helpGUIListView := helpGUI.Add("ListView", "yp+40 w400 R10 -Multi", helpGUIListViewArray)
    helpGUIListView.OnEvent("DoubleClick", (*) => processDoubleClickedListViewItem())

    helpGUIInfoGroupBox := helpGUI.Add("GroupBox", "xp+170 yp-65 w230 R2", "Application Info")

    local currentVersionLink := "https://github.com/LeoTN/yt-dlp-autohotkey-gui/releases/" . versionFullName
    local currentVersionString := 'Version: <a href="' . currentVersionLink . '">' . versionFullName . '</a>'
    helpGUIApplicationtVersionLink := helpGUI.Add("Link", "xp+10 yp+18", currentVersionString)
    helpGUIApplicationtVersionLink.ToolTip :=
        "Made by LeoTN (https://github.com/LeoTN). © 2025. Licensed under the MIT License."

    ; These links need to be changed when renaming the .YAML files for the GitHub issues section.
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
    helpGUIStatusBar.OnEvent("Click", (*) => handleHelpGUI_helpSectionEasterEgg())

    helpGUIListViewContentArray := createListViewContentCollectionArray()
    for (contentEntry in helpGUIListViewContentArray) {
        addLineToListView(contentEntry)
    }
    ; Sorts the data according to the title column.
    helpGUIListView.ModifyCol(3, "SortHdr")
}

updateListViewAccordinglyToSearch(pSearchString) {
    global helpGUIListViewContentArray

    helpGUIListView.Delete()
    ; Shows all data when the search bar is empty.
    if (pSearchString == "") {
        for (contentEntry in helpGUIListViewContentArray) {
            addLineToListView(contentEntry)
        }
        return
    }
    ; Calls the search function to search in all entries.
    resultArray := searchInListView(pSearchString)
    for (resultEntry in resultArray) {
        addLineToListView(resultEntry)
    }
    else {
        tmpListViewEntry := ListViewEntry("*****", "No results found.", "*****", (*) =>
            0)
        addLineToListView(tmpListViewEntry)
    }
}

/*
Allows to search for elements in the list view element.
@param pSearchString [String] A string to search for.
@returns [Array] This array contains all ListView objects matching the search string.
*/
searchInListView(pSearchString) {
    global helpGUIListViewContentArray

    resultArrayCollection := Array()
    ; Scans every string in the content array.
    for (contentEntry in helpGUIListViewContentArray) {
        if (InStr(contentEntry.topic, pSearchString)) {
            resultArrayCollection.Push(contentEntry)
        }
        else if (InStr(contentEntry.type, pSearchString)) {
            resultArrayCollection.Push(contentEntry)
        }
        else if (InStr(contentEntry.title, pSearchString)) {
            resultArrayCollection.Push(contentEntry)
        }
    }
    return resultArrayCollection
}

/*
Adds the content of a list view entry object into the list view element.
@param pListViewObject [ListViewEntry] An object containing relevant information to create an item in the list view.
@param pBooleanAutoAdjust [boolean] If set to true, the column width will be adjusted accordingly to the content.
*/
addLineToListView(pListViewObject, pBooleanAutoAdjust := true) {
    global helpGUIListViewArray

    helpGUIListView.Add(, pListViewObject.topic, pListViewObject.type, pListViewObject.title)
    if (pBooleanAutoAdjust) {
        ; Adjust the width accordingly to the content.
        loop (helpGUIListViewArray.Length) {
            helpGUIListView.ModifyCol(A_Index, "AutoHdr")
        }
    }
}

; Runs the bound action of the currently selected list view element.
processDoubleClickedListViewItem() {
    global helpGUIListViewContentArray
    ; This map stores all visible list view entries together with their identifyer string.
    identifyerMap := Map()
    for (contentEntry in helpGUIListViewContentArray) {
        identifyerMap[contentEntry.identifyerString] := contentEntry
    }
    ; Finds out the currently selected entry's index.
    focusedEntryColumnNumber := helpGUIListView.GetNext(, "Focused")
    ; The identifyer string is created by merging the topic, the type and the title of the ListView object.
    entryTopic := helpGUIListView.GetText(focusedEntryColumnNumber, 1)
    entryType := helpGUIListView.GetText(focusedEntryColumnNumber, 2)
    entryTitle := helpGUIListView.GetText(focusedEntryColumnNumber, 3)
    focusedEntryIdentifyerString := entryTopic . entryType . entryTitle
    ; Runs the action from the identified ListView object.
    identifyerMap[focusedEntryIdentifyerString].runAction()
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

handleHelpGUI_helpSectionEasterEgg() {
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
Stores all data required to create an entry in a list view element.
@param pTopic [String] The topic this entry is about (e.g. General, Macros, etc.).
@param pType [String] The type of content, for instance, Tutorial or Info.
@param pTitle[String] The title of the entry.
@param pAction [Function] Can be a fat arrow function ((*) =>) or a function call (doSomething()).
*/
class ListViewEntry {
    __New(pTopic, pType, pTitle, pAction) {
        this.topic := pTopic
        this.type := pType
        this.title := pTitle
        this.action := pAction
        ; This string will be used to identify the entry.
        this.identifyerString := this.topic . this.type . this.title
    }
    runAction() {
        this.action
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
    draw() {
        /*
        ------
        
        
        */
        this.__line1 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
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
        this.__line2 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
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
        this.__line3 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
        this.__line3.BackColor := this.outerLineColor
        showX := this.topLeftCornerX + this.boxWidth
        showY := this.topLeftCornerY
        showString := "x" . showX . " y" . showY . " w" . this.outerLineThickness
            . " h" . this.boxHeight . " NoActivate"
        this.__line3.Show(showString)

        /*
        
        
        -----
        */
        this.__line4 := Gui("+AlwaysOnTop -Caption +Disabled +ToolWindow", "")
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
