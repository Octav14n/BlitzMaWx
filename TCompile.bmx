Const wxEVT_COMPILE_FIRST:Int = wxEVT_USER_FIRST + 1
Const wxEVT_COMPILE_ERROR:Int = wxEVT_COMPILE_FIRST + 1
Const wxEVT_COMPILE_END:Int = wxEVT_COMPILE_FIRST + 2
Const wxEVT_COMPILE_DEBUG:Int = wxEVT_COMPILE_FIRST + 3

Type TCompile Extends wxEvtHandler
?Win32
	Const EXE_ENDUNG:String = ".exe"
?Not Win32
	Const EXE_ENDUNG:String = ""
?
	Field _bmxPath:String
	Field debug:Int, execute:Int, quick:Int
	
	Function IsValidBLitzMaxPath:Int(BlitzMaxPath:String)
		Return FileType(BlitzMaxPath + "/bin/bmk" + EXE_ENDUNG) <> FILETYPE_FILE
	End Function
	
	Method Create:TCompile(BlitzMaxPath:String)
		Assert FileType(BlitzMaxPath) = FILETYPE_DIR, "Invalid BlitzMaxPath (should have been catched in main.bmx)"
		
		Self._bmxPath = BlitzMaxPath
		Return Self
	End Method
	
	Rem
		bbdoc:
	End Rem
	Method Build(compilePfad:String, execute:Int = -1)
		If execute = -1 Then execute = Self.execute
		Local Pfad:String = Self._bmkBuildExecString(compilePfad, Self.debug, execute, Self.quick)
		
		Print "Execute: " + Pfad
		Local proc:TProcess = TProcess.Create(Pfad, HIDECONSOLE)
		If proc = Null Then
			Self.AddPendingEvent(New wxCompileEvent)
			Notify(app.lang.error_programmDosntStart)
		Else
			If proc Then
				app.frameMain.createDebugDialog()
				app.setProgRunnint(proc)
			Else
				Local errorText:String = ""
				While proc.Status() Or proc.pipe.ReadAvail()
					If proc.pipe.ReadAvail() Then
						errorText:+Chr(proc.pipe.ReadByte())
					EndIf
				Wend
				TDebugPanel.addDebugMessage(app.lang.error_programmDosntStart + "~nExecute-Error: " + errorText)
			EndIf
		End If
	End Method
	
	Rem
		bbdoc:Gibt den BlitzMax-Basis-Ordner zurück.
	End Rem
	Method GetBlitzMaxPath:String()
		Return Self._bmxPath
	End Method
	
	Rem
		bbdoc:Erstellt den bmk-Pfad-String.
	EndRem
	Method _bmkBuildExecString:String(compilePfad:String, debug:Int, execute:Int, quick:Int)
		Local Pfad:String = "~q" + Self.GetBlitzMaxPath() + "/bin/bmk" + EXE_ENDUNG + "~q makeapp "
		If execute Then Pfad :+ "-x "
		If Not quick Then Pfad :+ "-a "
		If debug Then Pfad :+ "-o ~q" + StripExt(RealPath(compilePfad)) + ".debug" + EXE_ENDUNG + "~q "
		Pfad :+ "~q" + compilePfad + "~q"
		Return Pfad
	EndMethod
End Type

Type wxCompileEvent Extends wxEvent
	Field _line:Int, _relPos:Int
	Field _message:String
	
	Function Create:wxEvent(wxEventPtr:Byte Ptr, evt:TEventHandler)
		Local this:wxCompileEvent = New wxCompileEvent 
		
		this.init(wxEventPtr, evt)
		
		Return this
	End Function
	
	Method Initialize:wxEvent(line:Int=-1, pos:Int=-1, message:String = "")
		Self._line = line
		Self._relPos = pos
		Self._message = message
		Return Self
	End Method
End Type
