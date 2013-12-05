
Const DEBUG_WarnOnXmlMissingAttribute:Int = False ' Betrifft den "Type Scope" (w2.bmx)
Const DEBUG_InfoOnSinglelineIfs:Int = True ' Betrifft den "Type Scope" (w2.bmx)

Const wxID_REFRESHDATABASE:Int = wxID_HIGHEST + 1
Const wxID_TOGGLESTRUCTURE:Int = wxID_HIGHEST + 2

Global app:TApp = TApp(New TApp) ' Instance der App erzeugen
app.run

Type TApp Extends wxAppMain
	Field frameMain:TFrameMain
	Field AutoComp:TEditorAutoComplete
	Global forceClose:Int = False ' True = Beendet die IDE.
	Global compileForceClose:Int = False ' True = Zwingt das zu debuggende Programm sich zu beenden
	Global _s:Scope ' Scope welches alle Module enthaelt.
	Field compileRun:Int = False ' False = Kein Programm wird ausgefuehrt
	Field compileProc:TProcess
	Field compile:TCompile
	Field lang:TLanguage
	
	Function getModulScope:Scope()
		Return TApp._s
	End Function
	
	Rem
		bbdoc:Initialisiert alle Resourcen (ImageHandler, Provider, ...)
	End Rem
	Method OnInitResources()
		wxImage.AddHandler(New wxPNGHandler)
		wxImage.AddHandler(New wxXPMHandler)
		Local tmp1:TArtProvider = TArtProvider(New TArtProvider.Create())
		wxInitAllImageHandlers()
		wxArtProvider.Push(tmp1)
	End Method
	
	Rem
		bbdoc:Initialisiert/Lädt die Einstellungen
	End Rem
	Method OnInitSettings()
		TSettings.LoadXML("./Config.xml")
		Settings.SetDefault("WindowX", -1)
		Settings.SetDefault("WindowY", -1)
		Settings.SetDefault("WindowW", 700)
		Settings.SetDefault("WindowH", 500)
		Settings.SetDefault("ShowStructure", True)
		Settings.SetDefault("TabWidth", 4)
		Settings.SetDefault("Language", "de")
		Settings.SetDefault("AutoComp", 1) ' 0=Disabled, 1=Enabled, 2=Custom[TEditorAutoComplete]
	End Method
	
	Rem
		bbdoc:Initialisiert den Compiler-Wrapper-Helfer-Typ
	End Rem
	Method OnInitCompile()
		' Lade aus Settings und untersuche häufige Pfade
		Local BlitzMaxPath:String = Settings.Get("BlitzMaxPath")
		If BlitzMaxPath = "" Or FileType(BlitzMaxPath) <> FILETYPE_DIR Then
		?Win32
			Select FILETYPE_DIR
				Case FileType("C:/Program Files (x86)/BlitzMax")
					BlitzMaxPath = "C:/Program Files (x86)/BlitzMax"
				Case FileType("C:/Program Files/BlitzMax")
					BlitzMaxPath = "C:/Program Files/BlitzMax"
				Case FileType("C:/Programme/BlitzMax")
					BlitzMaxPath = "C:/Programme/BlitzMax"
				Default
					BlitzMaxPath = ""
			End Select
		?Not Win32
			BlitzMaxPath = getenv_("HOME") + "/.blitzmax"
		?
			If FileType(BlitzMaxPath) <> FILETYPE_DIR Then
				If Settings.Get("BlitzMaxPath") <> BlitzMaxPath Then
					Settings.Set("BlitzMaxPath", BlitzMaxPath)
				End If
			End If
		EndIf
		
		' Frag den Benutzer.
		While TCompile.IsValidBlitzMaxPath(BlitzMaxPath)
			DebugLog "BlitzMaxPath not valid: ~q" + BlitzMaxPath + "~q"
			BlitzMaxPath = wxDirSelector(lang.FileDialog_BMaxDir_Title)
			If BlitzMaxPath = "" Then End
		Wend
		Settings.Set("BlitzMaxPath", BlitzMaxPath)
		
		Self.compile = New TCompile.Create(BlitzMaxPath)
	End Method
	
	Method OnInitLanguage()
		Self.lang = TLanguage.Create("./lang_" + settings.Get("Language") + ".xml") ' Erstellen der lang
	End Method
	
	Method OnInitAutoComp()
		' Erstelle Container-Objekte.
		New TKeyword
		Scope.LoadFromXML("Module.xml")
		New TAutoComp
		Self.AutoComp = TEditorAutoComplete(New TEditorAutoComplete.Create(Self.frameMain,, "AutoComplete",,, 170, 200, wxFRAME_FLOAT_ON_PARENT | wxFRAME_NO_TASKBAR | wxSYSTEM_MENU | wxRESIZE_BORDER))
	End Method
	
	Method OnInitFrameMain()
		Self.frameMain = TFrameMain(New TFrameMain.Create(Null,, My.Application.Name, Int(Settings.Get("WindowX")), Int(Settings.Get("WindowY")), Int(Settings.Get("WindowW")), Int(Settings.Get("WindowH")), wxDEFAULT_FRAME_STYLE | wxSYSTEM_MENU | wxMAXIMIZE)) ' Hauptfenster erstellen
		Self.SetTopWindow(Self.frameMain) ' Hauptfenster als Hauptfenster deklarieren
		Self.frameMain.Show() ' Hauptfenster anzeigen
		Self.frameMain.ConnectAny(wxEVT_CLOSE , Self.onQuit)
	End Method
	
	Method OnInit:Int()
		Print "Init~tMain"
		Self.SetAppName(My.Application.Name)
		Print "Init~tResources"
		Self.OnInitResources
		Print "Init~tSettings"
		Self.OnInitSettings
		Print "Init~tCompile"
		Self.OnInitCompile
		Print "Init~tLanguage"
		Self.OnInitLanguage
		Print "Init~tFrameMain"
		Self.OnInitFrameMain
		Print "Init~tAutoComp"
		Self.OnInitAutoComp
		
		Print "Init~tOpen recent files"
		Local filePaths:String[] = String(Settings.Get("RecentFiles")).Split("|")
		For Local filePath:String = EachIn filePaths
			Self.frameMain.LoadFile(filePath)
		Next
		'Self.helpWindow = TTest(New TTest.Create(Self.frameMain,,, ,, ,, wxBORDER_SIMPLE | wxFRAME_TOOL_WINDOW))
		Self.frameMain.MenueStopApplication(False) ' Stopp-Menueintrag deaktivieren.
		
		Print "Init~tDone"
		Return True
	End Method
	
	Method MainLoop:Int()
		While True
			While Not Pending() And ProcessIdle()
			Wend
			While Pending()
				dispatch()
			Wend
			If TApp.forceClose Then
				Print "Closing the Application NOW"
				Return 0
			End If
			
			If Self.compileRun Then
				If Self.compileProc.pipe.ReadAvail() Then
					' Es wurde in die "normale" Konsolen-ausgabe geschrieben.
					TDebugPanel.addDebugMessage(ReadStream(Self.compileProc.pipe))
				EndIf
				If Self.compileProc.err.ReadAvail() Then
					' Es wurde in die "Fehler" Konsolen-ausgabe geschrieben.
					TDebugPanel.addDebugMessage("Error: " + ReadStream(Self.compileProc.err))
				EndIf
				If TApp.compileForceClose Then
					' Programm beenden (auch wenn es sich noch so sehr wehrt)
					If Self.compileProc <> Null Then Self.compileProc.Terminate()
					Self.setProgStopped()
				EndIf
				If Not Self.compileProc.Status() Then
					' Programm hat sich beendet.
					Self.setProgStopped()
				EndIf
			EndIf
		Wend
	End Method
	
	Rem
	bbdoc:Setzt ein Programm auf die "wird ausgefuehrt"-liste
	EndRem
	Method setProgRunnint(proc:TProcess)
		Self.compileProc = proc
		Self.compileRun = True
		Self.compileForceClose = False
		Self.frameMain.MenueStopApplication(True) ' Stopp-Menueintrag aktivieren.
	End Method
	
	Rem
	bbdoc:Setzt den "Programm gestoppt"-Status.
	EndRem
	Method setProgStopped()
		TDebugPanel.addDebugMessage(Chr(10))
		TDebugPanel.addDebugMessage("---------------" + Chr(10))
		TDebugPanel.addDebugMessage("- The End -" + Chr(10))
		
		Self.compileRun = False
		Self.compileForceClose = False
		Self.frameMain.MenueStopApplication(False) ' Stopp-Menueintrag deaktivieren.
	End Method
	
	Rem
		bbdoc:Setzt den Uebergebenen Text als statustext (zu debug-zwecken)
	EndRem
	Method SetStatusText(text:String)
		Self.frameMain.SetStatusText(text)
		'DebugLog "Status: " + text
	End Method
	
	Rem
		bbdoc:Sichert die aktuellen Einstellungen.
	End Rem
	Method SaveSettings()
		' frameMain - Positionen und Groesse.
		Local frameMainX:Int, frameMainY:Int, frameMainWidth:Int, frameMainHeight:Int
		frameMain.GetScreenPosition(frameMainX, frameMainY)
		frameMain.GetSize(frameMainWidth, frameMainHeight)
		Settings.Set("WindowX", frameMainX)
		Settings.Set("WindowY", frameMainY)
		Settings.Set("WindowW", frameMainWidth)
		Settings.Set("WindowH", frameMainHeight)
		
		' geoffnete Dokumente.
		Local tmpS:String = ""
		For Local editor:TEditorPanel = EachIn .app.frameMain.editor
			tmpS:+editor.editor.url + "|"
		Next
		Settings.Set("RecentFiles", tmpS[..(tmpS.Length - 1)]) 
		Settings.Save("./Config.xml")
	End Method
	
	Function onQuit(event:wxEvent)
		TApp.forceClose = True
		
		.app.SaveSettings()
		
		DebugLog "Last Status Text: " + TApp(TApp.app).frameMain.GetStatusBar().GetStatusText()
		.app.frameMain.auiManager.UnInit
		.app.frameMain.Destroy
		
	End Function
