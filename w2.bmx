
'SuperStrict

'Local t:Scope = Auswerten(LoadString("w2.bmx"))
'Debuglog "Ausgabe: "
'Debuglog t.ToString()

Function RepeatString:String(Str:String,Count:Int)
	Local newString:String=""
	While Count <> 0
		If (Count & 1) <> 0 Then
			newString=newString+Str
		EndIf
		Count=Count Shr 1
		Str:+Str
	Wend
	Return newString
End Function

Function Auswerten:Object(s:String, Path:String)
	
	Local Lexxer:Auswerten1 = New Auswerten1
	Lexxer.Path = Path
	Local WordNow:String = ""
	Local WordSeperator:Int = Asc(" ")
	Local i:Int = 0
	Local LineNumber:Int = 0
	s:+Chr(0) ' Ohne dies wird das letzte Wort nicht gelexxt.

	While i < s.Length
	
		If (s[i] >= Asc("a") And s[i] <= Asc("z")) Or (s[i] >= Asc("A") And s[i] <= Asc("Z")) Or (s[i] >= Asc("0") And s[i] <= Asc("9")) Or s[i] = Asc("_") Then
			WordNow:+Chr(s[i])
		Else
			Select s[i]
				Case 13 ' Windows-Zeilenumbruch ueberspringen.
				Case Asc("~q")
					WordNow:+Chr(s[i])
					i :+ 1
					While i < s.Length
						WordNow:+Chr(s[i])
						If s[i] = Asc("~q") Or s[i] = 10 Then Exit
						i :+ 1
					Wend
				Case Asc("'")
					If WordNow <> "" Then
						Local ex:LexExceptionBase = Lexxer.Lexx(WordSeperator, WordNow, LineNumber)
						If ex <> Null Then
							DebugLog "LexException: " + ex.ToString()
							Return ex
						EndIf
						WordNow = ""
						WordSeperator = Asc(" ")
					EndIf
					Local ex:LexExceptionBase = Lexxer.Lexx(WordSeperator, "'", LineNumber)
					If ex <> Null Then
						DebugLog "LexException: " + ex.ToString()
						Return ex
					EndIf
					WordNow = ""
					WordSeperator = Asc(" ")
				Default 'Chr(9), Chr(10), Chr(13), " ", ".", ":"
					
					If WordNow <> "" Or (WordSeperator <> Asc(" ") And s[i] <> 9 And s[i] <> Asc(" ")) Then
						'DebugLog(">" + WordSeperator + "<~q" + WordNow + "~q")
						Local ex:LexExceptionBase = Lexxer.Lexx(WordSeperator, WordNow, LineNumber)
						If ex <> Null Then
							DebugLog "LexException: " + ex.ToString()
							Return ex
						EndIf
						WordNow = ""
						WordSeperator = Asc(" ")
					EndIf
						
					If s[i] <> 9 And s[i] <> Asc(" ") Then
						WordSeperator = s[i]
						If s[i] = 10 Then
							LineNumber :+ 1
						End If
					End If
					
	
			End Select
		End If
		i :+ 1
	Wend
	Return Lexxer.GetRootScope()
End Function

