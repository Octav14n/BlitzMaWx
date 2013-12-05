Type TReadMods
	Global _instance:TReadMods
	Field rootIsInExtern:Int
	Field root:TReadModsNSRoot
	
	Method New()
		Self._instance = Self
	End Method
	
	Method Load(url:String, nowObject:TReadModsNSAbstract = Null, debugDontContinue:Int = False)
		If nowObject = Null Then
			If Self.root = Null Then Self.root = New TReadModsNSRoot
			nowObject = Self.root
		End If
		If FileType(url) <> FILETYPE_DIR Then Notify("This should never happen!~n~n~q" + url + "~q~n~qTReadMods erwartet einen Ordner, bekam aber etwas anderes~q", True) ; End
		If Right(url, 1) <> "/" Then url = url + "/"
		'printOut_indent:+1
		'printOut "Dir: " + url
		Local dir:Int = ReadDir(url)
		Local file:String
		Repeat
			file = NextFile(dir)
			If file <> "" And file <> "." And file <> ".." And (Right(file, 4) = ".mod" Or Right(file, 4) = ".bmx") Then
				'If Not debugDontContinue And file <> "pub.mod" And file <> "brl.mod" Then Continue ' Entfernen um alle module einlesen zu lassen.
				Print file
				Select FileType(url + file)
					Case 1; If Right(file, 4) = ".bmx" Then Self._ReadFile(url + file)
					Case 2; Self.Load(url + file, Null, True) ' Self.Load(url + file, Null)
				EndSelect
			End If
		Until file = ""
		'printOut"Return"
		'printOut_indent:-1
	EndMethod
	
	Method _ReadFile(url:String)
		Local stream:TStream = ReadFile(url)
		printOut"Parsing " + url
		printOut_indent:+1
		If stream Then
			'While Not Eof(stream)
			Self.root.parserAddFromStream(stream)
			'Wend
			stream.Close()
		End If
		printOut_indent:-1
	EndMethod
	
	Rem
		bbdoc:Saves the Objects to a XML format
	EndRem
	Method saveAsXml(url:String)
		'Local nowObject:TReadModsNSAbstract
		If Self.root = Null Then Return
		Local stream:TStream = WriteFile(url)
		If stream Then
			Self._saveAsXml_FromObject(stream, Self.root, -1)
			stream.Close()
		End If
	EndMethod
	
	Method _saveAsXml_FromObject(stream:TStream, nowObject:TReadModsNSAbstract, einrueckung:Int)
		Local child:TReadModsNSAbstract
		Local selXML:TXMLObject = New TXMLObject
		If nowObject.childs Then
			selXML.unterObjekte = nowObject.childs.Count()
		EndIf
		selXML.addArgument("name", nowObject.objectName)
		selXML.addArgument("type", nowObject.objectType)
		
		Select nowObject.namespaceType
			Case TReadModsNSAbstract.NS_ROOT
				selXML.name = "root"
			Case TReadModsNSAbstract.NS_TYPE
				selXML.name = "type"
			Case TReadModsNSAbstract.NS_VARIABLE
				selXML.name = "variable"
				selXML.addArgument("zusatz", TReadModsNSVariable(nowObject).varZusatz)
				selXML.addArgument("scope", TReadModsNSVariable(nowObject).varScope)
			Case TReadModsNSAbstract.NS_FUNCTION
				selXML.name = "function"
			Case TReadModsNSAbstract.NS_METHOD
				selXML.name = "method"
			Case TReadModsNSAbstract.NS_KEYWORD
				selXML.name = "keyword"
		End Select
		
		Self._writeLine(stream, selXML.getStartString(), einrueckung)
		
		If nowObject.childs <> Null Then
			For child = EachIn nowObject.childs
				Self._saveAsXml_FromObject(stream, child, einrueckung + 1)
			Next
		EndIf
		
		If selXML.getEndString() <> "" Then Self._writeLine(stream, selXML.getEndString(), einrueckung)
	EndMethod
	
	Method _writeLine(stream:TStream, txt:String, einrueckung:Int)
		Local i:Int
		For i = 0 To einrueckung
			stream.WriteByte(Asc("~t"))
		Next
		stream.WriteLine(txt)
	End Method
