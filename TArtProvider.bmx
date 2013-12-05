Type TArtProvider Extends wxArtProvider
	Const IconApp:String = "./icons/App/"
	Const IconAutoComplete:String = "./icons/AutoComplete/"
	Field _loaded:TMap = New TMap
	
	Method CreateBitmap:wxBitmap(id:String, client:String, w:Int, h:Int)
		Print "TArtProvider.CreateBitmap(id=~q"+id+"~q, client=~q"+client+"~q, w="+w+", h="+h+")"
		If Self._loaded.Contains(id) Then
			Return wxBitmap(Self._loaded.ValueForKey(id))
		Else
			Select id
				Case "AppIcon", "AppBuildRun", "AppBuildStop"
					Return Self._loadBitmap(id[3..], 1)
				Case "AutocompleteVar", "AutocompleteFunction", "AutocompleteType"
					Return Self._loadBitmap(id[12..], 2)
			End Select
		EndIf
		Return wxNullBitmap
	End Method
	
	Method _loadBitmap:wxBitmap(name:String, SearchPath:Int)
		Local dir:String = ""
		Select SearchPath
			Case 1
				dir = TArtProvider.IconApp
			Case 2
				dir = TArtProvider.IconAutoComplete
		End Select
		Local img:wxBitmap = wxBitmap.CreateFromFile(dir + name + ".png", wxBITMAP_TYPE_PNG)
		If img Then
			Self._loaded.Insert(name, img)
		EndIf
		Return img
	End Method
End Type
