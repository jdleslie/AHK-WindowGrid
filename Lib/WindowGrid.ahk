/**
 * WindowGrid organizes windows using a list of 2D grid of preset positions
 * you define and assign to hotkeys. Functionality is inspired by Gnome gTile.
 * Grids are dynamically scaled to match native monitor resolution.
 *
 * Additionally, grids can be used to assign arbitrary windows (e.g. assign
 * notepad.exe to the same position.
 *
 * Look at `example.ahk` for examples.
 *
 * @author jdleslie
 * @license MIT
 *
 * @link https://github/jdleslie/AHK-WindowGrid
 */
class WindowGrid {
	static _OriginalPositions = {}

	/**
	 * Reverse order of window positions
	 *
	 * @param WindowPositions Array of candidate WindowPosition objects
	 * @return Reversed list of WindowPosition objects
	 */
	Reversed(WindowPositions) {
		Result := []
		For Index, Position in WindowPositions
			Result.InsertAt(1, Position)
		Return Result
	}
	
	/**
	 * Remove window positions with width smaller than 900 pixels
	 *
	 * @param WindowPositions Array of candidate WindowPosition objects
	 * @return Pruned list of WindowPosition objects
	 */
	MinimumWidth(WindowPositions) {
		Result := []
		For Index, Position in WindowPositions
			If (Position.Width > 900)
				Result.Push(Position)
		Return Result
	}
	
	/**
	 * Apply a condition filter if a specified Hotkey is among those pressed.
	 * Advance cycle forward and backward depending on the presence of
	 * a single modifier, e.g. Ctrl+Alt+1 might cycle forward and 
	 * Shift+Ctrl+Alt+1 might cycle backward when 
	 * `WindowGrid.Toggle("+", WindowGrid.Reversed)` is a condition.
	 *
	 * @param Hotkey Single character to find in `A_ThisHotkey`
	 * @param Wrapped Condition function to apply when `Hotkey` is present
	 */
	Toggle(Hotkey, Wrapped) {
		If (InStr(A_ThisHotkey, Hotkey))
			Return Wrapped
	}

