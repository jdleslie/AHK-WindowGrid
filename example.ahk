#NoEnv
#Include <WindowGrid>

^!r::Reload

^!1::WindowGrid.CycleWindowPosition("A", "1x1 0:0")

; Active window snaps to 1/2 width, full height
^!2:: WindowGrid.CycleWindowPosition("A", "4x1 1:0 2:0, 2x1 0:0, 1:0")

; Active window snaps to 1/3 width, half and full height
 ^!3::
+^!3::WindowGrid.CycleWindowPosition("A"
      , "3x1 0:0, 1:0, 2:0,"
	  . "3x2 0:0, 0:1, 1:0, 1:1, 2:0, 2:1"
	  , WindowGrid.MinimumWidth
      , WindowGrid.Toggle("+", WindowGrid.Reversed))

; Active window snaps to 1/4 width, half and full height
 ^!4::
+^!4::WindowGrid.CycleWindowPosition("A"
      , "4x1 0:0, 1:0, 2:0, 3:0, "
	  . "4x2 0:0, 0:1, 1:0, 1:1, 2:0, 2:1, 3:0, 3:1"
	  , WindowGrid.MinimumWidth
      , WindowGrid.Toggle("+", WindowGrid.Reversed))

; Align preset windows, if they exist, to known locations
^!0::
	SnapApplicationWindows() {
		; notepad.exe in top left
		WindowGrid.CycleWindowPosition("ahk_exe notepad.exe", "4x3 0:0")
		
		; winver.exe in center third
		WindowGrid.CycleWindowPosition("ahk_exe winver.exe", "3x3 1:1")
	}