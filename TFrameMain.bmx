Type TFrameMain Extends wxFrame
	Field menuBar:wxMenuBar
	Field menuFile:wxMenu
	Field menuEdit:wxMenu
	Field menuView:wxMenu
	Field menuBuild:wxMenu
	Field menuHelp:wxMenu
	Field menuTest:wxMenu
	Field standardToolBar:wxToolBar
	Field auiManager:wxAuiManager
	
	Field tabs:wxAuiNotebook
	Field editor:TList 'TEditorPanel[1]
	Field _buildEditor:TEditorPanel
	Field _showStructure:Int
	
	Method OnInit()
		Print "Init~tFrameMain~tBasics"
		Self.setIcon(wxArtProvider.GetIcon("AppIcon", wxART_FRAME_ICON))
		Self.auiManager = New wxAuiManager.Create(Self)
		Self.editor = New TList
		Self._showStructure = Int(Settings.Get("ShowStructure"))
		
		Print "Init~tFrameMain~tMenues"
		Self._CreateMenues()
		
		Print "Init~tFrameMain~tToolbars"
		Self.standardToolBar = wxToolBar.CreateToolBar(Self, wxID_ANY,,, ,, wxTB_HORIZONTAL | wxNO_BORDER | wxTB_FLAT)
		Self.standardToolBar.AddTool(wxID_NEW, app.lang.Gui_MenuFileNew, wxArtProvider.GetBitmap(wxART_NEW, wxART_TOOLBAR))
		Self.standardToolBar.AddTool(wxID_OPEN, app.lang.Gui_MenuFileOpen, wxArtProvider.GetBitmap(wxART_FILE_OPEN, wxART_TOOLBAR))
		Self.standardToolBar.AddTool(wxID_SAVE, app.lang.Gui_MenuFileSave, wxArtProvider.GetBitmap(wxART_FILE_SAVE, wxART_TOOLBAR))
		Self.standardToolBar.AddTool(wxID_CLOSE, app.lang.Gui_MenuFileClose, wxArtProvider.GetBitmap("wxART_CLOSE", wxART_TOOLBAR))
		Self.standardToolBar.addSeparator()
		Self.standardToolBar.AddTool(wxID_CUT, app.lang.Gui_MenuEditCut, wxArtProvider.GetBitmap(wxART_CUT, wxART_TOOLBAR))
		Self.standardToolBar.AddTool(wxID_COPY, app.lang.Gui_MenuEditCopy, wxArtProvider.GetBitmap(wxART_COPY, wxART_TOOLBAR))
		Self.standardToolBar.AddTool(wxID_PASTE, app.lang.Gui_MenuEditPaste, wxArtProvider.GetBitmap(wxART_PASTE, wxART_TOOLBAR))
		Self.standardToolBar.addSeparator()
		Self.standardToolBar.AddTool(wxID_PREVIEW, app.lang.Gui_MenuBuildCompileRun, wxArtProvider.GetBitmap("AppBuildRun", wxART_TOOLBAR))'wxBitmap.CreateFromFile(IconApp + "CompileRun.png", wxBITMAP_TYPE_PNG))
		Self.standardToolBar.AddTool(wxID_STOP, app.lang.Gui_MenuBuildStop, wxArtProvider.GetBitmap("AppBuildStop", wxART_TOOLBAR))'wxBitmap.CreateFromFile(IconApp + "Stopp.png", wxBITMAP_TYPE_PNG))
		Self.standardToolBar.Realize()
		Self.standardToolBar.EnableTool(wxID_STOP, False)
		Self.SetToolBar(Self.standardToolBar)
		
		Print "Init~tFrameMain~tNoteBook"
		Self.tabs = wxAuiNotebook.CreateAuiNoteBook(Self, wxID_ANY,,, ,, wxAUI_NB_CLOSE_ON_ACTIVE_TAB | wxAUI_BUTTON_CLOSE | wxAUI_NB_TAB_MOVE | wxAUI_NB_SCROLL_BUTTONS | wxAUI_NB_WINDOWLIST_BUTTON | wxAUI_NB_TAB_SPLIT)
		
		Self.tabs.ConnectAny(wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE, OnClose)
		'Self.editor[0] = TEditorPanel(New TEditorPanel.Create(Self.tabs))
		'Self.tabs.AddPage(Self.editor[0], app.lang.tab_Unnamed, True)
		
		Self.CreateStatusBar(1)
	End Method
	
	Rem
		bbdoc:Erstellt das Menu fuer das FrameMain.
	EndRem
	Method _CreateMenues()
		' Erstellt die Menus
		Self.menuBar = wxMenuBar.CreateMenuBar() ' Erstellt die Menubar
		
		Self.menuFile = wxMenu.CreateMenu() ' Menu -> Datei
			Self.menuFile.Append(wxID_NEW, app.lang.Gui_MenuFileNew, app.lang.Gui_MenuFileNewHelp) ' Datei -> Speichern
			Self.menuFile.Append(wxID_OPEN, app.lang.Gui_MenuFileOpen, app.lang.Gui_MenuFileOpenHelp) ' Datei -> Oeffnen
			Self.menuFile.Append(wxID_SAVE, app.lang.Gui_MenuFileSave, app.lang.Gui_MenuFileSaveHelp) ' Datei -> Speichern
			Self.menuFile.AppendSeparator()
			Self.menuFile.Append(wxID_EXIT, app.lang.Gui_MenuFileExit, app.lang.Gui_MenuFileExitHelp) ' Datei -> Beenden
		Self.menuEdit = wxMenu.CreateMenu() ' Menu -> Bearbeiten
			Self.menuEdit.Append(wxID_UNDO, app.lang.Gui_MenuEditUndo, app.lang.Gui_MenuEditUndoHelp) ' Bearbeiten -> Rueckgaengig
			Self.menuEdit.Append(wxID_REDO, app.lang.Gui_MenuEditRedo, app.lang.Gui_MenuEditRedoHelp) ' Bearbeiten -> Wiederholen
			Self.menuEdit.AppendSeparator()
			Self.menuEdit.Append(wxID_CUT, app.lang.Gui_MenuEditCut, app.lang.Gui_MenuEditCutHelp) ' Bearbeiten -> Ausschneiden
			Self.menuEdit.Append(wxID_COPY, app.lang.Gui_MenuEditCopy, app.lang.Gui_MenuEditCopyHelp) ' Bearbeiten -> Kopieren
			Self.menuEdit.Append(wxID_PASTE, app.lang.Gui_MenuEditPaste, app.lang.Gui_MenuEditPasteHelp) ' Bearbeiten -> Einfuegen
			'Self.menuEdit.Append(wxID_, app.lang.Gui_MenuEdit, app.lang.Gui_MenuEditHelp)
		Self.menuView = wxMenu.CreateMenu()
			Self.menuView.Append(wxID_TOGGLESTRUCTURE, app.lang.Gui_MenuViewStructure, app.lang.Gui_MenuViewStructureHelp, wxITEM_CHECK).Check(Not Self._showStructure) ' Ansicht -> Struktur
		Self.menuBuild = wxMenu.CreateMenu() ' Menu -> Build
			Self.menuBuild.append(wxID_PREVIEW, app.lang.Gui_MenuBuildCompileRun, app.lang.Gui_MenuBuildCompileRunHelp)
			Self.menuBuild.append(wxID_STOP, app.lang.Gui_MenuBuildStop, app.lang.Gui_MenuBuildStopHelp).Enable(False) ' Build -> Stop
			Self.menuBuild.Append(wxID_REFRESHDATABASE, "Read modules")
			Self.menuBuild.Append(wxID_STATIC, app.lang.Gui_MenuBuildLock, app.lang.Gui_MenuBuildLockHelp)
		Self.menuHelp = wxMenu.CreateMenu() ' Menu -> Hilfe
			'Self.menuHelp.Append(wxID_HELP_CONTEXT, app.lang.Gui_MenuHelpHelp, app.lang.Gui_MenuHelpHelpHelp)
			'Self.menuHelp.Append(wxID_ABOUT, app.lang.Gui_MenuHelpAbout, app.lang.Gui_MenuHelpAboutHelp)
		Self.menuTest = wxMenu.CreateMenu() ' Menu -> Test
			Self.menuTest.Append(wxID_DELETE, "delete")
		
		' Fuegt die Menus der MenuBar zu
		Self.menuBar.Append(Self.menuFile, app.lang.Gui_MenuFile) ' Datei
		Self.menuBar.Append(Self.menuEdit, app.lang.Gui_MenuEdit) ' Bearbeiten
		Self.menuBar.Append(Self.menuView, app.lang.Gui_MenuView) ' Ansicht
		Self.menuBar.Append(Self.menuBuild, app.lang.Gui_MenuBuild) ' Build
		Self.menuBar.Append(Self.menuHelp, app.lang.Gui_MenuHelp) ' Hilfe
		Self.menuBar.Append(Self.menuTest, "Test") ' Test
		
		Self.Connect(wxID_DELETE, wxEVT_COMMAND_MENU_SELECTED, del)
		Self.Connect(wxID_NEW, wxEVT_COMMAND_MENU_SELECTED, onNew)
		Self.Connect(wxID_SAVE, wxEVT_COMMAND_MENU_SELECTED, onSave)
		Self.Connect(wxID_OPEN, wxEVT_COMMAND_MENU_SELECTED, onLoad)
		Self.Connect(wxID_CLOSE, wxEVT_COMMAND_MENU_SELECTED, OnClose)
		Self.Connect(wxID_EXIT, wxEVT_COMMAND_MENU_SELECTED, TApp.onQuit)
		Self.Connect(wxID_TOGGLESTRUCTURE, wxEVT_COMMAND_MENU_SELECTED, onToogleStructure)
		Self.Connect(wxID_PREVIEW, wxEVT_COMMAND_MENU_SELECTED, buildAndRun)
		Self.Connect(wxID_STOP, wxEVT_COMMAND_MENU_SELECTED, onStop)
		Self.Connect(wxID_REFRESHDATABASE, wxEVT_COMMAND_MENU_SELECTED, onRefreshDatabase)
		Self.Connect(wxID_STATIC, wxEVT_COMMAND_MENU_SELECTED, onLockBuildFile)
		
		' Connect Events from Menu -> Bearbeiten
		Self.Connect(wxID_UNDO, wxEVT_COMMAND_MENU_SELECTED, onEditUndo)
		Self.Connect(wxID_REDO, wxEVT_COMMAND_MENU_SELECTED, onEditRedo)
		Self.Connect(wxID_CUT, wxEVT_COMMAND_MENU_SELECTED, onEditCut)
		Self.Connect(wxID_COPY, wxEVT_COMMAND_MENU_SELECTED, onEditCopy)
		Self.Connect(wxID_PASTE, wxEVT_COMMAND_MENU_SELECTED, onEditPaste)
		
		Self.SetMenuBar(Self.menuBar) ' Fuegt die MenuBar dem Fenster zu
	EndMethod
	
	Rem
		bbdoc:(De-)Aktiviert die "Stop"-Eintraege, um ein Programm abszubrechen.
	End Rem
	Method MenueStopApplication(enabled:Int)
		Self.menuBuild.FindItemByPosition(1).Enable(enabled)
		Self.standardToolBar.EnableTool(wxID_STOP, enabled)
		Self.standardToolBar.EnableTool(wxID_PREVIEW, Not enabled)
		Self.standardToolBar.Realize()
	End Method
	
	Method showLoadDialog()
		Local dialog:wxFileDialog = New wxFileDialog.Create(Self, app.lang.FileDialog_Load_Title,,, "BlitzMax (*.bmx)|*.bmx", wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_MULTIPLE)
		'Local url:String = wxFileSelector(app.lang.FileDialog_Load_Title,,, ".bmx", "BlitzMax (*.bmx)|*.bmx", wxFD_OPEN | wxFD_FILE_MUST_EXIST | wxFD_MULTIPLE, Self)
		If dialog.ShowModal() = wxID_OK Then
			For Local url:String = EachIn dialog.GetPaths()
				Self.LoadFile(url)
			Next
		EndIf
	End Method
	
	Method showSaveDialog()
		If Not Self.getCurrentEditor() Then Return
		If Self.getCurrentEditor().editor.url = "" Then
			Local url:String = wxFileSelector(app.lang.FileDialog_Save_Title,,, ".bmx", "BlitzMax (*.bmx)|*.bmx", wxFD_SAVE | wxFD_OVERWRITE_PROMPT, Self)
			Self.saveFile(Self.getCurrentEditor(), url)
		Else
			Self.getCurrentEditor().editor.saveFile(Self.getCurrentEditor().editor.url)
		EndIf
	End Method
	
	Method LoadFile(url:String)
		If url <> "" Then
			url = url.Replace("\", "/") 'Replace(url, "\", "/")
			Print url
			Local edit:TEditorPanel
			For edit = EachIn app.frameMain.editor
				If edit.editor.url = url Then Exit
				edit = Null
			Next
			If edit = Null Then
				edit = TEditorPanel(New TEditorPanel.Create(app.frameMain.tabs, wxID_ANY,,, ,, wxSP_NOBORDER))
				edit.editor.LoadFile(url)
				edit.editor.url = url
				edit.editor.Name = StripAll(url)
				Self._addEditor(edit)
				edit.editor.LexxDocument()
			Else
				Self.BringEditorToFront(edit)
			EndIf
		EndIf
	End Method
	
	Method saveFile(editor:TEditorPanel, url:String) ' noch etwas verbugt (vorletzte Zeile)
		If url <> "" Then
			url = url.Replace("\", "/") 'Replace(url, "\", "/")
			editor.editor.saveFile(url)
			editor.editor.url = url
			editor.editor.name = StripAll(url)
			app.frameMain.tabs.SetPageText(app.frameMain.tabs.GetSelection(), StripAll(url)) '<-- muss ueberarbeitet werden.
		EndIf
	End Method
	
	Method createDebugDialog:TDebugPanel()
		If TDebugPanel.instance <> Null Then
			TDebugPanel.instance.Clear()
			Return TDebugPanel.instance
		EndIf
		Local debugPanel:TDebugPanel = TDebugPanel(New TDebugPanel.Create(Self.tabs))
		Local tmpPageIndex:Int = app.frameMain.tabs.GetSelection()
		app.frameMain.tabs.AddPage(debugPanel, app.lang.tab_Debug)
		Local pageIndex:Int = app.frameMain.tabs.GetPageIndex(debugPanel)
		app.frameMain.tabs.Split(pageIndex, wxBOTTOM)
		app.frameMain.tabs.SetSelection(tmpPageIndex)
	End Method
	
	Method getCurrentEditor:TEditorPanel()
		If Self.tabs.GetSelection() = -1 Then Return Null
		Return TEditorPanel(Self.tabs.GetPage(Self.tabs.GetSelection()))
	End Method
	
	Method getBuildEditor:TEditorPanel()
		If Self._buildEditor <> Null Then
			Return Self._buildEditor
		Else
			Return Self.getCurrentEditor()
		End If
	End Method
	
	Method CloseEditor(editor:TEditorPanel)
		Self.tabs.RemoveChild(editor)
		Self.editor.Remove(editor)
	End Method
	
	Method BringEditorToFront(editor:TEditorPanel)
		Local i:Int = Self.GetTabPageFromEditor(editor)
		If i >= 0 Then
			Self.tabs.SetSelection(i)
		End If
	End Method
	
	Method _addEditor(editor:TEditorPanel)
		Self.editor.AddLast(editor)
		Self.tabs.AddPage(editor, editor.editor.Name, True)
	End Method
	
	Rem
		bbdoc:Gibt zu den uebergebenen Editor dessen Page-Zahl zurueck.
	EndRem
	Method GetTabPageFromEditor:Int(Editor:TEditorPanel)
		'For Local Editor2:TEditorPanel = EachIn Self.tabs.GetChildren()
		For Local i:Int = 0 Until Self.tabs.GetPageCount()
			If Editor = Self.tabs.GetPage(i) Then
				Return i
			End If
		Next
		Return - 1
	End Method
	
	Rem
		bbdoc:Öffnet den Editor und springt an die übergebene Zeile.
	EndRem
	Method OpenEditorOnLine(url:String, line:Int)
		Local edit:TEditorPanel = Self.GetEditor(url)
		If edit = Null Then
			Self.LoadFile(url)
			edit = Self.GetEditor(url)
		End If
		edit.editor.GotoLine(line)
	End Method
	
	Rem
		bbdoc:Gibt einen Editor fuer einen bestimmten Pfad zurueck.
	EndRem
	Method GetEditor:TEditorPanel(url:String)
		For Local edit:TEditorPanel = EachIn Self.editor
			If edit.editor.url = url Then
				Return edit
			End If
		Next
	End Method
	
	Rem
		bbdoc:Lockt das Build-File (oder aendert das Lock)
	End Rem
	Method ToogleLockFile(value:Int = -1)
		If value = -1 Then value = (Self._buildEditor = Null)
		If Not value Then
			Self.tabs.SetPageText(Self.GetTabPageFromEditor(Self._buildEditor), Self._buildEditor.editor.Name)
			Self._buildEditor = Null
		Else
			Self._buildEditor = Self.getCurrentEditor()
			Self.tabs.SetPageText(Self.GetTabPageFromEditor(Self._buildEditor), "<Build> " + Self._buildEditor.editor.Name)
		End If
	End Method
	
	Rem
		bbdoc:Schaltet um, ob die Codestruktur angezeigt wird.
	EndRem
	Method ToogleStructure()
		Self._showStructure = Not Self._showStructure
		Self.menuView.FindItemByPosition(0).Check(Not Self._showStructure)
		Settings.Set("ShowStructure", Self._showStructure)
		For Local editor:TEditorPanel = EachIn Self.editor
			editor.SetStructureVisible(Self._showStructure)
		Next
	End Method
End Type
