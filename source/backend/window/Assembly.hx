package backend.window;

import haxe.macro.Context;
import haxe.macro.Expr;

class Assembly {
    public static macro function asm(assem:String):Expr {
        return macro {
            @:functionCode('
                asm($assem);
            ')
            function _writeAssemblyCode():Void {
                // This is a placeholder function for the assembly code
            }

            function assemblyCode():Void {
                _writeAssemblyCode();
            }
        };
    }
}
