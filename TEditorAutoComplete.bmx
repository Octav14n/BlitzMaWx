
Rem
	bbdoc:Autocomplete-Liste fuer das Editor-Fenster.
End Rem
Type TEditorAutoComplete Extends wxFrame
	Field KeyList:TEditorAutoCompleteKeyword[]
	Field List:wxListCtrl
	Field _Editor:TEditor
	
	Rem
		bbdoc:Called during frame creation.
	End Rem
	Method OnInit()
		Self.Show(False)
		Self.SetTransparent(.5)
		Self.SetWindowStyle(wxFRAME_NO_TASKBAR | wxFRAME_FLOAT_ON_PARENT | wxRESIZE_BORDER | wxNO_BORDER | wxTRANSPARENT_WINDOW)
		Local sizer:wxBoxSizer = wxBoxSizer.CreateBoxSizer(wxVERTICAL)
		Local ili:wxImageList = wxImageList.createImageList(16, 16, False)
		ili.add(wxArtProvider.GetBitmap("AutocompleteFunction", wxART_OTHER))
		ili.add(wxArtProvider.GetBitmap("AutocompleteVar", wxART_OTHER))
		ili.add(wxArtProvider.GetBitmap("AutocompleteType", wxART_OTHER))
		
		Self.List = wxListCtrl.CreateListCtrl(Self, wxID_ANY,,, ,, wxLC_ALIGN_LEFT | wxLC_SINGLE_SEL | wxLC_REPORT)' | wxLC_NO_HEADER)
		Self.List.InsertColumn(0, "Items",, -2)
		Self.List.SetImageList(ili, wxIMAGE_LIST_SMALL)
		sizer.Add(Self.List, 1, wxEXPAND)
		Self.List.SetFocus()
		
		Self.Connect(Self.List.GetId(), wxEVT_COMMAND_LIST_ITEM_ACTIVATED, TEditorAutoComplete.ItemActivated, Self)
		Self.ConnectAny(wxEVT_KEY_DOWN, TEditorAutoComplete.KeyDown, Self)
		Self.ConnectAny(wxEVT_KILL_FOCUS, TEditorAutoComplete.Blur, Self)
		
		Self.SetSizer(sizer)
		sizer.SetSizeHints(Self)
	End Method
	
	Rem
		bbdoc:Wird aufgerufen um die AutoComp anzuzeigen.
	EndRem
	Method ShowAutoComp(KeyWords:String, Seperator:String = " ", TypeSep:String = "?", Editor:TEditor)
		Self._Editor = Editor
		
		Local tmpKeyword:String[] = KeyWords.Split(Seperator)
		Self.KeyList = New TEditorAutoCompleteKeyword[tmpKeyword.Length]
		
		Self._Clear()
		
		For Local i:Int = 0 Until tmpKeyword.Length
			Self.KeyList[i] = TEditorAutoCompleteKeyword.Create(tmpKeyword[i], TypeSep)
			Self._AddKeyword(Self.KeyList[i])
		Next
		
		'Editor.ConnectAny(wxEVT_KEY_DOWN, EditorKeyDown, Self)
		
		Local xWin:Int, yWin:Int, xRel:Int, yRel:Int
		Editor.GetPositionAboslute(xWin, yWin)
		Editor.PointFromPosition(Editor.GetCurrentPos(), xRel, yRel)
		yRel = yRel + Editor.TextHeight(Editor.GetCurrentLine())
		Self.SetPosition(xWin + xRel, yWin + yRel)
		Self.Show()
		Self.SetFocus()
	End Method
	
	Rem
		bbdoc:Wird aufgerufen um die AutoComp zu schließen.
	EndRem
	Method HideAutoComp()
		Self.Hide()
		Self._Editor.SetFocus()
	End Method
	
	Rem
		bbdoc:Eventhandler-Wrapper.
	EndRem
	Function Blur(event:wxEvent)
		TEditorAutoComplete(event.userData).OnBlur(event)
	End Function
	
	Rem
		bbdoc:Eventhandler-Wrapper.
	EndRem
	Function ItemActivated(event:wxEvent)
		TEditorAutoComplete(event.userData).OnItemActivated(wxListEvent(event))
	End Function
	
	Rem
		bbdoc:Eventhandler-Wrapper.
	EndRem
	Function KeyDown(event:wxEvent)
		TEditorAutoComplete(Event.userData).OnKeyDown(wxKeyEvent(event))
	End Function
	
	Function EditorKeyDown(event:wxEvent)
		TEditorAutoComplete(Event.userData).OnKeyDown(wxKeyEvent(event), False)
	End Function
	
	Method OnItemActivated(event:wxListEvent)
		Self.OnApply(event.GetItem().GetText())
		DebugLog "OnItemActivated"
	End Method
	
	Method OnBlur(event:wxEvent)
		Print "Blur"
		Self.OnCancel()
	End Method
	
	Method OnKeyDown(event:wxKeyEvent, inWindow:Int = true)
		Select event.GetKeyCode()
			Case WXK_ESCAPE
				Self.OnCancel()
			'Case WXK_ENTER
			'	Self.OnApply(Self._GetActualKeyword().KKeyword())
		End Select
	End Method
	
	Rem
		bbdoc:Gibt das aktuell ausgewählte (hervorgehobene) Keyword zurück.
	End Rem
	Method _GetActualKeyword:TeditorAutoCompleteKeyword()
		Return KeyList[Self.List.GetNextItem(-1, wxLIST_NEXT_ALL, wxLIST_STATE_FOCUSED)]
	End Method
	
	Rem
		bbdoc:Wird aufgerufen, wenn der ausgewaehlte Text uebernommen werden soll.
	EndRem
	Method OnApply(Kw:String)
		Self._Editor.AddText(Kw)
		Self.HideAutoComp
	End Method
	
	Rem
		bbdoc:Wird aufgerufen, wenn die Autovervollstaendigung abgebrochen werden soll.
	EndRem
	Method OnCancel()
		Self.HideAutoComp
	End Method
	
	Rem
		bbdoc:Setzt die AutoComp-Liste zurueck.
	EndRem
	Method _Clear()
		Self.List.DeleteAllItems()
	End Method
	
	Rem
		bbdoc:Fuegt das uebergebene Keyword zu der Auswahlliste hinzu.
	EndRem
	Method _AddKeyword(kw:TEditorAutoCompleteKeyword)
		If kw.KType() = 0 Then
			Self.List.InsertStringItem(Self.List.GetItemCount(), kw.KKeyword())
		Else
			Self.List.InsertImageStringItem(Self.List.GetItemCount(), kw.KKeyword(), kw.KType() - 1)
		EndIf
	End Method
End Type

Type TEditorAutoCompleteKeyword
	Field _Keyword:String
	Field _Type:Int
	
	Function Create:TEditorAutoCompleteKeyword(Keyword:String, TypeSeperator:String)
		Local tmp:TEditorAutoCompleteKeyword = New TEditorAutoCompleteKeyword
		tmp.KKeyword Keyword[..(Keyword.Find(TypeSeperator))]
		tmp.KType Int(Keyword[(Keyword.Find(TypeSeperator) + 1)..])
		Return tmp
	End Function
	
	Method KKeyword:String(value:String = Null)
		If value <> Null Then
			Self._Keyword = value
		EndIf
		Return Self._Keyword
	End Method
	
	Method KType:Int(value:Int = 0)
		If value <> 0 Then
			Self._Type = value
		EndIf
		Return Self._Type
	End Method
End Type