End Type

Rem
	bbdoc:Ein Element, was einzelne Nodes zurueckgibt. wird nur fuer TReadMods benoetigt
EndRem
Type TXMLObject
	Field name:String
	Field arguments:String
	Field unterObjekte:Int
	Method getStartString:String()
		Local str:String = "<" + name + arguments
		If Self.unterObjekte > 0 Then
			str = str + ">"
		Else
			str = str + " />"
		End If
		Return str
	End Method
	Method getEndString:String()
		If unterObjekte > 0 Then Return "</" + name + ">"
	End Method
	Method addArgument(key:String, value:String)
		If value = "" Or key = "" Then Return
		Self.arguments = Self.arguments + " " + key + "=~q" + value + "~q"
	End Method
End Type

Type TReadModsNSAbstract Abstract
	' Namespaces
	Const NS_ROOT:Int = 1
	Const NS_TYPE:Int = 2
	Const NS_METHOD:Int = 3
	Const NS_FUNCTION:Int = 4
	Const NS_VARIABLE:Int = 5
	Const NS_KEYWORD:Int = 6
	' Variable types
	Const VAR_LOCAL:Int = 1
	Const VAR_GLOBAL:Int = 2
	Const VAR_CONST:Int = 3
	Field namespaceType:Int
	Field namespaceSichtbarkeit:Int ' Container der VAR_ konstanten fuer Variablen
	Field childs:TList
	
	Field objectName:String ' Name des Objektes
	Field objectType:String ' Type (Rueckgabe-Type oder Var-Type) des Objektes
	
	Method addChilds(obj:TReadModsNSAbstract)
		childs.AddLast(obj)
	End Method
	Rem
		bbdoc:Gibt die unterelemente des aktuellen Elementes zurueck (oder Null)
	End Rem
	Method getChilds:TList()
		Return Self.childs
	End Method
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream) Abstract
End Type

Type TReadModsNSKeyword Extends TReadModsNSAbstract
	Method New()
		Self.namespaceType = NS_KEYWORD
	End Method
	
	Function Create:TReadModsNSKeyword(keyword:String)
		Local trm:TReadModsNSKeyword = New TReadModsNSKeyword
		trm.objectName = keyword
		Return trm
	End Function
	
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		Return 0;
	End Method
End Type

