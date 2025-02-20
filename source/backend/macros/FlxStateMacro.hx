package backend.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class FlxStateMacro {
    public static function build():Array<Field> {
        var fields:Array<Field> = [];
        var stateMapExpr = buildStateMap();
        fields.push({
            name: "stateMap",
            access: [Access.APublic, Access.AStatic],
            kind: FieldType.FVar(macro:Map<String, Class<Dynamic>>, stateMapExpr),
            pos: Context.currentPos()
        });
        return fields;
    }

    private static function buildStateMap():Expr {
        var stateMap = macro new Map<String, Class<Dynamic>>();
        var types = Context.getBuildFields().kind;
        for (type in types) {
            switch (type) {
                case TClassDecl(classDecl):
                    if (isFlxState(classDecl) || isFlxSubState(classDecl)) {
                        var className = classDecl.get().name;
                        stateMap = macro $stateMap.set(className, classDecl);
                    }
                default:
            }
        }
        return stateMap;
    }

    private static function isFlxState(classDecl:Ref<ClassType>):Bool {
        return Type.getSuperClass(classDecl) == Type.resolveClass("flixel.FlxState");
    }

    private static function isFlxSubState(classDecl:Ref<ClassType>):Bool {
        return Type.getSuperClass(classDecl) == Type.resolveClass("flixel.FlxSubState");
    }
}