	/**
	 * Advance window position through a list of grid positions, restoring the
	 * original position before looping the cycle.
	 *
	 * @param WinTitle See: https://www.autohotkey.com/docs/misc/WinTitle.htm
	 * @param Positions See: https://github.com/gTile/gTile#configuration
	 * @param Condition Optional functions (any number of arguments are OK)
	 *                  that accept an array of WindowPosition objects and 
	 *                  return the same (to facilitate filtering, sorting, 
	 *                  etc.)
	 * @return Nothing
	 */
	CycleWindowPosition(WinTitle, Positions, Conditions*) {
		; Remember original window positions for last step in cycle. 
		; All cycles containing the same WinTitle parameter share the same
		; OriginalPositions history, so cycling an active window ("A") to 
		; 2x1 0:0 and then 3x1 0:0, 1:0, 2:0 will restore to the original position 
		; of the window when it started its first "A" cycle.
		OriginalPositions := {}
		If (This._OriginalPositions[WinTitle])
			OriginalPositions := This._OriginalPositions[WinTitle]
			
		
		; Procure HWND
		hWindow := WinExist(WinTitle)
		
		; Available viewport for windows
		CurrentMonitor := This._Import.GetMonitorIndexFromWindow(hWindow)
		SysGet, MonitorWorkArea, MonitorWorkArea, CurrentMonitor
		MonitorWorkArea := [MonitorWorkAreaRight  - MonitorWorkAreaLeft
		,                   MonitorWorkAreaBottom - MonitorWorkAreaTop]
		
		; Coordinates for window, including DWM/Aero offsets
		RawPosition     := This._Invoke_GetWinGetPosEx(hWindow)
		RawOffset       := RawPosition.Offset
		CurrentOffset   := [-1 * RawOffset.Left ; x
		,                   -1 * RawOffset.Top  ; y
		,                   (RawOffset.Left + RawOffset.Right)   ; width
		,                   (RawOffset.Top  + RawOffset.Bottom)] ; height
		
		; Formulate position of window as WindowPosition for matching
		CurrentPosition := RawPosition.RECTPlus
		CurrentPosition.Push(MonitorWorkArea*)
		CurrentPosition := new This.WindowPosition(CurrentPosition*)
		
		; Scale candidate positions to current viewport
		CandidatePositions := []
		For Index, Value in This._ParsePositions(Positions)
			CandidatePositions.Push(Value.Scale(MonitorWorkArea*))
		
		; Filter candidate positions via conditions that accept an array of
		; WindowPosition objects as an argument and return the same (perhaps
		; modulo some filter criteria)
		For Index, Fn in Conditions
			If (Fn.MaxParams > 1)
				Fn := Fn.Bind(This)
			Result := Fn.Call(CandidatePositions)
			If (Result.Length())
				CandidatePositions := Result


		; Iterate through candidate positions and identify if currently active
		; window occupies any already. If so, advance to the next position in cycle
		For Index, Position in CandidatePositions 
		{
			NextPosition := Position
			
			If (LastPosition.Equal(CurrentPosition))
				Break
			If (Index == 1)
				InitialPosition := NextPosition

			LastPosition := NextPosition
		}
		
		; First iteration and looping of cycles 
		If (NextPosition == LastPosition)
			If (LastPosition.Equal(CurrentPosition) 
				and OriginalPositions[hWindow])
			{
				If (not OriginalPositions[hWindow].Equal(CurrentPosition))
					NextPosition := OriginalPositions[hWindow] ; Restore original window position 
				Else
					NextPosition := InitialPosition
				OriginalPositions.Remove(hWindow)
			} Else {
				If (not OriginalPositions[hWindow])
					OriginalPositions[hWindow] := CurrentPosition ; Store original window position
				NextPosition := InitialPosition
			}

		; Update original position storage
		This._OriginalPositions[WinTitle] := OriginalPositions

		; Apply offset from window to the next position 
		NextPosition.Add(CurrentOffset*)

		
		; Move and resize selected window
		WinMove ahk_id %hWindow%, , NextPosition.X,     NextPosition.Y
		,                           NextPosition.Width, NextPosition.Height
	}
	
	/**
	 * Window position, tracked in whole units (integers)
	 */
	class WindowPosition {
		__New(X, Y, Width, Height, Max_X, Max_Y) {			
			If (X + Y + Width + Height + Max_X + Max_Y) is integer
			{
				If ((Max_X >= 0) and (Max_Y >= 0))
				{
					; Negative and beyond-max sizes are common with Aero/DWM,
					; so not much to be validated
					This.X := X 
					This.Y := Y
					This.Width := Floor(Width)
					This.Height := Floor(Height)
					This.Max := {X: Max_X, Y: Max_Y}
					This.Max := {X: Max_X, Y: Max_Y}
				} Else {
					Throw "Maximum height and width must be greater than zero"
				}
			} Else 
				Throw "All values must be integers"
		}
		
		
		Equal(Other) {
			Return (This.X       == Other.X) 
			and    (This.Y       == Other.Y)
			and    (This.Width   == Other.Width) 
			and    (This.Height  == Other.Height)
			and    (This.Max.X == Other.Max.X)
			and    (This.Max.Y == Other.Max.Y)
		}
		
		
		Add(X, Y, Width, Height) {
			This.X += X
			This.Y += Y
			This.Width  += Width
			This.Height += Height
			
			Return This
		}
		
		
		Scale(Max_X, Max_Y) {			
			; Remaining units to be allocated
			Remainder := {X: Mod(Max_X, This.Max.X)
			,             Y: Mod(Max_Y, This.Max.Y)}
			
			; Allocate remaining units as +1 to each of the 0..Remainder grid cells
			Adjust := {}
			Adjust.X      := Min(This.X, Remainder.X)
			Adjust.Y      := Min(This.Y, Remainder.Y)
			Adjust.Width  := Remainder.X - Adjust.X
			Adjust.Height := Remainder.Y - Adjust.Y
			
			; Integer multiplier for each whole unit of grid
			Factor := {X: Max_X // This.Max.X
			,          Y: Max_Y // This.Max.Y}
			
			Result := [Factor.X * This.X      + Adjust.X
			,          Factor.Y * This.Y      + Adjust.Y
			,          Factor.X * This.Width  + Adjust.Width
			,          Factor.Y * This.Height + Adjust.Height
			,          Max_X, Max_Y]
			Result := new This(Result*), Result.Parent := This
			Return Result
		}
		
		ToString() {
			Return   This.X     . ", " . This.Y 
			. " "  . This.Width . ", " . This.Height 
			. " (" . This.Max.X . ", " . This.Max.Y . ")"
		}
	}