Type TReadModsNSRoot Extends TReadModsNSAbstract
	Method New()
		Self.namespaceType = Self.NS_ROOT
		Self.childs = New TList
		
		' Logik
		Self.addChilds(TReadModsNSKeyword.Create("End"))
		Self.addChilds(TReadModsNSKeyword.Create("If"))
		Self.addChilds(TReadModsNSKeyword.Create("Then"))
		Self.addChilds(TReadModsNSKeyword.Create("Else"))
		Self.addChilds(TReadModsNSKeyword.Create("ElseIf"))
		Self.addChilds(TReadModsNSKeyword.Create("EndIf"))
		Self.addChilds(TReadModsNSKeyword.Create("Function"))
		Self.addChilds(TReadModsNSKeyword.Create("EndFunction"))
		Self.addChilds(TReadModsNSKeyword.Create("Strict"))
		Self.addChilds(TReadModsNSKeyword.Create("SuperStrict"))
		Self.addChilds(TReadModsNSKeyword.Create("Null"))
		Self.addChilds(TReadModsNSKeyword.Create("And"))
		Self.addChilds(TReadModsNSKeyword.Create("Or"))
		Self.addChilds(TReadModsNSKeyword.Create("Xor"))
		Self.addChilds(TReadModsNSKeyword.Create("Not"))
		Self.addChilds(TReadModsNSKeyword.Create("Select"))
		Self.addChilds(TReadModsNSKeyword.Create("Case"))
		Self.addChilds(TReadModsNSKeyword.Create("Default"))
		Self.addChilds(TReadModsNSKeyword.Create("EndSelect"))
		Self.addChilds(TReadModsNSKeyword.Create("Return"))
		Self.addChilds(TReadModsNSKeyword.Create("Exit"))
		' Types
		Self.addChilds(TReadModsNSKeyword.Create("Field"))
		Self.addChilds(TReadModsNSKeyword.Create("Self"))
		Self.addChilds(TReadModsNSKeyword.Create("Extends"))
		Self.addChilds(TReadModsNSKeyword.Create("New"))
		Self.addChilds(TReadModsNSKeyword.Create("Method"))
		Self.addChilds(TReadModsNSKeyword.Create("EndMethod"))
		Self.addChilds(TReadModsNSKeyword.Create("Type"))
		Self.addChilds(TReadModsNSKeyword.Create("EndType"))
		Self.addChilds(TReadModsNSKeyword.Create("Abstract"))
		' Variablen
		Self.addChilds(TReadModsNSKeyword.Create("Var"))
		Self.addChilds(TReadModsNSKeyword.Create("Ptr"))
		Self.addChilds(TReadModsNSKeyword.Create("Local"))
		Self.addChilds(TReadModsNSKeyword.Create("Global"))
		Self.addChilds(TReadModsNSKeyword.Create("Const"))
		' Konstanten (schlechter Platz eigentlich...)
		Self.addChilds(TReadModsNSKeyword.Create("True"))
		Self.addChilds(TReadModsNSKeyword.Create("False"))
		Self.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_CONST, "True", "Int", ""))
		Self.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_CONST, "False", "Int", ""))
		' Einfache Typen
		Self.addChilds(TReadModsNSKeyword.Create("Object"))
		Self.addChilds(TReadModsNSKeyword.Create("Int"))
		Self.addChilds(TReadModsNSKeyword.Create("String"))
		Self.addChilds(TReadModsNSKeyword.Create("Double"))
		Self.addChilds(TReadModsNSKeyword.Create("Float"))
		Self.addChilds(TReadModsNSKeyword.Create("Byte"))
		Self.addChilds(TReadModsNSKeyword.Create("Short"))
		' Schleifen
		Self.addChilds(TReadModsNSKeyword.Create("Repeat"))
		Self.addChilds(TReadModsNSKeyword.Create("Until"))
		Self.addChilds(TReadModsNSKeyword.Create("Forever"))
		Self.addChilds(TReadModsNSKeyword.Create("While"))
		Self.addChilds(TReadModsNSKeyword.Create("Wend"))
		Self.addChilds(TReadModsNSKeyword.Create("For"))
		Self.addChilds(TReadModsNSKeyword.Create("To"))
		Self.addChilds(TReadModsNSKeyword.Create("Step"))
		Self.addChilds(TReadModsNSKeyword.Create("Next"))
		Self.addChilds(TReadModsNSKeyword.Create("EachIn"))
		' Einbindungen
		Self.addChilds(TReadModsNSKeyword.Create("IncBin"))
		Self.addChilds(TReadModsNSKeyword.Create("Include"))
		Self.addChilds(TReadModsNSKeyword.Create("Import"))
		Self.addChilds(TReadModsNSKeyword.Create("Framework"))
		' Module
		Self.addChilds(TReadModsNSKeyword.Create("Extern"))
		Self.addChilds(TReadModsNSKeyword.Create("EndExtern"))
		Self.addChilds(TReadModsNSKeyword.Create("Private"))
		Self.addChilds(TReadModsNSKeyword.Create("Public"))
		Self.addChilds(TReadModsNSKeyword.Create("Rem"))
		Self.addChilds(TReadModsNSKeyword.Create("EndRem"))
		' Fehlerbehandlung/Debugging
		Local tmpFunction:TReadModsNSFunction
		tmpFunction = TReadModsNSFunction.Create("Throw", "")
		tmpFunction.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_LOCAL, "exception", "Object", ""))
		Self.addChilds(tmpFunction)
		tmpFunction = TReadModsNSFunction.Create("Assert", "")
		tmpFunction.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_LOCAL, "boolean", "Int", ""))
		Self.addChilds(tmpFunction)
	End Method
	
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		Local ActualWord:String
		Local LastWord:String
		Local rb:Int
		Local isExtern:Int = False
		While Not stream.Eof()
			rb = ReadByte(stream)
			If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
				ActualWord = ActualWord + Chr(rb)
			Else
				If LastWord <> "end" Then
					Select ActualWord.ToLower()
						Case ""
						Case "function"
							Local t:TReadModsNSFunction = New TReadModsNSFunction
							t.parserAddFromStream(stream)
							Self.addChilds(t)
						Case "type"
							Local t:TReadModsNSType = New TReadModsNSType
							t.parserAddFromStream(stream)
							Self.addChilds(t)
						Case "method" ' assert Sollte eigentlich nie passieren
							Local t:TReadModsNSMethod = New TReadModsNSMethod
							t.parserAddFromStream(stream)
							Self.addChilds(t)
						Case "rem"
							ignoreKommentar(stream)
						Case "extern"; TReadMods._instance.rootIsInExtern = True
						Case "private" ; ignorePrivates(stream)
					End Select
					'printOut ActualWord
				Else
					Select ActualWord.ToLower()
						Case "extern"; TReadMods._instance.rootIsInExtern = False
					EndSelect
				End If
				If ActualWord <> "" Or rb <> 32 Then LastWord = ActualWord.ToLower()
				ActualWord = ""
			EndIf
		Wend
	EndMethod
