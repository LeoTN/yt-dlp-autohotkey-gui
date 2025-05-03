#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

tutorials_onInit() {
    ; Initializes all tutorials and info texts.
    tutorial_howToFindHelpGUI()
    tutorial_gettingStarted()
    tutorial_howToUsePlaylistRangeIndex()
}

; This tutorial aims to show the user how they can find the help section.
tutorial_howToFindHelpGUI() {
    global howToUseHelpGUITutorial :=
        InteractiveTutorialListViewEntry("General", "Tutorial", "How to use the Help Database")
    currentlyHighlightedControlObject := ""

    howToUseHelpGUITutorial.addText(
        "This tutorial will basically teach you how to find more tutorials and information.")
    howToUseHelpGUITutorial.addAction((*) => start())
    howToUseHelpGUITutorial.addText(
        "At first, you need to click on the [Help] menu in the top right corner of the video list window.")
    howToUseHelpGUITutorial.addAction((*) => showVideoListGUIAndHighlightHelpMenu())
    howToUseHelpGUITutorial.addText(
        "You can search these entries with the search bar (highlighted with a red border).")
    howToUseHelpGUITutorial.addAction((*) => highlightSearchBar())
    howToUseHelpGUITutorial.addText('Double clicking them can start interactive tutorials or just a simple info text.'
        '`n`nYou may start the "Getting started" tutorial now.')
    howToUseHelpGUITutorial.addAction((*) => demonstrateSearchBar())
    ; Makes sure the highlighted controls become normal again.
    howToUseHelpGUITutorial.addExitAction((*) => hideAllHighlightedElements())

    start() {
        hideAllHighlightedElements()
        saveCurrentVideoListGUIStateToConfigFile()
        showVideoListGUIWithSavedStateData()
        showGUIRelativeToOtherGUI(videoListGUI, howToUseHelpGUITutorial.gui, "MiddleRightCorner")
    }
    showVideoListGUIAndHighlightHelpMenu() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightMenuElement(videoListGUI.Hwnd, 5)
    }
    highlightSearchBar() {
        hideAllHighlightedElements()
        showGUIRelativeToOtherGUI(videoListGUI, helpGUI, "MiddleCenter", "AutoSize")
        currentlyHighlightedControlObject := highlightControl(helpGUISearchBarEdit)
    }
    demonstrateSearchBar() {
        hideAllHighlightedElements()
        showGUIRelativeToOtherGUI(videoListGUI, helpGUI, "MiddleCenter", "AutoSize")
        helpGUISearchBarEdit.Focus()
        ; Waits a little to avoid loosing the first few letters.
        Sleep(100)
        ; This array contains the letters "typed" into the search bar for demonstration purposes.
        searchBarDemoLetterArray := StrSplit("Getting started")
        ; Demonstrates the search bar to the user.
        for (letter in searchBarDemoLetterArray) {
            ControlSend(letter, helpGUISearchBarEdit, "ahk_id " . helpGUI.Hwnd)
            Sleep(10)
        }
    }
    hideAllHighlightedElements() {
        if (IsObject(currentlyHighlightedControlObject)) {
            ; Hides the highlighted control box.
            currentlyHighlightedControlObject.destroy()
        }
    }
}

