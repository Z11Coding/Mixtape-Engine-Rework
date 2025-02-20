import haxe.ds.StringMap;
import haxe.rtti.Meta;
import Type;

class StateMap {
    public static function getAllFlxStateClasses():StringMap<Class<Dynamic>> {
        var flxStateMap:StringMap<Class<Dynamic>> = new StringMap<Class<Dynamic>>();
        
        // Iterate through all classes in the project
        for (className in Type.getClassFields(Type.resolveClass("Main"))) {
            var cls = Type.resolveClass(className);
            if (cls != null && Type.getClassName(cls) != "MusicBeatState" && isFlxStateSubclass(cls)) {
                flxStateMap.set(className, cls);
            }
        }
        
        return cast flxStateMap;
    }

    private static function isFlxStateSubclass(cls:Class<Dynamic>):Bool {
        var superClass = Type.getSuperClass(cls);
        while (superClass != null) {
            if (Type.getClassName(superClass) == "FlxState") {
                return true;
            }
            superClass = Type.getSuperClass(superClass);
        }
        return false;
    }
}