End Type

Type TReadModsNSType Extends TReadModsNSAbstract
	'Field extend:String'TReadModsNSType
	
	Method New()
		Self.namespaceType = Self.NS_TYPE
		Self.childs = New TList
	End Method
	
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		printOut"[Type].parserAddFromStream"
		printOut"-----------------------------"
		printOut_indent:+1
		Local readFirstLine:Int = True
		Local ActualWord:String, LastWord:String
		Local rb:Int
		While Not stream.Eof()
			rb = ReadByte(stream)
			If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
				ActualWord = ActualWord + Chr(rb)
			Else
				If readFirstLine Then
					'printOut" -> " + ActualWord
					If Self.objectName = "" Then Self.objectName = ActualWord
					If rb = 10 Or rb = 13 Then
						'printOut"-----------------------------"
						'printOut_indent:-1
						'Return 1
						readFirstLine = False
					End If
				Else
					If LastWord <> "end" Then
						Select ActualWord.ToLower()
							Case ""
							Case "function"
								Local t:TReadModsNSFunction = New TReadModsNSFunction
								t.parserAddFromStream(stream)
								Self.addChilds(t)
							Case "method"
								Local t:TReadModsNSMethod = New TReadModsNSMethod
								t.parserAddFromStream(stream)
								Self.addChilds(t)
							Case "rem"
								ignoreKommentar(stream)
							Case "private"
								ignorePrivates(stream)
							Case "field"
								parserAddVariableFromStream(stream, Self.VAR_LOCAL, Self)
							Case "global"
								parserAddVariableFromStream(stream, Self.VAR_GLOBAL, Self)
							Case "const"
								parserAddVariableFromStream(stream, Self.VAR_CONST, Self)
						End Select
					End If
					If (LastWord = "end" And ActualWord.ToLower() = "type") Or ActualWord.ToLower() = "endtype" Then
						printOut"-----------------------------"
						printOut_indent:-1
						Return 1
					EndIf
					If ActualWord <> "" Then LastWord = ActualWord.ToLower()
				EndIf
				ActualWord = ""
			EndIf
		Wend
		printOut_indent:-1
	EndMethod
End Type

Rem
	bbdoc:Liesst die definition fuer Variablen von einem Stream und added sie bei ihrem Parent (scope = TRMAbstract.VAR_*)
