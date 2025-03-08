package backend.window;

import haxe.macro.Context;
import haxe.macro.Expr;

import haxe.ds.StringMap;
import haxe.crypto.Md5;

class Assembly {
    static var counter:Int = 0;
    static var usedNames:StringMap<Bool> = new StringMap<Bool>();

    public static macro function asm(assem:String):Expr {
        var uniqueName = generateUniqueName(assem);
        return macro {
            @:functionCode('
                asm($assem);
            ')
            function _writeAssemblyCode_$uniqueName():Void {
                // This is a placeholder function for the assembly code
            }

            function assemblyCode_$uniqueName():Void {
                _writeAssemblyCode_$uniqueName();
            }
        };
    }

    static function generateUniqueName(assem:String):String {
        var baseName = "asm_" + Md5.encode(assem).substr(0, 8);
        var uniqueName = baseName;
        while (usedNames.exists(uniqueName)) {
            counter++;
            uniqueName = baseName + "_" + counter;
        }
        usedNames.set(uniqueName, true);
        return uniqueName;
    }
}