Type Auswerten1
	'Global _instance:Auswerten1
	Field Path:String
	Field ifEnded:Int = False
	Field Declaration:String = ""
	Field InComment:Int = False
	Field LastWord:String = ""
	Field Parent:Scope
	Field ActualObject:Scope
	Field RootScope:Scope

	Method New()
		Self.ResetLexer()
	End Method
	
	Rem
		bbdoc:Erstellt aus dem uebergebenen CharCode eine (escapete) Zeichenkette.
	EndRem
	Method _escapeChar:String(char:Int)
		Select Chr(char)
			Case "~~"; Return "~~~~"
			Case "~q"; Return "~~q"
			Case "~n"; Return "~~n"
			Case Chr(13); Return ""
			Default
				Return Chr(char)
		End Select
	End Method
	
	Method Lexx:LexExceptionBase(Seperator:Int, Word:String, LineNumber:Int)
		'DebugLog "Lexx: Seperator = ~q" + Self._escapeChar(Seperator) + "~q [Chr(" + Seperator + ")], Word = ~q" + Word + "~q, LineNumber = " + LineNumber
		If Seperator = 10 Then
			If Self.ActualObject <> Null And Self.ifEnded And Self.LastWord.ToLower() <> "then" Then
				If Self.Parent = Null Then
					Return LexExceptionEnd.CreateEnd("Schliessung eines Ifs ohne vorhandenes If...", LineNumber, Null)
				EndIf
				If DEBUG_InfoOnSinglelineIfs Then DebugLog "~n~nIfEnded --> " + Self.Parent.ToString() + " [LastWord: " + Self.LastWord + "]"
				Self.Parent._EndLine = LineNumber - 1
				Self.Parent = Self.Parent._Parent
			End If
			If Self.InComment = True And Self.Declaration = "'" Then
				' Einzeiligen Kommentar beenden.
				Self.InComment = False
				Self.Declaration = ""
			End If
			
			Self.ifEnded = False
			
			Self.LastWord = ""
			Self.ActualObject = Null
			
			If Self.InComment <> True Then
				Self.Declaration = ""
			End If
		End If
		
		Select Word.ToLower()
			Case "type", "method", "function", "if", "rem", "select"
				If Self.LastWord.ToLower() = "end" Then
					Word = "End" + Word
				End If
		End Select

		If Self.InComment Then
			Select Word.ToLower()
				Case "endrem"
					If Self.Declaration <> "'" Then
						' EndRem kann durch ein Hochkommata auskommentiert werden.
						If Self.Declaration.ToLower() <> "rem" Then
							Return LexExceptionEnd.CreateEnd(Self.Declaration + " ohne " + Self._getEndKeyword(Self.Declaration)[0] + " (Zeile " + LineNumber + ")", LineNumber, Null)
						EndIf
						Self.Declaration = ""
						Self.InComment = False
					EndIf
			End Select
		Else
			If Word.ToLower() = "if" Or Word.ToLower() = "elseif" Or Word.ToLower() = "else" Then
				Self.ifEnded = False
			End If
			Select Word.ToLower()
				Case "rem"
					Self.Declaration = Word.ToLower()
					Self.InComment = True
				Case "'"
					Self.Declaration = Word
					Self.InComment = True
				Case "type", "method", "function"
					Self.Declaration = Word.ToLower()
				Case "const", "local", "global", "field"
					Self.ActualObject = Null
					Self.Declaration = Word.ToLower()
				Case "endtype", "endfunction", "endmethod", "forever", "until", "next", "wend", "endif"
					If Self.LastWord = "" Or Self.LastWord.ToLower() = "end" Then
						Local ex:LexExceptionBase = Self._endParent(Word, LineNumber)
						If ex Then Return ex
					EndIf
				Case "endselect"
					Local ex:LexExceptionBase = Self._endParent(Word, LineNumber)
					If ex Then Return ex
					If Self.Parent._Name.ToLower() <> "select" Then
						Return LexExceptionEnd.CreateEnd(Self.Declaration + " ohne Select?! (Zeile " + LineNumber + ")", LineNumber, Self.Parent)
					End If
					ex = Self._endParent(Word, LineNumber)
					If ex Then Return ex
				Case "elseif", "else", "case", "default"
					If Self.Parent._Declaration.ToLower() <> "select" Then
						Local ex:LexExceptionBase = Self._endParent(Word, LineNumber)
						If ex Then Return ex
					EndIf
					Self.ActualObject = Scope.Create(Word, Word, LineNumber, Self.Parent)
					Self.Parent = Self.ActualObject
				Case "for", "while", "repeat", "if", "select"
					Self.ActualObject = Scope.Create(Word, Word, LineNumber, Self.Parent)
					Self.Parent = Self.ActualObject
				Case "then"
					If Self.ActualObject And (Self.ActualObject._Name.ToLower() = "if" Or Self.ActualObject._Name.ToLower() = "elseif") Then
						Self.ifEnded = True
					Else
						Return LexExceptionEnd.CreateEnd(Word + " ohne If?! (Zeile " + LineNumber + ")", LineNumber, Self.Parent)
					EndIf
				Case "abstract"
					Select Self.Parent._Declaration.ToLower()
						Case "method", "function", "type"
							Self._endParent(Word, LineNumber)
						Default
							Return LexExceptionBase.CreateBase("~q" + Word + "~q ohne passendes Object (Zeile: " + LineNumber + ") [stattdessen: " + Self.ActualObject._Declaration + "]", LineNumber)
					End Select
				Default
					If Self.Declaration <> "" And Word <> "" Then
						If Self.ActualObject = Null And (Self.Declaration = "type" Or Self.Declaration = "method" Or Self.Declaration = "function") Then
							Self.ActualObject = Scope.Create(Word, Self.Declaration, LineNumber, Self.Parent)
							Self.Parent = Self.ActualObject
							Self.Declaration = "parameter"
						ElseIf Self.ActualObject <> Null And Self.LastWord.ToLower() = "extends" And Self.ActualObject._Declaration = "type" Then
							Self.ActualObject._Type = Word
						ElseIf Seperator = Asc(":") Then
							Self.ActualObject._Type = Word
						ElseIf Seperator = Asc(",") Or Seperator = Asc("(") Then
							Self.ActualObject = Scope.Create(Word, Self.Declaration, LineNumber, Self.Parent)
						ElseIf Seperator = Asc("=") Then
							Self.ActualObject._DefaultValue = Word
						ElseIf Seperator = Asc(" ") Then
							' Do nothing.
							If Self.ActualObject = Null Then
								Self.ActualObject = Scope.Create(Word, Self.Declaration, LineNumber, Self.Parent)
							End If
						ElseIf Seperator = Asc("[") Then
							If ActualObject <> Null Then
								Self.ActualObject._ArrayDimensions:+1
							EndIf
						Else
							Self.Declaration = ""
							DebugLog("DEB: Unerwarteter Seperator[Zeile: " + LineNumber + "]: ~q" + Chr(Seperator) + "~q (" + Seperator + ") (LastWord: " + Self.LastWord + ", NowWord: " + Word + ")")
						End If
					End If
			End Select
		End If
		If Word <> "" And Self.Declaration <> "'" Then
			Self.LastWord = Word
		EndIf
	End Method
	
	Method _endParent:LexExceptionBase(Word:String, LineNumber:Int)
		Select Word.ToLower()
			Case "abstract"
				If Not Self.Parent.IsFunction() Then
					Return LexExceptionBase.CreateBase(Self.Parent._Name + " unterstuetzt kein " + Word + ".", LineNumber)
				End If
				Self.Parent._IsAbstract = True
			Default
				If Not Self._isStartEndMatch(Self.Parent._Declaration, Word) Then
					Return LexExceptionEnd.CreateEnd(Self.Parent._Name + "<" + Self.Parent._Declaration + "> ohne " + Self._getEndKeyword(Self.Parent._Declaration)[0] + " [Stattdessen: " + Word + "] (Zeile " + Self.Parent._StartLine + " - " + LineNumber + ")", LineNumber, Self.Parent)
				End If
		EndSelect
		Self.Parent._EndLine = LineNumber
		Self.Parent = Self.Parent._Parent
	End Method
	
	Method _isStartEndMatch:Int(StartKeyword:String, EndKeyword:String)
		For Local s:String = EachIn Self._getEndKeyword(StartKeyword)
			If s.ToLower() = EndKeyword.ToLower() Then
				Return True
			End If
		Next
		Return False
	End Method

	Method _getEndKeyword:String[](StartKeyword:String)
		Select StartKeyword.ToLower()
			Case "if", "elseif"
				Return ["EndIf", "ElseIf", "Else"]
			Case "else"
				Return ["EndIf"]
			Case "select"
				Return ["EndSelect"]
			Case "case"
				Return ["EndSelect", "Case", "Default"]
			Case "default"
				Return ["EndSelect"]
			Case "repeat"
				Return ["Until", "Forever"]
			Case "for"
				Return ["Next"]
			Case "while"
				Return ["Wend"]
			Case "type"
				Return ["EndType"]
			Case "method"
				Return ["EndMethod"]
			Case "function"
				Return["EndFunction"]
			Case "rem"
				Return["EndRem"]
			Default
				Return [""]
		End Select
	End Method

	Method ResetLexer()
		Self.Parent = Null
		Self.Parent = Scope.Create("MAIN", "MAIN", -1, Null)
		Self.RootScope = Self.Parent
		ScopeContainer.Add(Self.Parent, Self.Path)
	End Method
	
	Method ToString:String()
		Return Self.Parent.GetMainScope().ToString()
	End Method
	
	Method GetRootScope:Scope()
		Return Self.Parent
	End Method
