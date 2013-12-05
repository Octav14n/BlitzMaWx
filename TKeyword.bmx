Type TKeyword
	Global instance:TKeyword
	Global keyWordString:String
	Field kwList:TList
	Field doc:TxmlDoc
	Field types:TList
	
	Method New()
		Self.instance = Self
		Self.kwList = New TList
		Self.types = New TList
		
		Self.Load()
	End Method
	
	Rem
		bbdoc:Laedt alle Keywords aus der Keyword.txt
	End Rem
	Method Load()
		Self.kwList.Clear()
		Self.keyWordString = ""
		If Self.doc Then Self.doc.free() ; Self.doc = Null
		Self.doc = TxmlDoc.parseFile("./Module.xml")
		If Self.doc Then
			Local nroot:TxmlNode = doc.getRootElement()
			Local nchilds:TList = nroot.getChildren()
			For Local node:TxmlNode = EachIn nchilds
				Select node.getName().ToLower()
					Case "keyword"; Self.addKeyword(node.getAttribute("name"))
					Case "function"; Self.addFunction(node.getAttribute("name"), node)
					Case "type"; Self.addType(node)
					'Case "variable"; Self.addVariable(node.getAttribute("scope"), node.getAttribute("name"), node.getAttribute("type"))
				End Select
			Next
		Else
			If Confirm(app.lang.error_keywordXmlNotParsed, True) Then
				onRefreshDatabase(Null)
			End If
		End If
	End Method
		
	Rem
		bbdoc:Ueberprueft, ob der uebergebene String ein Keyword ist
	End Rem
	Function isKeyword:TKeyword_kw(kw:String)
		Local kwL:TKeyword_kw
		kw = kw.ToLower()
		For kwL = EachIn TKeyword.instance.kwList
			If kw = kwL.KeyWord Then Return kwL
		Next
	End Function
	
	Rem
		bbdoc:Gibt eine Liste aller Key-Woerter zurueck (mit der richtigen Gross/kleinschreibung)
	End Rem
	Method ToString:String()
		Return Left(keyWordString, keyWordString.Length - 1)
	End Method
	
	Rem
		bbdoc:Adds a Keyword to the List
	endrem
	Method addKeyword(KeyWord:String, tabs:Int = 0)
		If KeyWord.Length = 0 Then Return
		Local kw:TKeyword_kw = New TKeyword_kw
		If tabs = 9 Then tabs = -1
		kw.KeyWord = Lower(KeyWord)
		kw.Syntax = KeyWord
		Self.kwList.AddLast(kw)
		TKeyword.keyWordString = TKeyword.keyWordString + KeyWord + " "
	End Method
	
	Rem
		bbdoc:Adds a Function to the List
	EndRem
	Method addFunction(FunctionName:String, node:TxmlNode)
		If FunctionName.Length = 0 Then Return
		Local kw:TKeyword_kw = New TKeyword_kw
		kw.KeyWord = Lower(FunctionName)
		kw.Syntax = FunctionName
		kw.node = node
		Self.kwList.AddLast(kw)
		TKeyword.keyWordString = TKeyword.keyWordString + FunctionName + " "
	End Method
	
	Rem
		bbdoc:Returns the Node from a Function or Type
	EndRem
	Method getKeyWordNode:TxmlNode(keyword:String)
		Local kwL:TKeyword_kw
		keyword = keyword.ToLower()
		For kwL = EachIn TKeyword.instance.kwList
			If keyword = kwL.keyword Then Return kwL.node
		Next
		Local node:TxmlNode
		For node = EachIn Self.types
			If node.getAttribute("name").ToLower() = keyword Then Return node
		Next
	End Method
	
	Rem
		bbdoc:Adds a Type to the List
	EndRem
	Method addType(node:TxmlNode)
		Self.types.AddLast(node)
	End Method
End Type

Type TKeyword_kw
	Field KeyWord:String
	Field Syntax:String
	Field node:TxmlNode
End Type
