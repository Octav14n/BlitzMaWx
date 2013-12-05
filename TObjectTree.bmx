Rem
	bbdoc:Programmcode in Baumform.
EndRem
Type TObjectTree Extends wxTreeCtrl
	Field _mainTree:wxTreeItemId
	Field panel:TEditorPanel
	
	Rem
		bbdoc:Called during window creation.
	End Rem
	Method OnInit()
		Local ili:wxImageList = wxImageList.createImageList(16, 16, False)
		ili.add(wxArtProvider.GetBitmap("AutocompleteFunction", wxART_OTHER))
		ili.add(wxArtProvider.GetBitmap("AutocompleteVar", wxART_OTHER))
		ili.add(wxArtProvider.GetBitmap("AutocompleteType", wxART_OTHER))
		
		Self.setImageList(ili)
		Self.ConnectAny(wxEVT_COMMAND_TREE_ITEM_ACTIVATED, onItemActivate)
		Self.ConnectAny(wxEVT_LEFT_UP, onLeftUp)
	End Method
	
	Rem
		bbdoc:wxWidgets kann kein Focus vergeben :/
	EndRem
	Function onLeftUp(event:wxEvent)
		Local obj:TObjectTree = TObjectTree(event.GetEventObject())
		If Not obj.IsEnabled() Then
			' Element wieder aktivieren.
			obj.Enable(True)
			If obj.IsFrozen() Then
				' Element wieder das Zeichnen erlauben.
				obj.Thaw()
			EndIf
		End If
		event.Skip()
	End Function
	
	Function onItemActivate(event:wxEvent)
		' Da wxWidgets hier den Focus nicht wecheln moechte, muss das eigene Objekt deaktiviert werden,
		' befor das aktive Objekt geaendert werden kann.
		Local obj:TObjectTree = TObjectTree(event.GetEventObject())
		If obj.GetSelection().IsOk() Then
			Local s:Scope = Scope(obj.GetItemData(obj.GetSelection()))
			app.setStatusText "..." + s._Name + " --> " + s._StartLine
			obj.panel.editor.SetFocus()
			obj.panel.editor.GotoLine(s._StartLine)
			obj.Freeze()
			obj.Enable(False)
		EndIf
	End Function
	
	Method getMain:wxTreeItemId()
		If Self._mainTree = Null Then
			Self._mainTree = Self.AddRoot("MAIN")
		 End If
		 
		 Return Self._mainTree
	End Method
	
	Rem
		bbdoc:Erstellt eine Baumstruktur aus dem uebergebenen Scope.
	End Rem
	Method CreateFromScope(s:Scope, id:wxTreeItemId = Null)
		If id = Null Then
			Self.DeleteAllItems()
			Self._mainTree = Null
			id = Self.getMain()
		EndIf
		Local tmpID:wxTreeItemId = Null
		For Local s1:Scope = EachIn s._Childs
			Select True
				Case s1.IsVariable()
					Self.attVariable(id, s1._Name, s1)
				Case s1.IsType()
					tmpID = Self.attType(s1._Name, s1)
					Self.CreateFromScope(s1, tmpID)
				Case s1.IsFunction()
					Self.attMethod(id, s1._Name, s1)
			End Select
		Next
	End Method
	
	Method attType:wxTreeItemId(typeName:String, s:Scope)
		Return Self.AppendItem(Self.getMain(), typeName, 2,, s)
	End Method
	
	Method attVariable(TypeId:wxTreeItemId, varName:String, s:Scope)
		Self.AppendItem(TypeId, varName, 1,, s)
	End Method
	
	Method attMethod(typeID:wxTreeItemId, methodName:String, s:Scope)
		Self.AppendItem(typeID, methodName, 0,, s)
	End Method
	
	Method attFunction(typeID:wxTreeItemId, functionName:String, s:Scope)
		Self.AppendItem(TypeId, functionName, 0,, s)
	End Method
EndType