EndRem
Function parserAddVariableFromStream(stream:TStream, scope:Int, parent:TReadModsNSAbstract)
	Local actualWord:String, lastWord:String, lastSeperator:Int, rb:Int
	While Not stream.Eof()
		rb = stream.ReadByte()
		If rb <> 32 And rb <> "~t"[0] And rb <> 13 Then
			If rb = ":"[0] Then
				lastSeperator = ":"[0]
				lastWord = actualWord
				actualWord = ""
			ElseIf rb = ","[0] Or rb = 10 Or rb = "="[0] Then
				if lastSeperator = ":"[0] Then
					parent.addChilds(TReadModsNSVariable.Create(scope, lastWord, actualWord, ""))
				ElseIf lastSeperator <> "="[0]
					parent.addChilds(TReadModsNSVariable.Create(scope, lastWord, "", ""))
				End If
				
				
				If rb = "="[0] Then
					While Not stream.Eof()
						rb = stream.ReadByte()
						If rb = "~q"[0] Then ignoreString(stream)
						If rb = ","[0] Or rb = 10 Then
							Exit
						End If
					Wend
				End If
				
				lastSeperator = rb
				
				lastWord = actualWord
				actualWord = ""
				If rb = 10 Then Return
			Else
				actualWord = actualWord + Chr(rb)
			EndIf
		End If
	WEnd
End Function

Type TReadModsNSVariable Extends TReadModsNSAbstract
	Field varZusatz:String, varScope:Int
	
	Rem
		bbdoc:Erstellt eine neue TReadModsNSVariable (scope = TRMAbstract.VAR_*)
	EndRem
	Function Create:TReadModsNSVariable(varScope:Int, varName:String, varType:String, varZusatz:String)
		Local v:TReadModsNSVariable = New TReadModsNSVariable
		v.varScope = varScope
		v.objectName = varName
		v.objectType = varType
		v.varZusatz = varZusatz
		Return v
	End Function
	
	Method New()
		Self.namespaceType = Self.NS_VARIABLE
		Self.namespaceSichtbarkeit = Self.VAR_LOCAL
	End Method
	
	Rem
		bbdoc:[Ungueltig]Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		Return 0
	End Method
EndType

Type TReadModsNSFunction Extends TReadModsNSAbstract
	
	Method New()
		Self.namespaceType = Self.NS_FUNCTION
		Self.childs = New TList
	End Method
	
	Function Create:TReadModsNSFunction(varName:String, varType:String)
		Local tmp:TReadModsNSFunction = New TReadModsNSFunction
		tmp.objectName = varName
		tmp.objectType = varType
		Return tmp
	End Function
	
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		printOut"[Funktion].parserAddFromStream"
		printOut"-----------------------------"
		printOut_indent:+1
		Local needsToBeClosed:Int = Not TReadMods._instance.rootIsInExtern
		Local ActualWord:String, LastWord:String
		Local varName:String, varType:String, zusatz:String
		Local readFirstLine:Int = True
		Local rb:Int, nonWord:Int
		While Not stream.Eof()
			rb = ReadByte(stream)
			If rb = Asc("~q") Then
				ignoreString(stream)
				If stream.Eof() Then Exit ' sollte eigentlich nie passieren Oo
				rb = ReadByte(stream)
			EndIf
			If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
				ActualWord = ActualWord + Chr(rb)
			Else
				If ActualWord.ToLower() = "rem" Then ignoreKommentar(stream)
				If ActualWord.ToLower() = "abstract" Then needsToBeClosed = False
				If readFirstLine Then
					'printOut(ActualWord)
					'printOut LastWord + " " + Chr(nonWord) + " " + ActualWord
					'If nonWord = Asc(":") Then
					'	If varType = "" Then varType = ActualWord
					'EndIf
					If nonWord <> Asc(":") And varName <> "" And rb <> 32 Then
						Select Chr(rb)
							Case "$";varType = "String"
							Case "%";varType = "Int"
							Case "@";varType = "Byte"
							Case "#";varType = "Float"
						End Select
					End If
					If nonWord <> Asc(":") And varName = "" Then varName = ActualWord
					If nonWord = Asc(":") And varType <> "" Then zusatz = zusatz + ActualWord
					If nonWord = Asc(":") And varType = "" Then varType = ActualWord
					
					If rb = Asc(",") Or rb = Asc("(") Or rb = Asc(")") Then
						'If nonWord <> Asc(":") zusatz = ActualWord
						If Self.objectName = "" Then
							Self.objectName = varName
							Self.objectType = varType
							printOut("Funktion: " + varName + "~t[Type=~q" + varType + "~q;~tvarZusatz=~q" + zusatz + "~q]")
						Else
							printOut("New Var: " + varName + "~t[Type=~q" + varType + "~q;~tvarZusatz=~q" + zusatz + "~q]")
							' Die Variable als child anlegen
							If varName <> "" Then Self.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_LOCAL, varName, varType, zusatz))
							'actualVar.objectName = varName
							'actualVar.varType = varType
							'actualVar.varZusatz = zusatz
							'actualVar = Null
						End If
						LastWord = ""
						varName = ""
						varType = ""
						zusatz = ""
					'ElseIf varName = "" Then'If LastWord = "" And ActualWord <> "" Then
						'LastWord = ActualWord
					'	varName = ActualWord
					'ElseIf nonWord = Asc(":") And varType = "" Then
					'	varType = ActualWord
					'	'nonWord = 0
					'Else
					'	zusatz = zusatz + ActualWord
					EndIf
					If rb <> 32 Then nonWord = rb
					If rb = 10 Or rb = 13 Then
						If Not needsToBeClosed Then
							printOut"-----------------------------"
							printOut_indent:-1
							Return 1
						End If
						readFirstLine = False
					End If
					'	printOut"-----------------------------"
					'	printOut_indent:-1
					'	Return 1
					'End If
				Else
					If (LastWord = "end" And ActualWord.ToLower() = "function") Or ActualWord.ToLower() = "endfunction" Then
						printOut"-----------------------------"
						printOut_indent:-1
						Return 1
					EndIf
					If ActualWord <> "" Then LastWord = ActualWord.ToLower()
				EndIf
				ActualWord = ""
			EndIf
		Wend
		printOut"--EOF-------------------------"
		printOut_indent:-1
	EndMethod
