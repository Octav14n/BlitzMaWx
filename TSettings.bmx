Global Settings:TSettings = New TSettings

Rem
	bbdoc:Type um Settings zu speichern.
End Rem
Type TSettings
	Global _instance:TSettings
	Field _setting:TMap
	
	Method New()
		If TSettings._instance <> Null Then
			Throw "Es kann nur eine Instance von TSettings erstellt werden!"
		End If
		TSettings._instance = Self
		Self._setting = New TMap
	End Method
	
	Rem
		bbdoc:Gibt die Setting zurueck.
	End Rem
	Method Get:String(Name:String)
		Return String(Self._setting.ValueForKey(Name))
	End Method
	
	Rem
		bbdoc:Setzt das uebergebene Setting.
	End Rem
	Method Set(Name:String, Value:String)
		Self._setting.Insert(Name, Value)
	End Method
	
	Rem
		bbdoc:Setzt die Default-Settings fuer den uebergebenen Namen.
	End Rem
	Method SetDefault(Name:String, Value:String)
		If Not Self._setting.Contains(Name) Then
			Self._setting.Insert(Name, Value)
		End If
	End Method
	
	Method Save(Url:String)
		Local xml:TxmlDoc = TxmlDoc.newDoc("1.0")
		Local root:TxmlNode = TxmlNode.newNode("setting")
		xml.setRootElement(root)
		For Local setting:String = EachIn Self._setting.Keys()
			Local node:TxmlNode = root.addChild("property")
			node.addAttribute("key", setting)
			node.addAttribute("value", String(Self._setting.ValueForKey(setting)))
		Next
		xml.saveFormatFile(Url, True)
	End Method
	
	Function LoadXML(Url:String)
		If FileType(Url) <> FILETYPE_FILE Then Return
		Local doc:TxmlDoc = TxmlDoc.parseFile(url)
		If doc <> Null Then
			Local root:TxmlNode = doc.getRootElement()
			For Local node:TxmlNode = EachIn root.getChildren()
				TSettings._instance.Set(node.getAttribute("key"), node.getAttribute("value"))
			Next
		End If
		
	End Function
End Type