End Type

Rem
	bbdoc:Wird bei allgemeinen Fehlern ausgeloest.
End Rem
Type LexExceptionBase
	Field message:String, zeile:Int
	
	Function CreateBase:LexExceptionBase(Message:String, zeile:Int)
		Local tmp:LexExceptionBase = New LexExceptionBase
		tmp.message = Message
		tmp.zeile = zeile
		Return tmp
	End Function
	
	Method ToString:String()
		Return "LexExceptionBase: [Zeile: " + Self.zeile + "] " + message
	End Method
End Type

Rem
	bbdoc:Wird ausgeloest, wenn ein Scope ohne passendes Ende abgeschlossen wird.
End Rem
Type LexExceptionEnd Extends LexExceptionBase
	Field s:Scope
	
	Function CreateEnd:LexExceptionEnd(Message:String, zeile:Int, s:Scope)
		Local tmp:LexExceptionEnd = New LexExceptionEnd
		tmp.message = Message
		tmp.zeile = zeile
		tmp.s = s
		Return tmp
	End Function
	
	Method ToString:String()
		Local tmp:String = "LexExceptionEnd: [Zeile: " + Self.zeile + "] " + message
		If Self.s <> Null Then
			tmp :+ "~nLexExceptionEnd-Scope: " + s.ToString()
		End If
		Return tmp
	End Method
