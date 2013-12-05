Function onHelp(event:wxEvent)
	Print "onhelp"
EndFunction

Function onStop(event:wxEvent)
	app.compileForceClose = True
End Function

Function onLockBuildFile(event:wxEvent)
	app.frameMain.ToogleLockFile()
End Function

Function onToogleStructure(event:wxEvent)
	app.frameMain.ToogleStructure()
End Function

Function onRefreshDatabase(event:wxEvent)
	' Liesst alle Module neu ein.
	Local trm:TReadMods = New TReadMods
	trm.Load(app.compile.GetBlitzMaxPath() + "/mod")
	trm.saveAsXml("./Module.xml")
	TKeyword.instance.Load()
	Notify "database Refreshed"
	Local KeyWords:String = TKeyword.instance.ToString().ToLower()
	If app.frameMain <> Null Then
		For Local editor:TEditorPanel = EachIn app.frameMain.editor
			editor.editor.SetKeywords(0, KeyWords)
		Next
	EndIf
End Function

Function onEditCut(event:wxEvent)
	app.frameMain.getCurrentEditor().editor.Cut()
End Function

Function onEditCopy(event:wxEvent)
	app.frameMain.getCurrentEditor().editor.Copy()
End Function

Function onEditPaste(event:wxEvent)
	app.frameMain.getCurrentEditor().editor.Paste()
End Function

Function onEditUndo(event:wxEvent)
	app.frameMain.getCurrentEditor().editor.Undo()
End Function

Function onEditRedo(event:wxEvent)
	app.frameMain.getCurrentEditor().editor.Redo()
End Function

Function onSave(event:wxEvent)
	app.frameMain.showSaveDialog()
End Function

Function onLoad(event:wxEvent)
	app.frameMain.showLoadDialog()
End Function

Function onNew(event:wxEvent)
	Local Editor:TEditorPanel = TEditorPanel(New TEditorPanel.Create(app.frameMain.tabs))
	Editor.Editor.Name = app.lang.tab_Unnamed
	app.frameMain._addEditor(Editor)
End Function

Function onCompile(event:wxEvent)
	onSave(event)
EndFunction

Function onKeyEvent(event:wxEvent)
	' Hier werden ein paar Spezialtasten(-kombinationen) behandelt.
	Local sel:TEditor = TEditor(event.userData)
	Local keyEvent:wxKeyEvent = wxKeyEvent(event)
	If sel Then sel.myOnKeyEvent(keyEvent)
End Function

Function handleMouse(event:wxEvent)
	Local mouseEvent:wxMouseEvent = wxMouseEvent(event)
	If TEditor(event.userData) <> Null Then
		TEditor(event.userData).myOnMouseEvent(mouseEvent)
	Else
		app.setStatusText("mouseEvent: " + mouseEvent.getEventType() + " - " + MilliSecs())
	End If
	event.Skip(True)
	'TEditor(event.userData).parseLastWord()
End Function

Function OnClose(event:wxEvent)
	If app.frameMain.getCurrentEditor() = Null Then Return
	app.frameMain.CloseEditor(app.frameMain.getCurrentEditor())
End Function
