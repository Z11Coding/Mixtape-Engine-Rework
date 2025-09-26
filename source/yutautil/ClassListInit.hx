package yutautil;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
#end

/**
 * Auto-initialization for ClassListMacro
 * This file automatically runs the class discovery when imported
 */
class ClassListInit {
    #if macro
    public static function __init__():Void {
        // Automatically initialize the class list macro
        ClassListMacro.build();

        trace("ClassListInit: Auto-initialized ClassListMacro");
    }
    #end
}

/**
 * Convenient macro for adding to your Main class or build process
 * Usage: Add --macro yutautil.ClassListInit.enableClassDiscovery() to your build args
 */
class ClassListMacros {
    #if macro
    public static function enableClassDiscovery():Void {
        ClassListMacro.build();
        trace("ClassListMacros: Class discovery enabled via macro");
    }

    public static function enableWithTracing():Void {
        ClassListMacro.build();
        // Add a compile-time trace of all classes
        Context.onAfterGenerate(function() {
            trace("=== COMPILE-TIME CLASS LIST ===");
            for (cls in ClassListMacro.allClasses) {
                trace('${cls.fullName} [${cls.isInterface ? "Interface" : cls.isAbstract ? "Abstract" : cls.isEnum ? "Enum" : "Class"}]');
            }
            trace("=== END CLASS LIST ===");
        });
        trace("ClassListMacros: Class discovery enabled with compile-time tracing");
    }
    #end
}