; This tutorial wants to show a few basics to get the user up and running.
tutorial_gettingStarted() {
    global gettingStartedTutorial :=
        InteractiveTutorialListViewEntry("General", "Tutorial", "Getting started")
    currentlyHighlightedControlObject := ""

    ; Collect URL from browser hotkey showcase.
    gettingStartedTutorial.addText(
        "This tutorial will guide you through your first video download.")
    gettingStartedTutorial.addAction((*) => closeHowToUseHelpGUITutorial())
    gettingStartedTutorial.addText(
        "To add videos to the list, you need their URL."
        "`n`nPlease open a (YouTube) video of your choice in your browser.")
    gettingStartedTutorial.addAction((*) => hideAllHighlightedElements())
    hotkeyString := expandHotkey(readConfigFile("URL_COLLECT_HK"))
    gettingStartedTutorial.addText(
        "Make sure that your browser is actively focused and the top most window."
        "`n`nPlease press [" . hotkeyString . "] while the browser is the active window to collect the video URL.")
    gettingStartedTutorial.addAction((*) => hideAllHighlightedElements())
    ; Video list showcase.
    gettingStartedTutorial.addText(
        "This is the video list. All videos will be added here, but the video extraction process might take some time."
        "`n`nIf everything worked, your video should be present in the list after a while.")
    gettingStartedTutorial.addAction((*) => showVideoListGUIAndHighlightVideoListView())
    gettingStartedTutorial.addText("Please take a look at this input field (highlighted with a red border)."
        "`n`nYou can enter video URLs here as well.")
    gettingStartedTutorial.addAction((*) => showVideoListGUIAndHighlightURLInputEdit())
    ; Download showcase.
    hotkeyString := expandHotkey(readConfigFile("START_DOWNLOAD_HK"))
    gettingStartedTutorial.addText(
        "Please press the [" . downloadStartButton.Text . "] button to start the download."
        "`n`nYou could also press [" . hotkeyString . "]."
        "`n`nPlease wait for the download to finish. You will see a message in the status bar.")
    gettingStartedTutorial.addAction((*) => showVideoListGUIAndHighlightDownloadButton())
    ; Directory showcase.
    gettingStartedTutorial.addText(
        "Please select the sub menu [Latest Download] of the [Directory] menu to see your downloaded video.")
    gettingStartedTutorial.addAction((*) => showVideoListGUIAndHighlightDirectoryMenu())
    ; Tutorial end.
    gettingStartedTutorial.addText(
        "That is the end of the tutorial."
        "`n`nThere are more features and download options but that might be too much for the beginning."
        "`n`nYou can always take a look at the help section to get more information.")
    gettingStartedTutorial.addAction((*) => showVideoListGUIAndHighlightHelpMenu())

    ; Makes sure the highlighted controls become normal again.
    gettingStartedTutorial.addExitAction((*) => hideAllHighlightedElements())

    closeHowToUseHelpGUITutorial() {
        hideAllHighlightedElements()
        saveCurrentVideoListGUIStateToConfigFile()
        showVideoListGUIWithSavedStateData()
        showGUIRelativeToOtherGUI(videoListGUI, gettingStartedTutorial.gui, "MiddleLeftCorner")
        /*
        The howToUseHelpGUITutorial refers to this tutorial at its end. It asks the user to start this tutorial
        and to avoid multiple unnecessary windows, we close the old tutorial if the user forgets it.
        */
        howToUseHelpGUITutorial.exit()
    }
    showVideoListGUIAndHighlightVideoListView() {
        ; Closes the help window.
        if (WinExist("ahk_id " . helpGUI.Hwnd)) {
            WinClose()
        }
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightControl(videoListView)
    }
    showVideoListGUIAndHighlightURLInputEdit() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightControl(addVideoURLInputEdit)
    }
    showVideoListGUIAndHighlightDownloadButton() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightControl(downloadStartButton)
    }
    showVideoListGUIAndHighlightDirectoryMenu() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightMenuElement(videoListGUI.Hwnd, 2)
    }
    showVideoListGUIAndHighlightHelpMenu() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightMenuElement(videoListGUI.Hwnd, 5)
    }
    hideAllHighlightedElements() {
        if (IsObject(currentlyHighlightedControlObject)) {
            ; Hides the highlighted control box.
            currentlyHighlightedControlObject.destroy()
        }
    }
}