	/**
	 * Parse WindowPosition objects from a comma delimited string.
	 * Syntax borrowed from gTile.
	 */
	_ParsePositions(PositionsRaw) {
		Offset := 1 ; initial value for first iteration
		Position_RegEx := "Sm)"
		.                 "\b(\d+)" ; width
		.                 "([x:])" ; flag type of position
		.                 "(\d+)\b" ; height
		.                 "\s*"
		.                 "(,)?" ; contains comma when position is fully specified
		
		; Ultimately ["grid_width", "grid_height", "x", "y", "width", "height"]
		Position  := []
		All_Positions := []
		Index     := 1

		While (Offset := RegExMatch(""
			. PositionsRaw . "," ; append comma so last record is closed correctly
			, Position_RegEx
			, M
			, Offset + StrLen(M))) 
		{
			If (M2 = "x") 
				Index := 1
			Else If ((M1 >= Position[1]) or (M3 >= Position[2]))
				Throw Exception("Invalid position for " 
				.               Position[1] . "x" . Position[2] . " grid: " 
				.               M1 . ":" . M3)
			Else If ((Index > 4) and ((M1 < Position[3]) or (M3 < Position[4])))
				Throw Exception("End position is before start: "
				.               M1 . ":" . M3 . " < " 
				.               Position[3] . ":" . Position[4])

					
			Position[Index++] := M1
			Position[Index++] := M3
			
			
			If (M4 and (Index == 5)) {
				Position[Index++] := M1
				Position[Index++] := M3
			}
			
			If (M4)
				If (Index == 7) {
					Position[5] += -1 * Position[3] + 1
					Position[6] += -1 * Position[4] + 1
					
					; Shift grid dimensions to be last two entries
					Position_Result := Position.Clone()
					Position_Result.Push(Position[1], Position[2])
					Position_Result.RemoveAt(1, 2)
					
					All_Positions.Push(new This.WindowPosition(Position_Result*))
					
					Index := 3
				} Else {
					Throw Exception("Incomplete position in: " . M 
					.               ", Index=" . Index 
					.               ", Offset=" . Offset)
				}
		}
		
		Return All_Positions
	}

	/**
	 * Class isolation for external includes
	 */
	class _Import {
		; https://github.com/pacobyte/AutoHotkey-Lib-WinGetPosEx/blob/master/WinGetPosEx.ahk
		#Include <WinGetPosEx>
		
		#Include <GetMonitorIndexForWindow>
	}

	_Invoke_GetWinGetPosEx(hWindow) {
		This._Import.WinGetPosEx(hWindow
		,           X, Y, Width, Height
		,           Offset_Left, Offset_Top, Offset_Right, Offset_Bottom)
		
		Offset := {Left: Offset_Left, Right: Offset_Right
		,          Top: Offset_Top, Bottom: Offset_Bottom}
		
		Return {RECTPlus: [X, Y, Width, Height], Offset: Offset}
	}
}