End Type

Function ReadStream:String(pipe:TPipeStream)
	If pipe.ReadAvail() Then
		Local str:String = ""
		While pipe.ReadAvail()
			str:+Chr(pipe.ReadByte())
		Wend
		Return str
	EndIf
End Function

Function buildAndRun(event:wxEvent)
	onSave(event)
	If Not app.frameMain.getBuildEditor() Then Return
	Local editor:TEditor = app.frameMain.getBuildEditor().editor
	
	app.compile.Build(editor.getUrl())
End Function

Function del(event:wxEvent)
	Local editorPanel:TEditorPanel = app.frameMain.getCurrentEditor()
	'editorPanel.editor.LexxDocument()
	
	For Local e:TEditorPanel = EachIn app.frameMain.editor
		e.editor.LexxDocument()
	Next
End Function

Type TDebugPanel Extends wxPanel
	Global instance:TDebugPanel
	Field output:wxTextCtrl
	
	Rem
		bbdoc:Fuegt eine Debugmessage, dem Debugpanel, hinzu.
	EndRem
	Function addDebugMessage(message:String = "")
		message = message.Replace(Chr(13), "")
		TDebugPanel.instance.output.AppendText(message)
	End Function
	
	Rem
	bbdoc:Called during window creation.
	End Rem
	Method OnInit()
		TDebugPanel.instance = Self
		Local sizer:wxBoxSizer = wxBoxSizer.CreateBoxSizer(wxVERTICAL)
		Self.SetSizer(sizer)
		Self.output = wxTextCtrl.CreateTextCtrl(Self, wxID_ANY,,, ,, , wxTE_DONTWRAP | wxTE_AUTO_SCROLL | wxTE_MULTILINE)
		
		sizer.add(Self.output, 1, wxEXPAND | wxALL, 0)
	End Method

	Rem
		bbdoc:Clears the Output.
	End Rem
	Method Clear()
		Self.output.Clear()
	End Method