End Type

Type TReadModsNSMethod Extends TReadModsNSAbstract
	
	Method New()
		Self.namespaceType = Self.NS_METHOD
		Self.childs = New TList
	End Method
	
	Rem
		bbdoc:Uebergibt einen neu eingelesenen Buchstaben, gibt True zurueck, wenn das Objekt fertig ist.
	End Rem
	Method parserAddFromStream:Int(stream:TStream)
		printOut"[Method].parserAddFromStream"
		printOut"-----------------------------"
		printOut_indent:+1
		Local needsToBeClosed:Int = Not TReadMods._instance.rootIsInExtern
		Local ActualWord:String, LastWord:String
		Local varName:String, varType:String, zusatz:String
		Local readFirstLine:Int = True
		Local rb:Int, nonWord:Int
		While Not stream.Eof()
			rb = ReadByte(stream)
			If rb = Asc("~q") Then
				ignoreString(stream)
				If stream.Eof() Then Exit' sollte eigentlich nie passieren Oo
				rb = ReadByte(stream)
			End If
			If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
				ActualWord = ActualWord + Chr(rb)
			Else
				If ActualWord.ToLower() = "rem" Then ignoreKommentar(stream)
				If ActualWord.ToLower() = "abstract" Then needsToBeClosed = False
				If readFirstLine Then
					'printOut(ActualWord)
					'printOut LastWord + " " + Chr(nonWord) + " " + ActualWord
					'If nonWord = Asc(":") Then
					'	If varType = "" Then varType = ActualWord
					'EndIf
					If nonWord <> Asc(":") And varName <> "" And rb <> 32 Then
						Select Chr(rb)
							Case "$";varType = "String"
							Case "%";varType = "Int"
							Case "@";varType = "Byte"
							Case "#";varType = "Float"
						End Select
					End If
					If nonWord <> Asc(":") And varName = "" Then varName = ActualWord
					If nonWord = Asc(":") And varType <> "" Then zusatz = zusatz + ActualWord
					If nonWord = Asc(":") And varType = "" Then varType = ActualWord
					
					If rb = Asc(",") Or rb = Asc("(") Or rb = Asc(")") Then
						'If nonWord <> Asc(":") zusatz = ActualWord
						If Self.objectName = "" Then
							Self.objectName = varName
							Self.objectType = varType
							printOut("Method: " + varName + "~t[Type=~q" + varType + "~q;~tvarZusatz=~q" + zusatz + "~q]")
						Else
							printOut("New Var: " + varName + "~t[Type=~q" + varType + "~q;~tvarZusatz=~q" + zusatz + "~q]")
							' Die Variable als child anlegen
							If varName <> "" Then Self.addChilds(TReadModsNSVariable.Create(TReadModsNSAbstract.VAR_LOCAL,varName, varType, zusatz))
							'actualVar.objectName = varName
							'actualVar.varType = varType
							'actualVar.varZusatz = zusatz
							'actualVar = Null
						End If
						LastWord = ""
						varName = ""
						varType = ""
						zusatz = ""
					'ElseIf varName = "" Then'If LastWord = "" And ActualWord <> "" Then
						'LastWord = ActualWord
					'	varName = ActualWord
					'ElseIf nonWord = Asc(":") And varType = "" Then
					'	varType = ActualWord
					'	'nonWord = 0
					'Else
					'	zusatz = zusatz + ActualWord
					EndIf
					If rb <> 32 Then nonWord = rb
					If rb = 10 Or rb = 13 Then
						If Not needsToBeClosed Then
							printOut"-----------------------------"
							printOut_indent:-1
							Return 1
						End If
						readFirstLine = False
					End If
					'	printOut"-----------------------------"
					'	printOut_indent:-1
					'	Return 1
					'End If
				Else
					If (LastWord = "end" And ActualWord.ToLower() = "method") Or ActualWord.ToLower() = "endmethod" Then
						printOut"-----------------------------"
						printOut_indent:-1
						Return 1
					EndIf
					If ActualWord <> "" Then LastWord = ActualWord.ToLower()
				EndIf
				ActualWord = ""
			EndIf
		Wend
		printOut"--EOF-------------------------"
		printOut_indent:-1
	EndMethod
