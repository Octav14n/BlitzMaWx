Type TEditorPanel Extends wxSplitterWindow
	Field editor:TEditor
	Field objects:TObjectTree
	
	Method OnInit()
		Self.editor = TEditor(New TEditor.Create(Self)) ' Erstellt den Editor
		Self.editor.panel = Self
		Self.objects = TObjectTree(New TObjectTree.Create(Self, wxID_ANY,,, 150,, wxTR_FULL_ROW_HIGHLIGHT | wxTR_HAS_BUTTONS | wxTR_HIDE_ROOT | wxTR_LINES_AT_ROOT))
		Self.objects.panel = Self
		
		Self.editor.SetFocus()
		
		Self.SetSplitMode(wxSPLIT_VERTICAL)
		Self.SplitVertically(Self.editor, Self.objects, -100)
		Self.SetStructureVisible(Int(Settings.Get("ShowStructure")))
		
		Self.ConnectAny(wxEVT_COMMAND_SPLITTER_UNSPLIT, TEditorPanel.onUnsplit)
	End Method
	
	Function onUnsplit(event:wxEvent)
		' Wenn ein teil des Splitters "Verschwindet".
		'TODO: Unsplit-EventHandler implementieren.
	End Function
	
	Method SetStructureVisible(Value:Int)
		If Not Value Then
			'If Self.IsSplit() Then
			Self.Unsplit(Self.objects)
			'End If
		Else
			'If Not Self.IsSplit() Then
			Self.SplitVertically(Self.editor, Self.objects, -100)
			'End If
		End If
	End Method
End Type