; Shows the syntax and use of the playlist range index.
tutorial_howToUsePlaylistRangeIndex() {
    global howToUsePlaylistRangeIndexTutorial :=
        InteractiveTutorialListViewEntry("Video Extraction", "Information", "How to use the Playlist Range Index")
    currentlyHighlightedControlObject := ""

    ; Explain the need for the playlist range index.
    howToUsePlaylistRangeIndexTutorial.addText(
        "Why would I need to use the playlist range index?"
        "`n`nIf a URL contains a reference or is itself a link to a playlist, "
        . "only the video specified in the URL or the very first video of the playlist "
        . "will be added to the list by default.")
    howToUsePlaylistRangeIndexTutorial.addAction((*) => start())
    howToUsePlaylistRangeIndexTutorial.addText(
        "Why would I need to use the playlist range index?"
        "`n`nImagine a playlist with 20 videos, but you only want to download the first 10 videos."
        "`n`nIt would be possible to copy each video URL individually or to simply use the playlist range index.")
    howToUsePlaylistRangeIndexTutorial.addAction((*) => hideAllHighlightedElements())
    ; Show the input field.
    howToUsePlaylistRangeIndexTutorial.addText(
        "Where can I enter the playlist range index?"
        "`n`nPlease take a look at this input field. It indicates the validity in the text above."
        "`n`nThe entered string is not a valid index.")
    howToUsePlaylistRangeIndexTutorial.addAction((*) =>
        showVideoListGUIAndHighlightPlaylistRangeIndexInputEditAndEnterInvalidIndex())
    howToUsePlaylistRangeIndexTutorial.addText(
        "Where can I enter the playlist range index?"
        "`n`nHowever this time, the playlist range index is valid."
        "`n`n[1,2,3] and [1-3] would have the same effect. Note, that [1:3] is the same as [1-3].")
    howToUsePlaylistRangeIndexTutorial.addAction((*) =>
        showVideoListGUIAndHighlightPlaylistRangeIndexInputEditAndEnterValidIndex())
    ; Explain the syntax.
    howToUsePlaylistRangeIndexTutorial.addText(
        "Playlist Range Index Syntax Example"
        "`n`nLet's get back to our example from the beginning. "
        . "We have a playlist with 20 videos, but only want to download the first 10 of them."
        "`n`nTo achieve this, we select the videos similar to pages in a document."
        "`n`n1 (the first video) and 10 (the last video) → [1-10].")
    howToUsePlaylistRangeIndexTutorial.addAction((*) => hideAllHighlightedElements())
    howToUsePlaylistRangeIndexTutorial.addText(
        "Playlist Range Index Syntax Example"
        "`n`nIf we now wanted to have the 15th video as well, the index would have to be adjusted as follows:"
        "`n`n1 (the first video) and 10 (the last video) and 15 (the 15th video) → [1-10,15].")
    howToUsePlaylistRangeIndexTutorial.addAction((*) => hideAllHighlightedElements())
    howToUsePlaylistRangeIndexTutorial.addText(
        "Playlist Range Index Summary"
        "`n`nUse ranges to select a range of videos.`nFor example [1-10]."
        "`n`nUse single index numbers to select specific videos.`nFor example [1]."
        "`n`nEach new instruction must be seperated by a comma.`nFor example [1,2,3,4,5-10]")
    howToUsePlaylistRangeIndexTutorial.addAction((*) => hideAllHighlightedElements())

    ; Makes sure the highlighted controls become normal again.
    howToUsePlaylistRangeIndexTutorial.addExitAction((*) => hideAllHighlightedElements())

    start() {
        hideAllHighlightedElements()
        saveCurrentVideoListGUIStateToConfigFile()
        showVideoListGUIWithSavedStateData()
    }
    showVideoListGUIAndHighlightPlaylistRangeIndexInputEditAndEnterInvalidIndex() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightControl(addVideoSpecifyPlaylistRangeInputEdit)
        ; Enables the required checkboxes.
        addVideoURLIsAPlaylistCheckbox.Value := 1
        handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick(addVideoURLIsAPlaylistCheckbox, "")
        addVideoURLUsePlaylistRangeCheckbox.Value := 1
        handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick(addVideoURLUsePlaylistRangeCheckbox, "")
        ; Demonstrates the playlist range input field.
        addVideoSpecifyPlaylistRangeInputEdit.Value := ""
        addVideoSpecifyPlaylistRangeInputEdit.Focus()
        ; This array contains the letters "typed" into the edit for demonstration purposes.
        charArray := StrSplit("Example Invalid Index Value")
        for (char in charArray) {
            ControlSend(char, addVideoSpecifyPlaylistRangeInputEdit, "ahk_id " . videoListGUI.Hwnd)
            Sleep(10)
        }
    }
    showVideoListGUIAndHighlightPlaylistRangeIndexInputEditAndEnterValidIndex() {
        hideAllHighlightedElements()
        videoListGUI.Show()
        currentlyHighlightedControlObject := highlightControl(addVideoSpecifyPlaylistRangeInputEdit)
        ; Enables the required checkboxes.
        addVideoURLIsAPlaylistCheckbox.Value := 1
        handleVideoListGUI_addVideoURLIsAPlaylistCheckbox_onClick(addVideoURLIsAPlaylistCheckbox, "")
        addVideoURLUsePlaylistRangeCheckbox.Value := 1
        handleVideoListGUI_addVideoURLUsePlaylistRangeCheckbox_onClick(addVideoURLUsePlaylistRangeCheckbox, "")
        ; Demonstrates the playlist range input field.
        addVideoSpecifyPlaylistRangeInputEdit.Value := ""
        addVideoSpecifyPlaylistRangeInputEdit.Focus()
        ; This array contains the letters "typed" into the edit for demonstration purposes.
        charArray := StrSplit("1,2,3,1-3,1:3")
        for (char in charArray) {
            ControlSend(char, addVideoSpecifyPlaylistRangeInputEdit, "ahk_id " . videoListGUI.Hwnd)
            Sleep(10)
        }
    }
    hideAllHighlightedElements() {
        if (IsObject(currentlyHighlightedControlObject)) {
            ; Hides the highlighted control box.
            currentlyHighlightedControlObject.destroy()
        }
    }
}