End Type

Type TAutoComp
	Global instance:TAutoComp
	Method New()
		Assert TAutoComp.instance = Null
		TAutoComp.instance = Self
	End Method
	
	Rem
	bbdoc:Liefert moegliche weiterfuehrende Befehle zu dem uebergebenen anfang zurueck
	End Rem
	Method getHintKeyword:String(anfang:String)
		'Print"autoComp.getHintKeyword(" + anfang + ")"
		Local hintS:String
		Local kw:TKeyword_kw
		anfang = anfang.ToLower()
		
		For kw = EachIn TKeyword.instance.kwList
			If Left(kw.KeyWord, anfang.Length) = anfang Then
				hintS = hintS + kw.Syntax + " "
			End If
		Next
		'Print"autoComp -> return ~q" + Left(hintS, hintS.Length - 1) + "~q"
		
		Return Left(hintS, hintS.Length - 1)
	End Method
	
	Rem
	bbdoc:Liefert alle Elemente einer Klasse
	EndRem
	Method getHintType:String(typeName:String, anfang:String)
		Local hintS:String
		Local node:TxmlNode, child:TxmlNode
		typeName = typeName.ToLower()
		anfang = anfang.ToLower()
		For node = EachIn TKeyword.instance.types
			If node.getAttribute("name").ToLower() = typeName Then
				For child = EachIn node.getChildren()
					If child.getAttribute("name")[0..(anfang.Length)].ToLower() = anfang Then
						hintS = hintS + child.getAttribute("name") + " "
					End If
				Next
				Return hintS[0..(hintS.Length - 1)]
			EndIf
		Next
		Return ""
	End Method
End Type