Type TEditor Extends wxScintilla
	Field Name:String
	Field url:String
	Field lockUpdate:Int = False
	Field panel:TEditorPanel
	Field CalltipLastPosition:Int
	Field s:Scope
	Field _showAutoComp:Int = False
	
	Method OnInit()
		Self.SetMarginWidth(0 , 36) ' Zeilennummer-breite definieren.
		Self._initFolding()
		
		Self.ConnectAny(wxEVT_SCI_CHARADDED, TEditor.OnUpdate, Self)
		Self.ConnectAny(wxEVT_KEY_DOWN, onKeyEvent, Self)
		Self.ConnectAny(wxEVT_MOUSE_EVENTS , handleMouse , Self)
		Self.ConnectAny(wxEVT_SCI_MARGINCLICK, TEditor.onMarginClick, Self)
		
		Local font:wxFont = New wxFont.CreateWithAttribs(12, wxFONTFAMILY_MODERN, wxNORMAL, wxNORMAL)
		
		Self.SetLexer(wxSCI_LEX_BLITZBASIC)
		Self.SetLexerLanguage("blitzmax")
		Self.SetCodePage(wxSCI_CP_UTF8)
		Self.SetKeywords(0, TKeyword.instance.ToString().ToLower())
		Self.StyleSetFontFont(wxSCI_STYLE_DEFAULT , FONT)
		
		Self.SetCaretLineBackground(New wxColour.Create(213, 213, 213))
		Self.SetCaretLineVisible(True)
		
		'LexerKeywords we want Blue
		Self.StyleSetForeground(wxSCI_B_KEYWORD, New wxColour.Create(0, 0, 255))
		
		'Not Rem/EndRem either...
		Self.StyleSetForeground(wxSCI_B_COMMENT, New wxColour.Create(180, 150, 0))
		Self.StyleSetForeground(19, New wxColour.Create(180, 150, 0)) ' es gibt kein "wxSCI_B_COMMENTREM" aber die Zahl dafuer waehre 19.
		
		'Strings we want to be Green
		Self.StyleSetForeground(wxSCI_B_STRING, New wxColour.Create(0, 127, 0))
		
		' Setzt die "Autocompletion" einstellungen
		Self.AutoCompSetSeparator(32) ' Seperator ist das Leerzeichen
		Self.AutoCompSetChooseSingle(True) ' Wenn autocomp aufgerufen wird und nur eine option uebrig bleibt, setze diese ein
		Self.AutoCompSetIgnoreCase(True) ' Es soll nicht auf groß/kleinschreibung geachtet werden
		Self.AutoCompSetDropRestOfWord(True)
		'Rem
		Local variable:wxBitmap = wxArtProvider.GetBitmap("AutocompleteVar", wxART_OTHER)
		Local funct:wxBitmap = wxArtProvider.GetBitmap("AutocompleteFunction", wxART_OTHER)
		Local typ:wxBitmap = wxArtProvider.GetBitmap("AutocompleteType", wxART_OTHER)
		Self.RegisterImage(1, variable)
		Self.RegisterImage(2, funct)
		Self.RegisterImage(3, typ)
		Self.AutoCompSetAutoHide(False)
		'EndRem
		
		Self.UsePopUp(True) ' Rechtsklickmenu
		Self.SetTabWidth(Int(Settings.Get("TabWidth")))
		Self.SetTabIndents(True)
		Self.SetBufferedDraw(True)
		Self.DragAcceptFiles(False)
		
		' CallTip-Einstellungen
		Self.CallTipSetBackground(New wxColour.Create(255, 255, 102))
		Self.CallTipSetForeground(New wxColour.Create(0, 0, 0))
	End Method
	
	Method getUrl:String()
		Return Self.url
	End Method
	
	Rem
		bbdoc:Analysiert das aktuelle Dokument.
	EndRem
	Method LexxDocument()
		If Self.s <> Null Then
			Self.s.Remove()
		End If
		Local ret:Object = Auswerten(Self.GetText(), Self.url)
		If Scope(ret) <> Null Then
			Self.s = Scope(ret)
			Self.panel.objects.CreateFromScope(Self.s)
		ElseIf LexExceptionEnd(ret) <> Null Then
			Local ex:LexExceptionEnd = LexExceptionEnd(ret)
			app.frameMain.BringEditorToFront(Self.panel)
			Self.GotoLine(ex.zeile - 1)
			Self.SetFocus()
			wxMessageBox("TEditor.LexxDocument: Fehler in ~q" + Self.Name + "~q, Zeile " + ex.zeile + "~n" + ex.ToString(), "LexxFehler", wxOK | wxICON_ERROR, Self)
			DebugLog "LexxDocument: Fehler in ~q" + Self.Name + "~q, Zeile " + ex.zeile + ".~n" +  ex.s.GetMainScope().ToString()
		ElseIf LexExceptionBase(ret) <> Null Then
			Local ex:LexExceptionBase = LexExceptionBase(ret)
			app.frameMain.BringEditorToFront(Self.panel)
			Self.GotoLine(ex.zeile - 1)
			Self.SetFocus()
			wxMessageBox("LexxDocument: Fehler in ~q" + Self.Name + "~q, Zeile " + ex.zeile + ".~n" + ex.ToString(), "LexxFehler", wxOK | wxICON_ERROR, Self)
		EndIf
	End Method
	
	Method _initFolding()
		Self.setmargintype(1, wxSCI_MARGIN_SYMBOL)
		Self.setmarginwidth(1, 0)
		Self.setmarginmask(1, wxSCI_MASK_FOLDERS)
		Self.SetMarginWidth(1, 23)
		Self.SetProperty("fold" , 1)
		Self.SetMarginSensitive(1 , 1)
		
		' Definiere, wie die Symbole aussehen sollen.
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDER, wxSCI_MARK_BOXPLUS)
		Self.MarkerSetBackground(wxSCI_MARKNUM_FOLDER, New wxColour.CreateNamedColour("BLACK"))
		Self.MarkerSetForeground(wxSCI_MARKNUM_FOLDER, New wxColour.CreateNamedColour("WHITE"))
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDEROPEN, wxSCI_MARK_BOXMINUS)
		Self.MarkerSetBackground(wxSCI_MARKNUM_FOLDEROPEN, New wxColour.CreateNamedColour("BLACK"))
		Self.MarkerSetForeground(wxSCI_MARKNUM_FOLDEROPEN, New wxColour.CreateNamedColour("WHITE"))
		
		' Symbole, welche benutzt werden.
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDERSUB, wxSCI_MARK_EMPTY)
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDEREND, wxSCI_MARK_SHORTARROW)
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDEROPENMID, wxSCI_MARK_ARROWDOWN)
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDERMIDTAIL, wxSCI_MARK_EMPTY)
		Self.MarkerDefine(wxSCI_MARKNUM_FOLDERTAIL , wxSCI_MARK_EMPTY)
	End Method

	Rem
		bbdoc:Wird vom System aufgerufen, wenn sich der Inhalt, der Textbox veraendert
	End Rem
	Function OnUpdate(evt:wxEvent)
		If TEditor(evt.userData).lockUpdate = True Then Return;
		
		Local w_Start:Int, w_End:Int
		Local sel:TEditor = TEditor(evt.userData) ' Ich hab keine lust immer diesen ganzen firlefanz zu schreiben
		sel.lockUpdate = True
		sel.getActualWord(w_Start, w_End)
		If w_Start <> sel.GetTargetStart() Then
			' es wurde angefangen ein neues Wort zu schreiben
			sel.parseLastWord()
			sel.SetTargetStart(w_Start)
			sel.SetTargetEnd(w_End)
		Else
			sel.SetTargetEnd(w_End)
		EndIf
		'RefreshScope(sel.panel)
		app.frameMain.SetStatusText("[" + sel.GetTargetStart() + " - " + sel.GetTargetEnd() + "]")
		
		If sel._showAutoComp Then
			sel._showAutoComp = False
			sel.showCompletion()
		End If
		
		sel.lockUpdate = False
	End Function
	
	Rem
		bbdoc:Wird aufgerufen, wenn auf den Randbereich geklickt wird.
	EndRem
	Function onMarginClick(event:wxEvent)
		Local p:Int = wxScintillaEvent(event).getPosition()
		
		TEditor(event.GetEventObject()).togglefold(TEditor(event.GetEventObject()).linefromposition(p))
		
		event.Skip()
	End Function

	Rem
		bbdoc:Gibt den Start-Index und den End-Index des momentan geschriebenen wortes zurueck.
	End Rem
	Method getActualWord(wordStart:Int Var, wordEnd:Int Var)
		wordStart = Self.GetCurrentPos()
		wordStart = WordStartPosition(wordStart, 1)
		wordEnd = WordEndPosition(wordStart, 1)
	End Method
	
	Rem
		bbdoc:Zeigt eine Info zu einem bestimmten Wort an. (wenn Pos=-1 ist, wird eine Info zu dem aktuellen Wort angezeigt.)
	EndRem
	Method showInfo(Pos:Int = -1, coordX:Int = -1, coordY:Int = -1)
		If Not Self.AutoCompActive() Then
			If Pos = -1 Then Pos = Self.GetSelectionStart()
			Local s:Scope = Self._getScopeForPosition(Pos)
			If s <> Null Then
				Local CallTip:String = ""
				
				If s._StartLine <> Self.LineFromPosition(Pos) Then
					If s.IsFunction() Then
						CallTip = s._Name
						If s._Type <> "void" Then CallTip:+":" + s._Type
						Local paramS:String = "", paramA:Scope[] = s.GetChilds()
						For Local param:Scope = EachIn paramA
							If param.IsParameter() Then
								paramS:+param._Name + ":" + param._Type + ", "
							End If
						Next
						CallTip:+"(" + paramS[..(paramS.Length - 2)] + ")"
					ElseIf s.IsVariable() Then
						CallTip = s._Name + ":" + s._Type
						If s._DefaultValue <> "" Then
							CallTip:+" = " + s._DefaultValue
						End If
					End If
				End If
				
				If CallTip <> "" And (Not Self.CallTipActive() Or Self.CalltipLastPosition <> Self.WordStartPosition(Pos, True)) Then
					Self.hideInfo()
					Self.CalltipLastPosition = Self.WordStartPosition(Pos, True)
					Self.CallTipShow(Self.WordStartPosition(Pos, True), CallTip)
				ElseIf CallTip = "" And Self.CallTipActive() Then
					Self.hideInfo()
				End If
			ElseIf Self.CallTipActive() Then
				Self.hideInfo()
			End If
		EndIf
	End Method
	
	Rem
		bbdoc:Versteckt die User-Info wieder.
	EndRem
	Method hideInfo()
		If Self.CallTipActive() Then
			Self.CallTipCancel()
		EndIf
	End Method
	
	Rem
		bbdoc:Zeigt die Autovervollstaendigung.
	EndRem
	Method showCompletion()
		If Self.AutoCompActive() Then
			Self.AutoCompCancel()
		EndIf
		Local wordLength:Int = Self.WordEndPosition(Self.GetCurrentPos(), True) - Self.WordStartPosition(Self.GetCurrentPos(), True)
		Local s:Scope[] = Self._autoCompSuggestion(Self.GetCurrentPos())
		If s.length > 0 Then
				
			Local list:TList = TList.FromArray(s)
			list.Sort()
			s = Scope[] (list.ToArray())
			
			Local AutoComplete:String = ""
			For Local s1:Scope = EachIn s
				AutoComplete:+s1._Name
				Select True
					Case s1.IsVariable()
						AutoComplete:+"?1"
					Case s1.IsFunction()
						AutoComplete:+"?2"
					Case s1.IsType()
						AutoComplete:+"?3"
				End Select
				AutoComplete:+" "
			Next
			AutoComplete = AutoComplete[..(AutoComplete.Length - 1)]
			DebugLog "Text-Length: " + wordLength
			If Settings.Get("AutoComp") = 1 Then
				Self.AutoCompShow(wordLength, AutoComplete)
			Else
				app.AutoComp.ShowAutoComp(AutoComplete,,, Self)
			End If
		EndIf
	End Method
	
	Rem
		bbdoc:Gibt ein Wort, an einer bestimmten Position zurueck.
	EndRem
	Method _getWordAtPos:String(Pos:Int, WithObjects:Int = False)
		Local PosStart:Int = Self.WordStartPosition(Pos, True)
		Local PosEnd:Int = Self.WordEndPosition(Pos, True)
		If WithObjects = False Then
			Return Self.GetTextRange(PosStart, PosEnd)
		Else
			While Self.GetTextRange(PosStart - 1, PosStart) = "."
				PosStart = Self.WordStartPosition(PosStart - 2, True)
			Wend
			Return Self.GetTextRange(PosStart, PosEnd)
		EndIf
	End Method
	
	Rem
		bbdoc:Gibt den Scope für eine angegebene Position zurück.
	EndRem
	Method _getScopeForPosition:Scope(Pos:Int)
		Local Word:String = Self._getWordAtPos(Pos, True)
		Local s:Scope = Self._getScopeFromLine(Self.LineFromPosition(Pos))
		If s <> Null Then
			If Word.Find(".") > 0 Then
				s = s.GetScopeFromPath(Word)
			If s = Null Then app.setStatusText "Path(" + Word + ") - No Scope: " + MilliSecs()
			Else
				s = s.GetNearestMatch(Word)
			If s = Null Then app.setStatusText "Nearest(" + Word + ") - No Scope: " + MilliSecs()
			End If
		Else
			app.setStatusText("Es gibt kein Scope fuer das aktuelle Dokument.")
		End If
		Return s
	End Method
	
	Rem
		bbdoc:Gibt die moeglichen Scopes an, die ein User angefangen haben koennte.
	EndRem
	Method _autoCompSuggestion:Scope[] (Pos:Int)
		Local Word:String = Self._getWordAtPos(Pos, True).ToLower()
		Local s:Scope = Self._getScopeFromLine(Self.LineFromPosition(Pos))
		Local ret:Scope[]
		If s <> Null Then
			Local LastObjectSeperator:Int = Word.FindLast(".")
			If LastObjectSeperator > - 1 Then
				' Objekt Key-Word.
				DebugLog "GetScopeFromPath: " + Word[..(LastObjectSeperator)] + " --> " + Word[(LastObjectSeperator + 1)..]
				Local parent:Scope = s.GetScopeFromPath(Word[..(LastObjectSeperator)])
				If parent Then parent = parent.GetTypeScope()
				If parent Then
					Word = Word[(LastObjectSeperator + 1)..]
					Local childs:Scope[] = parent.GetChilds(Self.LineFromPosition(Pos))
					For s = EachIn childs
						If Word = s._Name[..(Word.Length)].ToLower() Then
							ret = ret[..(ret.Length + 1)]
							ret[ret.Length - 1] = s
						EndIf
					Next
				Else
					DebugLog "ScopePathnot found."
				EndIf
			Else
				' Objektloses Key-Word.
				For Local Container:ScopeContainer = EachIn ScopeContainer.GetScopes()
					Local parent:Scope
					If Container.GetScope() = Self.s Then
						' In der aktuellen Datei, muss die aktuelle Zeile beruecksichtigt werden.
						parent = s
					Else
						parent = Container.GetScope()
					End If
					While parent <> Null
						For Local s1:Scope = EachIn parent._Childs
							If Word = s1._Name[..(Word.Length)].ToLower() Then
								' Ein Object faengt mit den Word-Buchstaben an.
								ret = ret[..(ret.Length + 1)]
								ret[ret.Length - 1] = s1
							EndIf
						Next
						parent = parent._Parent
					Wend
				Next
			End If
		End If
		Return ret
	End Method
	
	Rem
		bbdoc:Gibt das unterste Scope fuer eine Zeile zurueck.
	EndRem
	Method _getScopeFromLine:Scope(Line:Int)
		If Self.s <> Null Then
			Return Self.s.GetChildFromLine(Line)
		End If
		Return Null
	End Method
	
	Rem
		bbdoc:Git eine absolute Position eines Punktes auf dem Controls zurueck.
	EndRem
	Method GetPositionAboslute(X:Int Var, Y:Int Var)
		Local editorX:Int, editorY:Int
		app.frameMain.getPosition(editorX, editorY)
		Self.GetScreenPosition(editorX, editorY)
		X:+editorX
		Y:+editorY
	End Method
	
	Method parseLastWord()
		Local ws:Int, we:Int
		Self.getActualWord(ws, we)
		
		Local Position:Int = Self.GetCurrentPos()
		Local LineNr:Int = Self.GetCurrentLine()
		Local Line:String = Self.GetLine(LineNr)
		Position = Position - Self.GetLineEndPosition(LineNr - 1) - 2 ' (chr 10 und chr 13)
		DebugLog "Position: " + Position
		
		Rem
			bbdoc:Hier wird ueberprueft, ob das Wort geparst werden darf.
		End Rem
		Local Pos2:Int = 0
		While Pos2 < Line.Length
			If Line[Pos2] = Asc("~q") Then
				While Pos2 < Line.Length
					Pos2:+1
					If Line[Pos2] = Asc("~q") Then Exit
				Wend
			End If
			
			If Position = Pos2 Then Exit
			If Position < Pos2 Then Return ' Position war in Anfuehrungszeichen
			If Line[Pos2] = Asc("'") Then Return ' Position liegt in einem Kommentar
			Pos2:+1
		Wend
		
		If (ws > Self.GetTargetStart() And ws < Self.GetTargetEnd()) Or (we > Self.GetTargetStart() And we < Self.GetTargetEnd()) Then Return;
		
		' Keyword aus der Liste suchen
		Local txt:String = Self.GetTextRange(Self.GetTargetStart(), Self.GetTargetEnd())
		Local keyWord:TKeyword_kw = TKeyword.isKeyword(txt)
		If keyWord And txt <> keyWord.Syntax Then
			Self.Freeze() ' Editor einfrieren
			Self.ReplaceTarget(keyWord.Syntax) ' Wort ersetzen
			Self.Thaw() ' Editor auftauen
		End If
	End Method
	
	Method myOnMouseEvent(event:wxMouseEvent)
		Select event.getEventType()
			Case wxEVT_LEFT_UP
				Self.hideInfo()
				Self.parseLastWord()
			Case wxEVT_MOTION
				Local Position:Int = Self.PositionFromPointClose(event.getX(), event.getY())
				If Position = wxInvalidOffset Then
					Self.hideInfo()
				Else
					Self.showInfo(Position, event.getX(), event.getY())
				End If
		End Select
	End Method
	
	Method myOnKeyEvent(event:wxKeyEvent)
		'If event.GetModifiers() = wxACCEL_CMD And event.getKeyCode() = WXK_SPACE Then ' 2=CmdDown, 32=Space
		If event.GetModifiers() = wxK_CONTROL And event.getKeyCode() = WXK_SPACE Then ' 2=CmdDown, 32=Space
			' Aufruf der Autovervollstaendigung.
			Self.showCompletion()
		Else
			Select event.getKeyCode()
				Case WXK_RETURN ' Enter
					' Hier werden (die richtige Anzahl-)Tabs in der nachsten Zeile eingefuegt.
					Self.Freeze()
					Local lineNr:Int = Self.GetCurrentLine()
					Local Indention:Int = Self.GetLineIndentation(lineNr)
					Self.NewLine()
					lineNr = Self.GetCurrentLine()
					Self.SetLineIndentation(lineNr, Indention)
					Self.SetSelection(Self.GetLineIndentPosition(lineNr), Self.GetLineIndentPosition(lineNr) )
					Self.Thaw()
				Case WXK_F1
					' Hilfe-Aufruf (Keyword und Parameter werden angezeigt).
					Self.showInfo()
				Case WXK_LEFT, WXK_RIGHT, WXK_UP, WXK_DOWN, WXK_END, WXK_START, WXK_PAGEDOWN, WXK_PAGEUP
					' "Cursor-bewegungs-tasten"
					Self.hideInfo()
					Self.parseLastWord()
					event.Skip()
				Case Asc(".") ' Punkt
					Self._showAutoComp = True
					'If Not event.ShiftDown() And Not event.CmdDown() And Not event.AltDown() Then
					'	Self.AddText(".")
					'	Self.showCompletion()
					'Else
					event.Skip()
					'EndIf
				Default
					Self.hideInfo()
					If Self.GetTextRange(Self.GetCurrentPos() - 1, Self.GetCurrentPos()) = "." Then
						Self._showAutoComp = True
					End If
					event.Skip()
			EndSelect
		EndIf
	End Method
End Type
