import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class StateCollector {
    public static var possibleStates:Array<Class<Dynamic>> = [];

    public static macro function collectStates():Expr {
        var types = Context.getAllModuleTypes();

        for (type in types) {
            if (isStateClass(type)) {
                var cl = Context.getType(type).get();
                if (cl != null && haxe.macro.TypeTools.isClassType(cl)) {
                    possibleStates.push(cast cl);
                }
            }
        }

        return macro [];
    }

    private static function isStateClass(typeName:String):Bool {
        var classType = Context.getType(typeName);
        
        if (classType != null && haxe.macro.TypeTools.isClassType(classType)) {
            var superType:Type.Ref<ClassType> = cast classType;
            
            while (superType != null) {
                if (superType.get().name == "flixel.FlxState") {
                    return true;
                }
                
                superType = switch superType.get().superClass {
                    case Some(sc): cast sc;
                    case None: null;
                };
            }
        }
        return false;
    }
}