End Type

Type ScopeContainer
	Global _List:ScopeContainer[]
	Field _mainScope:Scope
	Field _Path:String
	
	Function Add(s:Scope, Path:String = "")
		Local tmp:ScopeContainer = New ScopeContainer
		tmp._mainScope = s
		tmp._Path = Path
		ScopeContainer._List = ScopeContainer._List[..(ScopeContainer._List.Length + 1)]
		ScopeContainer._List[ScopeContainer._List.Length - 1] = tmp
	End Function
	
	Rem
		bbdoc:Gibt alle Scopes, oder das Scope, fuer den uebergebenen Pfad zurueck.
	EndRem
	Function GetScopes:ScopeContainer[] (Path:String = "")
		If Path = "" Then
			Return Self._List
		Else
			For Local s:ScopeContainer = EachIn ScopeContainer._List
				If s._Path = Path Then
					Return[s]
				End If
			Next
		End If
	End Function
	
	Rem
		bbdoc:Gibt das Scope zurueck, welches den uebergebenen Namen traegt.
	EndRem
	Function GetNamedScope:Scope(Name:String)
		For Local sc:ScopeContainer = EachIn ScopeContainer._List
			Local s:Scope = sc.GetScope().GetChild(Name)
			If s <> Null Then
				Return s
			EndIf
		Next
		Return Null
	EndFunction
	
	Rem
		bbdoc:Gibt das MAIN-Scope zurueck.
	EndRem
	Method GetScope:Scope()
		Return Self._mainScope
	End Method
	
	Rem
		bbdoc:Gibt den Pfad der Datei zurueck.
	EndRem
	Method GetPath:String()
		Return Self._Path
	End Method
	
	Function Remove(s:Scope)
		DebugLog "Before: " + ScopeContainer._List.Length
		For Local i:Int = 0 Until ScopeContainer._List.Length
			If ScopeContainer._List[i].GetScope() = s Then
				ScopeContainer._List = ScopeContainer._List[..(i)] + ScopeContainer._List[(i + 1)..]
				Exit
			End If
		Next
		DebugLog "After: " + ScopeContainer._List.Length
	End Function
End Type

