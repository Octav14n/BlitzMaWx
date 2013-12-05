SuperStrict
Include "blitzmaxTest2.bmx"

Graphics 800, 600

If True Then ' Test
	Print "Das Programm startet jetzt!"
EndIf

For Local i:Int = 0 To 10
	If False Then
		Print "Test"
	EndIf
Next

Local mx:Int, my:Int
Local gameObjects:TList = New TList
Local test:Int
Const TEST_1:Int = 1

'DebugStop

Type TGameObject
	Field x:Int, y:Int
	Field subObject:TGameObject
	
	Method Test:Int() Abstract
	
	Rem
		bbdoc:Updated das Objekt.
	EndRem
	Method Update()
		Local newY:Int = Self.x + 10
		
		Self.y = newY
	End Method
	
	Method SetX(Value:Int)
		Self.x = Value
	End Method
	
	Rem
		bbdoc:Malt das Objekt an die angegebene Position
	EndRem
	Method Draw()
		DrawText "test", Self.x, Self.y
	EndMethod
End Type



Repeat
	Cls
	
	DrawText "test", MouseX(), MouseY()
	' Dies ist ein Kommentar
	
	Rem
		Ein mehrzeiliger Kommentar?
		Juhu, selbst das funzt!
	End Rem
	If MouseHit(1) Then
		Print "MouseHit(1)"
		Local tgo:TGameObject = New TGameObject
		tgo.x = MouseX()
		tgo.y = MouseY()
		tgo.Test()
		gameObjects.AddLast(tgo)
	EndIf
	
	If KeyHit(KEY_F1) Then Throw("Test")
	
	For Local tgo:TGameObject = EachIn gameObjects
		tgo.Update()
		If tgo.y > GraphicsHeight() then
			gameObjects.Remove(tgo)
		Else
			tgo.Draw()
		EndIf
	Next
	
	Flip
Until KeyHit(KEY_ESCAPE) Or AppTerminate() = TEST_1
End
