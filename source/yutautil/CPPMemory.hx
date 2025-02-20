package yutautil;

#if cpp
import cpp.Lib;
#end

// HEAVY WIP FOR A FULL C++ ACCESS API FOR MORE LOW LEVEL CONTROL.

class CPPMemory {
    public static function allocate(size:Int):Dynamic {
        #if cpp
        return cpp.Lib.load("std", "malloc", 1)(size);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function free(ptr:Dynamic):Void {
        #if cpp
        cpp.Lib.load("std", "free", 1)(ptr);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function set(ptr:Dynamic, value:Dynamic, size:Int):Void {
        #if cpp
        cpp.Lib.load("std", "memset", 3)(ptr, value, size);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function copy(dest:Dynamic, src:Dynamic, size:Int):Void {
        #if cpp
        cpp.Lib.load("std", "memcpy", 3)(dest, src, size);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function getPointer(value:Dynamic):String {
        #if cpp
        return cpp.Lib.toString(cpp.Pointer.addressOf(value));
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function getValueFromPointer(pointer:String):Dynamic {
        #if cpp
        var address = Std.parseInt(pointer);
        return cpp.Pointer.addressOf(address);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }

    public static function setValueAtPointer(pointer:String, value:Dynamic):Void {
        #if cpp
        var address = Std.parseInt(pointer);
        var ptr = cpp.Pointer.addressOf(address);
        ptr.set(value);
        #else
        throw "This function is only available for C++ targets.";
        #end
    }
}