Type TColor
	Field _r:Int, _g:Int, _b:Int
	Method Set(r:Int, g:Int, b:Int)
		Self._r = r
		Self._g = g
		Self._b = b
		DebugLog "graphics : " + (r / g)
	End Method
	
	Method Apply()
		SetColor Self._r, Self._g, Self._b
	End Method
End Type

Type TColorAnim Extends TColor
	Field _rA:Int, _gA:Int, _bA:Int, zactiviert:Int
	Method SetA(r:Int, g:Int, b:Int)
		Self._rA = r
		Self._gA = g
		Self._bA = b
	End Method
	
	Method Apply()
		Local rB:Int, gB:Int, bB:Int
		rB = Self._r + (MilliSecs() Mod Self._rA)
		gB = Self._g + (MilliSecs() Mod Self._gA)
		bB = Self._b + (MilliSecs() Mod Self._bA)
		SetColor rB, gB, bB
	End Method
End Type

Print "Now starting."
'DebugStop
Local col:TColorAnim = New TColorAnim
col.Set(0, 0, 0)
DebugStop
















