Rem
	bbdoc:Language type
End Rem
Type TLanguage
	Global _instance:TLanguage
	'#Region Menue-Texte
	Field Gui_MenuFile:String
	Field Gui_MenuFileNew:String, Gui_MenuFileNewHelp:String
	Field Gui_MenuFileOpen:String, Gui_MenuFileOpenHelp:String
	Field Gui_MenuFileSave:String, Gui_MenuFileSaveHelp:String
	Field Gui_MenuFileClose:String, Gui_MenuFileCloseHelp:String
	Field Gui_MenuFileExit:String, Gui_MenuFileExitHelp:String
	
	Field Gui_MenuEdit:String
	Field Gui_MenuEditUndo:String, Gui_MenuEditUndoHelp:String
	Field Gui_MenuEditRedo:String, Gui_MenuEditRedoHelp:String
	Field Gui_MenuEditCut:String, Gui_MenuEditCutHelp:String
	Field Gui_MenuEditCopy:String, Gui_MenuEditCopyHelp:String
	Field Gui_MenuEditPaste:String, Gui_MenuEditPasteHelp:String
	
	Field Gui_MenuView:String
	Field Gui_MenuViewStructure:String, Gui_MenuViewStructureHelp:String
	
	Field Gui_MenuBuild:String
	Field Gui_MenuBuildStop:String, Gui_MenuBuildStopHelp:String
	Field Gui_MenuBuildCompileRun:String, Gui_MenuBuildCompileRunHelp:String
	Field Gui_MenuBuildLock:String, Gui_MenuBuildLockHelp:String
	
	Field Gui_MenuHelp:String
	Field Gui_MenuHelpHelp:String, Gui_MenuHelpHelpHelp:String
	Field Gui_MenuHelpAbout:String, Gui_MenuHelpAboutHelp:String
	'#EndRegion
	
	Field FileDialog_Save_Title:String
	Field FileDialog_Load_Title:String
	Field FileDialog_BMaxDir_Title:String
	
	Field fatalError_keywordFileCorrupt:String
	Field fatalError_keywordFileMissing:String
	
	Field error_programmDosntStart:String
	Field error_keywordXmlNotParsed:String
	
	Field tab_Unnamed:String
	Field tab_Debug:String
	
	Function GetInstance:TLanguage()
		Return TLanguage._instance
	End Function
	
	rem
		bbdoc:Laedt die Einkompilierte (Deutsche) Sprache
	endrem
	Method createDefault()
		Self.Gui_MenuFile = "&Datei"
			Self.Gui_MenuFileNew = "&Neu~tCtrl-N"; Self.Gui_MenuFileNewHelp = "Erstellt eine neue BlitzMax Datei."
			Self.Gui_MenuFileOpen = "Oeffnen~tCtrl-O"; Self.Gui_MenuFileOpenHelp = "Laedt eine BlitzMax Datei."
			Self.Gui_MenuFileSave = "&Speichern~tCtrl-S"; Self.Gui_MenuFileSaveHelp = "Speichert die aktuelle BlitzMax Datei."
			Self.Gui_MenuFileClose = "S&chlieszen~tCtrl-F4"; Self.Gui_MenuFileSaveHelp = "Schlieszt den aktuellen Tab."
			Self.Gui_MenuFileExit = "B&eenden~tCtrl-Q"; Self.Gui_MenuFileExitHelp = "Beendet das Programm."
		Self.Gui_MenuEdit = "&Bearbeiten"
			Self.Gui_MenuEditUndo = "&Rueckgaengig~tCtrl-Z"; Self.Gui_MenuEditUndoHelp = "Macht eine Aenderung rueckgaengig."
			Self.Gui_MenuEditRedo = "&Wiederholen~tCtrl-Y"; Self.Gui_MenuEditRedoHelp = "Stellt eine rueckgaengig gemachte Aenderung wieder her."
			Self.Gui_MenuEditCut = "&Ausschneiden~tCtrl-X"; Self.Gui_MenuEditCutHelp = "Schneidet den gewaehlten Textbereich aus."
			Self.Gui_MenuEditCopy = "&Kopieren~tCtrl-C"; Self.Gui_MenuEditCopyHelp = "Kopiert den ausgewaehlten Textbereich."
			Self.Gui_MenuEditPaste = "&Einfuegen~tCtrl-V"; Self.Gui_MenuEditPasteHelp = "Fuegt den Text aus der Zwischenablage ein."
			'Self.Gui_MenuEdit = ""; Self.Gui_MenuEditHelp = ""
		Self.Gui_MenuView = "&Ansicht"
			Self.Gui_MenuViewStructure = "Dateistruktur umschalten"; Self.Gui_MenuViewStructureHelp = "Schaltet die Strukturansicht fuer alle Dateien Ein/Aus."
		Self.Gui_MenuBuild = "B&uild"
			Self.Gui_MenuBuildStop = "&Stopp"; Self.Gui_MenuBuildStopHelp = "Stoppt die aktuell laufende Anwendung."
			Self.Gui_MenuBuildCompileRun = "Compile and Run~tF5";Self.Gui_MenuBuildCompileRunHelp = "..."
			Self.Gui_MenuBuildLock = "Lock buildfile"; Self.Gui_MenuBuildLockHelp = "..."
		Self.Gui_MenuHelp = "&Hilfe"
			Self.Gui_MenuHelpHelp = "&Hilfe~tF1"; Self.Gui_MenuHelpHelp = "Zeigt die programminterne Hilfe an."
			Self.Gui_MenuHelpAbout = "&Info"; Self.Gui_MenuHelpAboutHelp = "Zeigt Informationen zu dem Programm an."
		
		Self.FileDialog_Save_Title = "Datei speichern unter..."
		Self.FileDialog_Load_Title = "Datei oeffnen..."
		Self.FileDialog_BMaxDir_Title = "Bitte den Pfad zu der BlitzMax Installation angeben."
		
		Self.tab_Unnamed = "Unbenannt"
		Self.tab_Debug = "Konsole"
		
		Self.fatalError_keywordFileCorrupt = "Die ~qkeyword.txt~q Datei ist beschaedigt.~nBitte laden sie das Programm oder die Datei neu herunter."
		Self.fatalError_keywordFileMissing = "Die ~qkeyword.txt~q Datei kann nicht geoeffnet werden.~nBitte laden sie das Programm oder die Datei neu herunter."
		
		Self.error_programmDosntStart = "Das Programm konnte nicht ausgefuehrt werden"
		Self.error_keywordXmlNotParsed = "Die Keyword xml Datei (Module.xml) konnte nicht geparst werden"
	End Method
	
	rem
		bbdoc:Erstellt das Objekt und guckt, welche aktionen durchgefuehrt werden muessen.
	endrem
	Function Create:TLanguage(url:String = Null)
		Local tl:TLanguage = New TLanguage
		If url = Null Or FileType(url) = 0 Then
			Rem
				wenn keine Datei gewaehlt ist
			EndRem
			tl.createDefault()
		Else ' wenn die Datei vorhanden ist
			tl.Load(url)
		EndIf
		Return tl
	End Function
	
	rem
		bbdoc:Laedt eine Sprache aus einer Datei
	endrem
	Method Load(url:String)
		Local doc:TxmlDoc = TxmlDoc.parseFile(url)
		If doc Then
			Local root:TxmlNode = doc.getRootElement()
			For Local node:TxmlNode = EachIn root.getChildren()
				Select node.getName().ToLower()
					Case "file"
						Self.Gui_MenuFile = node.getAttribute("text")
						Self._LoadSubNodes(node, node.getName().ToLower())
					Case "edit"
						Self.Gui_MenuEdit = node.getAttribute("text")
						Self._LoadSubNodes(node, node.getName().ToLower())
					Case "view"
						Self.Gui_MenuView = node.getAttribute("text")
						Self._LoadSubNodes(node, node.getName().ToLower())
					Case "build"
						Self.Gui_MenuBuild = node.getAttribute("text")
						Self._LoadSubNodes(node, node.getName().ToLower())
					Case "help"
						Self.Gui_MenuHelp = node.getAttribute("text")
						Self._LoadSubNodes(node, node.getName().ToLower())
				End Select
			Next
		End If
	End Method
	
	Method _LoadSubNodes(root:TxmlNode, name:String)
		For Local node:TxmlNode = EachIn root.getChildren()
			Select root.getName().ToLower()
				Case "file"
					Select node.getName().ToLower()
						Case "new"
							Self.Gui_MenuFileNew = node.getAttribute("text")
							Self.Gui_MenuFileNewHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuFileNew:+"~t" + node.getAttribute("shortcut")
						Case "open"
							Self.Gui_MenuFileOpen = node.getAttribute("text")
							Self.Gui_MenuFileOpenHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuFileOpen:+"~t" + node.getAttribute("shortcut")
						Case "save"
							Self.Gui_MenuFileSave = node.getAttribute("text")
							Self.Gui_MenuFileSaveHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuFileSave:+"~t" + node.getAttribute("shortcut")
						Case "close"
							Self.Gui_MenuFileClose = node.getAttribute("text")
							Self.Gui_MenuFileCloseHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuFileClose:+"~t" + node.getAttribute("shortcut")
						Case "exit"
							Self.Gui_MenuFileExit = node.getAttribute("text")
							Self.Gui_MenuFileExitHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuFileExit:+"~t" + node.getAttribute("shortcut")
					End Select
				Case "edit"
					Select node.getName().ToLower()
						Case "undo"
							Self.Gui_MenuEditUndo = node.getAttribute("text")
							Self.Gui_MenuEditUndoHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuEditUndo:+"~t" + node.getAttribute("shortcut")
						Case "redo"
							Self.Gui_MenuEditRedo = node.getAttribute("text")
							Self.Gui_MenuEditRedoHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuEditRedo:+"~t" + node.getAttribute("shortcut")
						Case "cut"
							Self.Gui_MenuEditCut = node.getAttribute("text")
							Self.Gui_MenuEditCutHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuEditCut:+"~t" + node.getAttribute("shortcut")
						Case "copy"
							Self.Gui_MenuEditCopy = node.getAttribute("text")
							Self.Gui_MenuEditCopyHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuEditCopy:+"~t" + node.getAttribute("shortcut")
						Case "paste"
							Self.Gui_MenuEditPaste = node.getAttribute("text")
							Self.Gui_MenuEditPasteHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuEditPaste:+"~t" + node.getAttribute("shortcut")
					End Select
				Case "view"
					Select node.getName().ToLower()
						Case "structur"
							Self.Gui_MenuViewStructure = node.getAttribute("text")
							Self.Gui_MenuViewStructureHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuViewStructure:+"~t" + node.getAttribute("shortcut")
					End Select
				Case "build"
					Select node.getName().ToLower()
						Case "stop"
							Self.Gui_MenuBuildStop = node.getAttribute("text")
							Self.Gui_MenuBuildStopHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuBuildStop:+"~t" + node.getAttribute("shortcut")
						Case "compilerun"
							Self.Gui_MenuBuildCompileRun = node.getAttribute("text")
							Self.Gui_MenuBuildCompileRunHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuBuildCompileRun:+"~t" + node.getAttribute("shortcut")
						Case "lock"
							Self.Gui_MenuBuildLock = node.getAttribute("text")
							Self.Gui_MenuBuildLockHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuBuildLock:+"~t" + node.getAttribute("shortcut")
					End Select
				Case "help"
					Select node.getName().ToLower()
						Case "help"
							Self.Gui_MenuHelpHelp = node.getAttribute("text")
							Self.Gui_MenuHelpHelpHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuHelpHelp:+"~t" + node.getAttribute("shortcut")
						Case "about"
							Self.Gui_MenuHelpAbout = node.getAttribute("text")
							Self.Gui_MenuHelpAboutHelp = node.getAttribute("help")
							If node.hasAttribute("shortcut") Then Self.Gui_MenuHelpAbout:+"~t" + node.getAttribute("shortcut")
					End Select
			End Select
		Next
	End Method
End Type
