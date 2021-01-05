# AHK-WindowGrid
Cycle through window positions, inspired by the [gTile](https://github.com/gTile/gTile) extension for Gnome.

I created this to streamline workflow on a 21:9 ultra-widescreen display where I like to organize windows as 25%, 50%, 25% so my main task is in the center. Halves, thirds, and quarters are also useful. Perhaps this will be helpful for you as well!

Works for me with [AutoHotKey](https://autohotkey.com) (AHK) 1.1.30

## Grid Format

  * Format: grid size, top left corner tile, bottom right corner tile
  * Coordinate origin: The tile at `0:0` always corresponds to the **top left**, no matter the grid size. 
    In a `6x4` grid `5:3` is the bottom right tile
  * Format examples: `2x2 0:1 0:1` or `6x4 0:2 3:3, 0:0 3:3, 3x2 0:0 1:1` for multiple cyclable presets
    
    ![gTile Preset specification illustrated](https://user-images.githubusercontent.com/11145016/57080232-61310a00-6cf2-11e9-9ba2-bdd55b62fd2c.png)
    <!--
    | columns → | index    | 0         | 1         | 2         |
    | --------- | -------- | --------- | --------- | --------- |
    | **rows**  | **0**    | 0:0       | 1:0       | 2:0       |
    | **↓**     | **1**    | 0:1       | 1:1       | 2:1       |
    -->
  * Grid size format variants can either reuse the last grid format (e.g `6x4 0:2 3:3, 0:0 3:3`) or define a new grid (e.g `6x4 0:2 3:3, 8x6 0:0 3:3`)

*Note: Above explanation is borrowed directly from [gTile](https://github.com/gTile/gTile#configuration)*


## Examples

`WindowGrid.CycleWindowPosition` accepts parameters:
* `WinTitle` is any AHK [WinTitle](https://www.autohotkey.com/docs/misc/WinTitle.htm) query, e.g. `A` is the current active window
* `Positions` is a string of window locations to advance on each invocation, in a cyle. Syntax is described above in [Grid Format](#GridFormat)
* `Condition*` any number of AHK [Func](https://www.autohotkey.com/docs/objects/Func.htm) objects can be suppled. These filter and sort the entries established in `Positions` to achieve dynamic functionality, e.g.
    1. Remove locations that are below a minimum width
    2. Reverse the order of positions to allow forward and backward cycles
    3. etc.

See [`examples.ahk`](examples.ahk) for more. 

### Active Window snaps to 1/2 width, full height
<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>2</kbd>
```
^!2::WindowGrid.CycleWindowPosition("A", "2x1 0:0, 4x1 1:0 2:0, 2x1 1:1")
```

### Active window snaps to 1/3 width, half and full height
<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>3</kbd>, <kbd>Shift</kbd> reverses direction of cycle
```
 ^!3::
+^!3::WindowGrid.CycleWindowPosition("A"
      , "3x1 0:0, 1:0, 2:0,"
      . "3x2 0:0, 0:1, 1:0, 1:1, 2:0, 2:1"
      , WindowGrid.MinimumWidth
      , WindowGrid.Toggle("+", WindowGrid.Reversed))
```

### Align preset windows, if they exist, to known locations
<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>0</kbd>
```
^!0::
	SnapApplicationWindows() {
		; notepad.exe in top left
		WindowGrid.CycleWindowPosition("ahk_exe notepad.exe", "4x3 0:0")
		
		; winver.exe in center third
		WindowGrid.CycleWindowPosition("ahk_exe winver.exe", "3x3 1:1")
	}
```

## References

* [gTile](https://github.com/gTile/gTile) Gnome shell extension offers similar functionality
* AHK methods similar to [AdvancedWindowSnap](https://gist.github.com/AWMooreCO/1ef708055a11862ca9dc) and its [forks](https://gist.github.com/park-brian/f3f790e559e5145b99bf0f19c7928dd8)
* Uses [WinGetPosEx](https://github.com/pacobyte/AutoHotkey-Lib-WinGetPosEx) to calculate true window dimensions (Aero/DWM makes this a nontrivial task with each major Windows release)
