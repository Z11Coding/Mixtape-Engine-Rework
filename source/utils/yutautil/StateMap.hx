package utils.yutautil;

import haxe.ds.StringMap;
import haxe.rtti.Meta;
import Type;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class StateMap {

    public static var states:StringMap<Dynamic>;


    private static function getStatesImpl(paths:Array<String>):StringMap<Dynamic> {
        var classes = paths.map(function(path) return Type.resolveClass(path));
        var stateMap = new StringMap<Dynamic>();
        for (thing in classes) {
            var cls = thing;
            if (cls == null) {
                continue;
            }else if (isFlxStateSubclass(cls)) {
                    var resolvedClass = cls;
                    if (resolvedClass != null) {
                        stateMap.set(Type.getClassName(cls), resolvedClass);
                    }
                }
            }
        return stateMap;
    }

    macro public static function initializeStates():Expr {
        Context.onAfterTyping(function(_types: Array<haxe.macro.Type.ModuleType>) {
            // for 
            states = getStatesImpl(Context.getClassPath());
            trace(states);
            // trace(Context.getClassPath());
        });
        return macro null;
    }

    public static function isFlxStateSubclass(cls:Class<Dynamic>):Bool {
        var base:Class<Dynamic> = cls;
        while (true) {
            var superClass = Type.getSuperClass(base);
            if (superClass == null || Type.getClassName(superClass) == "flixel.FlxState") {
                break;
            }
            base = superClass;
        }
        return (Type.getClassName(base) == "flixel.FlxState"); 
    }
}