End Type

Function ignoreKommentar(stream:TStream)
	Local ActualWord:String, lastword:String
	Local rb:Int
	'printOut"ignoreKommentar"
	'printOut_indent:+1
	'DebugStop
	While Not stream.Eof()
		rb = ReadByte(stream)
		If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
			ActualWord = ActualWord + Chr(rb)
		Else
			'DebugStop
			'printOut LastWord + "  " + ActualWord
			If lastWord = "end" And actualword.ToLower() = "rem" Then printOut_indent:-1; Return
			If ActualWord <> "" Or rb <> 32 Then LastWord = ActualWord.ToLower()
			ActualWord = ""
		EndIf
	Wend
	'printOut"-----------------------------"
	'printOut_indent:-1
End Function

Function ignorePrivates(stream:TStream)
	Local ActualWord:String
	Local rb:Int
	While Not stream.Eof()
		rb = ReadByte(stream)
		If (rb >= 65 And rb <= 90) Or (rb >= 97 And rb <= 122) Or rb = 95 Then
			ActualWord = ActualWord + Chr(rb)
		Else
			If ActualWord.ToLower() = "public" Then printOut_indent:-1; Return
			ActualWord = ""
		EndIf
	Wend
End Function

Function ignoreString(stream:TStream)
	While Not stream.Eof()
		If ReadByte(stream) = Asc("~q") Then Return
	Wend
End Function

Global printOut_indent:Int
Function printOut(str:String)
	rem
	Local i:Int
	Local strToWrite:String = ""
	For i = 0 To printOut_indent
		'WriteStdout("  ")
		strToWrite = strToWrite + "  "
	Next
	strToWrite = strToWrite + str
	If printOut_stream Then printOut_stream.WriteLine(strToWrite)
	Print strToWrite
	endrem
End Function
