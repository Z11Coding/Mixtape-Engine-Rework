#if windows
package backend.window;

// most codes stolen from vs dave and bambi source code.
/*
    VS DAVE WINDOWS/LINUX/MACOS UTIL
    You can use this code while you give credit to it.
    65% of the code written by chromasen
    35% of the code written by Erizur (cross-platform and extra windows utils)

    Windows: You need the Windows SDK (any version) to compile.
    Linux: TODO
    macOS: TODO
*/

@:cppFileCode('#include <stdlib.h>
#include <stdio.h>
#include <windows.h>
#include <winuser.h>
#include <dwmapi.h>
#include <strsafe.h>
#include <shellapi.h>
#include <iostream>
#include <string>

#pragma comment(lib, "Dwmapi")
#pragma comment(lib, "Shell32.lib")')
class WindowUtil
{
    #if windows
	@:functionCode('
        HWND hWnd = GetActiveWindow();
        int colors[] = {red, green, blue, alpha};
        res = SetWindowLong(hWnd, GWL_EXSTYLE, GetWindowLong(hWnd, GWL_EXSTYLE) | WS_EX_LAYERED);
        if (res)
        {
            SetLayeredWindowAttributes(hWnd, RGB(colors[0], colors[1], colors[2]), colors[3], LWA_COLORKEY);
        }
    ')
	static public function setWindowAlpha(red:Int = 0, green:Int = 0, blue:Int = 0, alpha:Int = 0, res:Int = 0)
	{
        Sys.println('Setting Window Color: $red, $green, $blue, $alpha');
		return res;
	}
    #end
}
#end