; A small tutorial to show off the help GUI of this application.
applicationTutorial() {
    ; Welcome message.
    result_1 := MsgBox("Hello there... General Kenobi!`n`nThank you for installing VideoDownloader!"
        "`n`nWould you like to start a short tutorial?",
        "VD - Start Tutorial", "YN Iconi Owner" . videoListGUI.Hwnd)
    editConfigFile(false, "ASK_FOR_TUTORIAL")
    if (result_1 == "Yes") {
        minimizeAllGUIs()
        howToUseHelpGUITutorial.start()
    }
}

minimizeAllGUIs() {
    ; Minimizes all application windows to reduce diversion.
    hwndArray := [videoListGUI.Hwnd, settingsGUI.Hwnd, helpGUI.Hwnd]
    for (hwnd in hwndArray) {
        if (WinExist("ahk_id " . hwnd)) {
            WinMinimize()
        }
    }
}

/*
Calculates the position for the interactive tutorial window to appear.
The position will be selected relatively to the right of a given window.
@param pWindowHWND [int] The hwnd of the window to show the other GUI relatively to.
@var coordinateX [int] The x coordinate for the window.
@var coordinateY [int] The y coordinate for the window.
*/
calculateInteractiveTutorialGUICoordinates(pWindowHWND, &coordinateX, &coordinateY) {
    coordinateX := 0
    coordinateY := 0
    if (!WinExist("ahk_id " . pWindowHWND)) {
        MsgBox("[" . A_ThisFunc . "()] [WARNING] Could not find window with HWND: [" . pWindowHWND . "].",
            "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        return
    }
    ; This is done to make WinGetPos() work reliably.
    WinActivate("ahk_id " . pWindowHWND)
    ; We receive the coordinates from the top left corner of the given window.
    WinGetPos(&topLeftCornerX, &topLeftCornerY, &width, , "ahk_id " . pWindowHWND)
    windowTopRightCornerX := topLeftCornerX + width
    windowTopRightCornerY := topLeftCornerY
    ; We add an ofset for the x coordinate.
    coordinateX := windowTopRightCornerX + 50
    coordinateY := windowTopRightCornerY
}

/*
This object is used to create interactive tutorials and information texts. They will be shown in the help GUI.
@param pTopic [string] The topic of the tutorial.
@param pType [string] The type of the tutorial.
@param pTitle [string] The title of the tutorial.
*/
class InteractiveTutorialListViewEntry {
    __New(pTopic, pType, pTitle) {
        ; Used to determine input errors while creating new tutorial entries.
        allowedTopicsArray := ["General", "Video Extraction"]
        if (!checkIfStringIsInArray(pTopic, allowedTopicsArray)) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid topic received: [" . pTopic . "].",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            exitApplicationWithNotification(true)
        }
        ; Used to determine input errors while creating new tutorial entries.
        allowedTypesArray := ["Tutorial", "Information"]
        if (!checkIfStringIsInArray(pType, allowedTypesArray)) {
            MsgBox("[" . A_ThisFunc . "()] [WARNING] Invalid type received: [" . pType . "].",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            exitApplicationWithNotification(true)
        }
        /*
        This map stores all interactive tutorial objects with their identifier string as key.
        It is used to provide the content for the help GUI list view element.
        */
        if (!isSet(interactiveTutorialEntryMap)) {
            global interactiveTutorialEntryMap := Map()
        }
        this.topic := pTopic
        this.type := pType
        this.title := pTitle
        this.identifierString := pTopic . pType . pTitle
        ; Updates the help GUI list view element.
        this.addEntryToInteractiveTutorialEntryMap()
        this.updateHelpListViewElement()

        ; Contains the text for each step.
        this.textArray := Array()
        ; Contains an internal function to call for each step. You can enter "empty" functions like that "(*) =>".
        this.actionArray := Array()
        ; Can be filled with functions to execute when the user exits the tutorial.
        this.exitActionArray := Array()
        this.currentStepIndex := 1
        this.gui := Gui("AlwaysOnTop", this.title)
        this.gui.OnEvent("Close", (*) => this.exit())
        this.guiText := this.gui.Add("Text", "yp+10 w320 R10", "interactive_tutorial_text")
        this.guiPreviousButton := this.gui.Add("Button", "yp+150 w100", "<= Previous")
        this.guiPreviousButton.OnEvent("Click", (*) => this.previous())
        this.guiExitButton := this.gui.Add("Button", "xp+110 w100", "Exit")
        this.guiExitButton.OnEvent("Click", (*) => this.exit())
        this.guiNextButton := this.gui.Add("Button", "xp+110 w100", "Next =>")
        this.guiNextButton.OnEvent("Click", (*) => this.next())
        this.guiStatusBar := this.gui.Add("StatusBar", , "interactive_tutorial_statusbar_text")
        this.guiStatusBar.SetIcon(iconFileLocation, 14) ; ICON_DLL_USED_HERE
    }
    ; Adds the object to the tutorial list view entry map.
    addEntryToInteractiveTutorialEntryMap() {
        global interactiveTutorialEntryMap
        interactiveTutorialEntryMap.Set(this.identifierString, this)
    }
    ; Removes the object from the tutorial list view entry map.
    removeEntryFromInteractiveTutorialEntryMap() {
        global interactiveTutorialEntryMap
        interactiveTutorialEntryMap.Delete(this.identifierString)
    }
    ; Updates the help list view element with the current content of the tutorial list view entry map.
    updateHelpListViewElement() {
        global interactiveTutorialEntryMap
        ; Clears the old data from the list view element.
        helpGUIListView.Delete()
        for (key, tutorialEntry in interactiveTutorialEntryMap) {
            addInteractiveTutorialListViewEntryToListView(tutorialEntry)
        }
    }
    ; You can provide optional coordinates for the GUI to show up.
    start(pGuiX := unset, pGuiY := unset) {
        ; Makes the help GUI the owner of the window.
        if (IsSet(helpGUI) && WinExist("ahk_id " . helpGUI.Hwnd)) {
            this.gui.Opt("+Owner" . helpGUI.Hwnd)
        }
        ; Both parameters are omitted.
        if (!IsSet(pGuiX) && !IsSet(pGuiY)) {
            this.gui.Show("AutoSize")
        }
        ; Only one parameter is given and the other one is missing.
        else if (!IsSet(pGuiX) || !IsSet(pGuiY)) {
            MsgBox("[" . A_ThisFunc .
                "()] [WARNING] Make sure that either both (pGuiX and pGuiY) are given or omitted entirely.",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
            this.gui.Show("AutoSize")
        }
        else {
            this.gui.Show("x" . pGuiX . " y" . pGuiY)
        }
        ; Setting this to 1 will reset the tutorial.
        this.currentStepIndex := 1
        ; Displays the first text and starts the first action.
        this.playStep(1)
    }
    next() {
        this.currentStepIndex++
        this.playStep(this.currentStepIndex)
    }
    previous() {
        this.currentStepIndex--
        this.playStep(this.currentStepIndex)
    }
    exit() {
        /*
        Executes a variety of actions when the user exits the tutorial (if there are any actions provided).
        This could be used to hide certain windows or to stop controls from being highlighted for instance.
        */
        for (action in this.exitActionArray) {
            action.Call()
        }
        this.gui.Hide()
    }
    playStep(pStepIndex) {
        ; Updates the status bar.
        this.guiStatusBar.SetText("Step " . this.currentStepIndex . "/" . this.textArray.Length)
        ; Enables and disables the buttons accordingly to the current step index.
        if (pStepIndex <= 1) {
            ; Disables the previous button because you cannot go any further back on the very first step.
            this.guiPreviousButton.Opt("+Disabled")
        }
        else {
            this.guiPreviousButton.Opt("-Disabled")
        }
        if (pStepIndex >= this.textArray.Length) {
            ; Disables the next button because you cannot go any further on the very last step.
            this.guiNextButton.Opt("+Disabled")
        }
        else {
            this.guiNextButton.Opt("-Disabled")
        }

        if (this.textArray.Has(pStepIndex)) {
            this.guiText.Text := this.textArray.Get(pStepIndex)
        }
        else {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid text array index: [" . pStepIndex . "].",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        }
        if (this.actionArray.Has(pStepIndex)) {
            this.actionArray.Get(pStepIndex).Call()
        }
        else {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid action array index: [" . pStepIndex . "].",
                "VideoDownloader - [" . A_ThisFunc . "()]", "Icon! 262144")
        }
    }
    /*
    This method adds a text for the user to read. Will be played along with the actions in the actionArray.
    Do not exceed a length of 10 lines or there will be graphical issues.
    */
    addText(pText) {
        this.textArray.Push(pText)
    }
    /*
    This method requires a function object. This should be a function from the code containing instructions for the interactive tutorial.
    You can create these objects by passing the following parameter "(*) => doSomething()" without the quotation marks.
    Our method in the code would be called "doSomething()" in this example.
    */
    addAction(pFuncObject) {
        ; Checks if the given data is a valid function object.
        try
        {
            pFuncObject.IsOptional()
        }
        catch {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid function object.", "VideoDownloader - [" .
                A_ThisFunc . "()]", "Icon! 262144")
            return
        }
        this.actionArray.Push(pFuncObject)
    }
    /*
    This method requires a function object. This should be a function from the code containing instructions for the interactive tutorial.
    You can create these objects by passing the following parameter "(*) => doSomething()" without the quotation marks.
    Our method in the code would be called "doSomething()" in this example.
    */
    addExitAction(pFuncObject) {
        ; Checks if the given data is a valid function object.
        try
        {
            pFuncObject.IsOptional()
        }
        catch {
            MsgBox("[" . A_ThisFunc . "()]`n`n[WARNING] Received an invalid function object.", "VideoDownloader - [" .
                A_ThisFunc . "()]", "Icon! 262144")
            return
        }
        this.exitActionArray.Push(pFuncObject)
    }
}
