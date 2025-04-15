#SingleInstance Force
#MaxThreadsPerHotkey 2
SendMode "Input"
CoordMode "Mouse", "Window"

tutorials_onInit() {
    ; Initializes all tutorials and info texts.
    tutorial_howToFindHelpGUI()
    tutorial_gettingStarted()
}

tutorial_howToFindHelpGUI() {
    global howToUseHelpGUITutorial := InteractiveTutorial("How to use the help database")
    currentlyHighlightedControlObject := ""

    howToUseHelpGUITutorial.addText(
        "This tutorial will basically teach you how to find more tutorials and information.")
    howToUseHelpGUITutorial.addAction((*) => hideAllHighlightedElements())
    howToUseHelpGUITutorial.addText(
        "At first, you need to click on the [Help] menu in the top right corner of the main window.")
    howToUseHelpGUITutorial.addAction((*) => showVideoListGUIAndHighlightMenu())
    howToUseHelpGUITutorial.addText(
        "You can search these entries with the search bar (highlighted with a red border).")
    howToUseHelpGUITutorial.addAction((*) => highlightSearchBar())
    howToUseHelpGUITutorial.addText("Double clicking them can start interactive tutorials or just a simple info text.")
    howToUseHelpGUITutorial.addAction((*) => demonstrateSearchBar())
    ; Makes sure the highlighted controls become normal again.
    howToUseHelpGUITutorial.addExitAction((*) => hideAllHighlightedElements())

    showVideoListGUIAndHighlightMenu() {
        hideAllHighlightedElements()
        videoListGUI.Show("AutoSize")
        currentlyHighlightedControlObject := highlightMenuElement(videoListGUI.Hwnd, 3)
    }
    highlightSearchBar() {
        hideAllHighlightedElements()
        helpGUI.Show("AutoSize")
        currentlyHighlightedControlObject := highlightControl(helpGUISearchBarEdit)
    }
    demonstrateSearchBar() {
        hideAllHighlightedElements()
        helpGUISearchBarEdit.Focus()
        ; This array contains the letters "typed" into the search bar for demonstration purposes.
        searchBarDemoLetterArray := stringToArray("Getting started")
        ; Demonstrates the search bar to the user.
        for (letter in searchBarDemoLetterArray) {
            if (WinExist("ahk_id " . helpGUI.Hwnd)) {
                WinActivate()
            }
            ControlSend(letter, helpGUISearchBarEdit, "ahk_id " . helpGUI.Hwnd)
            Sleep(20)
        }
    }
    hideAllHighlightedElements() {
        if (IsObject(currentlyHighlightedControlObject)) {
            ; Hides the highlighted control box.
            currentlyHighlightedControlObject.destroy()
        }
    }
}

tutorial_gettingStarted() {
    global gettingStartedTutorial := InteractiveTutorial("Getting started")
    currentlyHighlightedControlObject := ""

    gettingStartedTutorial.addText("This tutorial is not finished yet.")
    gettingStartedTutorial.addAction((*) =>)
}

/*
Creates an array, which contains list view entry objects. They contain the required data to be added into a list view element.
@returns [Array] This array is filled with list view objects.
*/
createListViewContentCollectionArray() {
    ; This array contains all list view entries.
    helpGUIListViewContentArray := Array()
    ; 1. Topic 2. Type 3. Title 4. Action
    listViewEntry_1 := ListViewEntry(
        "General", "Tutorial", "How to use the help database",
        ; This will show the window relatively to the main GUI.
        (*) => calculateInteractiveTutorialGUICoordinates(videoListGUI.Hwnd, &x, &y) howToUseHelpGUITutorial.start(
            x, y)
    )
    listViewEntry_2 := ListViewEntry("General", "Tutorial", "Getting started",
        ; This will show the window relatively to the help GUI.
        (*) => calculateInteractiveTutorialGUICoordinates(helpGUI.Hwnd, &x, &y) gettingStartedTutorial.start(x, y))

    ; The number needes to be updated depending on how many list view entries there are.
    loop (2) {
        helpGUIListViewContentArray.InsertAt(A_Index, %"listViewEntry_" . A_Index%)
    }
    return helpGUIListViewContentArray
}

; A small tutorial to show off the help GUI of this script.
scriptTutorial() {
    result_1 := MsgBox("Would you like to have a short tutorial on how to use this software?",
        "VideoDownloader - Start Tutorial", "YN Iconi 262144")
    ; The dialog to disable the tutorial for the next time is only shown when the config file entry mentioned below is true.
    if (readConfigFile("ASK_FOR_TUTORIAL")) {
        result_2 := MsgBox("Press [Yes] to disable the tutorialfor the next time you run this script.",
            "VideoDownloader - Disable Tutorial for Next Time", "YN Iconi 262144")
        if (result_2 == "Yes") {
            editConfigFile("ASK_FOR_TUTORIAL", false)
        }
    }
    if (result_1 == "Yes") {
        minimizeAllGUIs()
        ; Welcome message.
        MsgBox("Hello there... General Kenobi!`n`nThank you for downloading VideoDownloader!",
            "VideoDownloader - Thanks for Installing", "YN Iconi 262144")
        ; This will show the window relatively to the main GUI.
        calculateInteractiveTutorialGUICoordinates(videoListGUI.Hwnd, &x, &y)
        howToUseHelpGUITutorial.start(x, y)
    }
}

minimizeAllGUIs() {
    ; Minimizes all script windows to reduce diversion.
    if (WinExist("ahk_id " . videoListGUI.Hwnd)) {
        WinMinimize()
    }
    if (WinExist("ahk_id " . helpGUI.Hwnd)) {
        WinMinimize()
    }
}

/*
Calculates the position for the interactive tutorial window to appear.
The position will be selected relatively to the right of a given window.
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
Can be used to create an interactive tutorial with a navigation window for the user.
@param pTutorialTitle [String] The title of the navigation window.
IMPORTANT: When adding text to a step, a height of 10 lines must not be exceeded!
In other words: ([K]eep [I]t [S]hort and [S]imple => KISS).
*/
class InteractiveTutorial {
    __New(pTutorialTitle) {
        this.tutorialTitle := pTutorialTitle
        ; Contains the text for each step.
        this.textArray := Array()
        ; Contains an internal function to call for each step. You can enter "empty" functions like that "(*) =>".
        this.actionArray := Array()
        ; Can be filled with functions to execute when the user exits the tutorial.
        this.exitActionArray := Array()
        this.currentStepIndex := 1
        this.gui := Gui("AlwaysOnTop", pTutorialTitle)
        this.gui.OnEvent("Close", (*) => this.exit())
        this.guiText := this.gui.Add("Text", "yp+10 w320 R10", "interactive_tutorial_text")
        this.guiPreviousButton := this.gui.Add("Button", "yp+150 w100", "Previous")
        this.guiPreviousButton.OnEvent("Click", (*) => this.previous())
        this.guiExitButton := this.gui.Add("Button", "xp+110 w100", "Exit")
        this.guiExitButton.OnEvent("Click", (*) => this.exit())
        this.guiNextButton := this.gui.Add("Button", "xp+110 w100", "Next")
        this.guiNextButton.OnEvent("Click", (*) => this.next())
        this.guiStatusBar := this.gui.Add("StatusBar", , "interactive_tutorial_statusbar_text")
        this.guiStatusBar.SetIcon("shell32.dll", 222) ; ICON_DLL_USED_HERE ; REMOVE [ADD ICON FILE]
    }
    ; You can provide optional coordinates for the GUI to show up.
    start(pGuiX := unset, pGuiY := unset) {
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