Type Scope
	'Global _Root:Scope
	Field _Name:String
	Field _DefaultValue:String
	Field _Declaration:String
	Field _ArrayDimensions:Int
	Field _Type:String
	Field _Parent:Scope
	Field _StartLine:Int
	Field _EndLine:Int
	Field _Childs:TList = New TList
	Field _IsAbstract:Int

	Function Create:Scope(Name:String, Declaration:String, StartLine:Int, parent:Scope)
		Local tmp:Scope = New Scope
		tmp._Name = Name
		tmp._Declaration = Declaration
		tmp._StartLine = StartLine
		tmp._EndLine = StartLine
		tmp._IsAbstract = False

		tmp.SetDefaultType()

		If parent <> Null Then
			parent.AddChild(tmp)
		End If
		'Else
			'ScopeContainer.Add(tmp, "")
		'	If Scope._Root <> Null Then Throw ("Es existiert bereits ein Root-Objekt")
			'Scope._Root = tmp
		'End If
		Return tmp
	End Function
	
	Method Compare:Int(withObject:Object)
		Local s:Scope = Scope(withObject)
		If Self._Name > s._Name Then
			Return 1
		ElseIf Object(Self) = Object(s) Then
			Return 0
		Else
			Return - 1
		End If
	End Method
	
	Rem
		bbdoc:Loescht das aktuelle Scope.
	EndRem
	Method Remove()
		If Self._Parent = Null Then
			ScopeContainer.Remove(Self)
		End If
		For Local s:Scope = EachIn Self._Childs
			s.Remove()
		Next
		Self._Childs.Clear()
		Self._Parent = Null
	End Method

	Rem
		bbdoc:Gibt das (unterste) Scope-Child-Objekt zurÃ¼ck (oder "Self", wenn es kein passendes Child gibt.) !! Line ist 0-basiert.
	EndRem
	Method GetChildFromLine:Scope(Line:Int)
		For Local s:Scope = EachIn Self._Childs
			If s._StartLine <= Line And s._EndLine >= Line Then
				Return s.GetChildFromLine(Line)
			End If
		Next
		Return Self
	End Method
	
	Rem
		bbdoc:Gibt ein Scope nach dem uebergebenen Path zurueck (Path = "Self.Object.AnotherObject.[...]") You should use "GetChildFromLine().GetScopeFromPath()".
	EndRem
	Method GetScopeFromPath:Scope(Path:String)
		Local pArray:String[] = Path.Split(".")
		If pArray[pArray.Length - 1] = "" Then pArray = pArray[..(pArray.Length - 1)]
		Local s:Scope = Self.GetNearestMatch(pArray[0])
		If s <> Null Then
			pArray = pArray[1..]
			For Local p:String = EachIn pArray
				If s.GetTypeScope() = Null Then
					DebugLog "GetScopeFromPath hat den Type ~q" + s._Type + "~q nicht gefunden :/ (Fuer Element: " + s._Name + ")"
					Return Null
				End If
				s = s.GetTypeScope().GetChild(p)
				If s = Null Then Exit
			Next
			'If s <> Null Then s = s.GetTypeScope()
		Else
			DebugLog "GetScopeFromPath hat das Anfangselement ~q" + pArray[0] + "~q nicht gefunden."
		End If
		Return s
	End Method
	
	Rem
		bbdoc:Gibt das Scope mit Namen "$Word" zurueck, welches am Naehsten "ueber" dem aktuellen Scope ist.
	EndRem
	Method GetNearestMatch:Scope(Word:String)
		Local s:Scope = Self
		While s.GetChild(Word) = Null
			s = s._Parent
			If s = Null Then Exit
		Wend
		If s <> Null Then
			s = s.GetChild(Word)
		Else
			s = ScopeContainer.GetNamedScope(Word)
			If s = Null Then Return Null
		End If
		Return s
	End Method
	
	Rem
		bbdoc:Gibt das Scope zurueck, welches mit "Word" uebereinstimmt.
	EndRem
	Method GetChild:Scope(Word:String)
		Select Word.ToLower()
			Case "self"
				If Self._Declaration = "type" Then
					Return Self
				End If
			Default
				For Local s:Scope = EachIn Self._Childs
					If s._Name.ToLower() = Word.ToLower() Then
						Return s
					End If
				Next
		End Select
		Return Null
	End Method
	
	Rem
		bbdoc:Gibt das Type-Scope von dem aktuellen Scope zurueck.
	EndRem
	Method GetTypeScope:Scope()
		Select Self._Declaration
			Case "type"
				Return Self
			Default
				'Local s:Scope = Self.GetMainScope().GetChild(Self._Type)
				'If s = Null Then
				'	
				'EndIf
				Return ScopeContainer.GetNamedScope(Self._Type)
		End Select
		's.GetChild(Self._Declaration)
	End Method
	
	Rem
		bbdoc:Gibt das Main-Scope zurueck.
	EndRem
	Method GetMainScope:Scope()
		Local s:Scope = Self
		While s._Parent <> Null
			s = s._Parent
		Wend
		Return s
	End Method
	
	Method IsLoop:Int()
		Select Self._Declaration
			Case "while", "repeat", "for"
				Return True
			Default
				Return False
		End Select
	End Method
	
	Method IsVariable:Int()
		Select Self._Declaration
			Case "parameter", "field", "local", "global", "const"
				Return True
			Default
				Return False
		End Select
	End Method
	
	Method IsParameter:Int()
		If Self._Declaration = "parameter" Then
			Return True
		Else
			Return False
		End If
	End Method
	
	Method IsType:Int()
		If Self._Declaration = "type" Then Return True
		Return False
	End Method
	
	Method IsFunction:Int()
		Select Self._Declaration
			Case "function", "method"
				Return True
			Default
				Return False
		End Select
	End Method
	
	Rem
		bbdoc:Gibt die Childs zurueck, welche an Zeile <Line> benutzt werden koennen. wird -1 fuer Line uebergeben, werden alle Childs zurueckgegeben.
	End Rem
	Method GetChilds:Scope[] (Line:Int = -1)
		Local tmp:Scope[] = New Scope[0]
		If Self.IsType() And Self._Type <> "" Then
			' Wenn der Type von einem anderen abgeleitet wurde,
			' werden dessen Childs mit ausgegeben.
			Local typeScope:Scope = Self.GetNearestMatch(Self._Type)
			If typeScope <> Null Then
				tmp = typeScope.GetChilds()
			Else
				DebugLog "TypeScope fuer Type ~q" + Self._Type + "~q nicht gefunden."
			EndIf
		End If
		For Local s:Scope = EachIn Self._Childs
			Select s._Declaration
				Case "local", "global", "const"
					If Line < 0 Or s._StartLine <= Line Then
						tmp = tmp[..(tmp.Length + 1)]
						tmp[tmp.Length - 1] = s
					End If
				Default
					tmp = tmp[..(tmp.Length + 1)]
					tmp[tmp.Length - 1] = s
			End Select
		Next
		Return tmp
	End Method
	
	Method SetDefaultType()
		Select Self._Declaration.ToLower()
			Case "parameter", "local", "const", "global", "field"
				Self._Type = "object"
			Case "type"
				Self._Type = "object"
			Case "function", "method"
				Self._Type = "void"
		End Select
	End Method

	Method AddChild(obj:Scope)
		Self._Childs.AddLast(obj)
		obj._Parent = Self
	End Method

	Method ToString:String()
		Return Self.ToString2()
	End Method

	Method ToString2:String(tabs:Int = 0)
		Local obj:String = RepeatString("~t", tabs) + Self.ToStringWithoutChilds()
		For Local s:Scope = EachIn Self._Childs
			obj :+ s.ToString2(tabs + 1)
		Next
		Return obj '.Remove(obj.Length - 1, 1)
	End Method
	
	Method ToStringWithoutChilds:String()
		Local obj:String = ""
		obj = "<" + Self._Declaration + ">"
		obj:+"[Line " + Self._StartLine
		If Self._StartLine <> Self._EndLine Then obj:+" - " + Self._EndLine
		obj :+ "] "
		obj :+ Self._Name
		If Self._Type <> Null Then obj :+ " : " + Self._Type
		If Self._ArrayDimensions > 0 Then obj:+"[]"
		If Self._IsAbstract Then obj:+" Abstract"
		If Self._DefaultValue <> Null Then obj:+" = " + Self._DefaultValue
		obj:+Chr(10)
		Return obj
	End Method
	
	'Function AsString:String()
	'	If Self._Root = Null Then
	'		Return "Assert: Scope.AsString: Scope._Root = Null"
	'	End If
	'	Return _Root.ToString()
	'End Function
	
	Function LoadFromXML:Scope(url:String)
		Local doc:TxmlDoc = TxmlDoc.parseFile(url)
		If doc = Null Then
			Notify app.lang.error_keywordXmlNotParsed, True
			Return Null
		End If
		
		Local s:Scope = scope.Create("MAIN", "MAIN", -1, Null)
		Local root:TxmlNode = doc.getRootElement()
		
		ScopeContainer.Add(s)
		
		For Local sChild:TxmlNode = EachIn root.getChildren()
			Scope._LoadFromXMLNode(sChild, s)
		Next
		
		Return s
	End Function
	
	Function _LoadFromXMLNode:Scope(Node:TxmlNode, Parent:Scope)
		Local s:Scope
		
		If Not Node.hasAttribute("name") Then
			' Variablen ohne Namen werden nicht benoetigt.
			If DEBUG_WarnOnXmlMissingAttribute Then
				DebugLog "Scope._LoadFromXMLNode [Parent: " + Parent._Declaration + " ~q" + Parent._Name + "~q] Node ohne Name-Attribut."
			EndIf
			Return Null
		End If
		
		' Variable types
		Const VAR_LOCAL:Int = 1
		Const VAR_GLOBAL:Int = 2
		Const VAR_CONST:Int = 3
		
		Select Node.getName().ToLower()
			Case "type"
				s = Scope.Create(Node.getAttribute("name"), "type", -1, Parent)
				
				Local xmlChilds:TList = node.getChildren()
				If xmlChilds Then
					For Local n:TxmlNode = EachIn xmlChilds
						Scope._LoadFromXMLNode(n, s)
					Next
				End If
			Case "function", "method"
				s = Scope.Create(Node.getAttribute("name"), Node.getName().ToLower(), -1, Parent)
				If Node.hasAttribute("type") Then
					s._Type = Node.getAttribute("type")
				End If
				Local xmlChilds:TList = node.getChildren()
				If xmlChilds Then
					For Local n:TxmlNode = EachIn xmlChilds
						Scope._LoadFromXMLNode(n, s)
					Next
				End If
			Case "variable"
				Select Parent._Declaration
					Case "function", "method"
						s = Scope.Create(Node.getAttribute("name"), "parameter", -1, Parent)
					Case "type"
						Local sDecleration:String = ""
						Select Int(Node.getAttribute("scope"))
							Case VAR_LOCAL
								sDecleration = "field"
							Case VAR_GLOBAL
								sDecleration = "global"
							Case VAR_CONST
								sDecleration = "const"
							Default
								If DEBUG_WarnOnXmlMissingAttribute Then
									DebugLog "Scope._LoadFromXMLNode [Parent: " + Parent._Declaration + " ~q" + Parent._Name + "~q] Node mit falschem Scope-Attribut."
								EndIf
								Return Null
						End Select
						s = Scope.Create(Node.getAttribute("name"), sDecleration, -1, Parent)
					Case "MAIN"
						Local sDecleration:String = ""
						Select Int(Node.getAttribute("scope"))
							Case VAR_LOCAL
								sDecleration = "local"
							Case VAR_GLOBAL
								sDecleration = "global"
							Case VAR_CONST
								sDecleration = "const"
							Default
								If DEBUG_WarnOnXmlMissingAttribute Then
									DebugLog "Scope._LoadFromXMLNode [Parent: " + Parent._Declaration + " ~q" + Parent._Name + "~q] Node mit falschem Scope-Attribut."
								EndIf
								Return Null
						End Select
						s = Scope.Create(Node.getAttribute("name"), sDecleration, -1, Parent)
				End Select
				If Node.hasAttribute("type") Then
					s._Type = Node.getAttribute("type")
				EndIf
		End Select
		Return s
	End Function
End Type
