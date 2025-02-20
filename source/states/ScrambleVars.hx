package states;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.TypeTools;

class ScrambleVars {
    public static macro function scrambleOrRandomize():Expr {
        var classes = Context.getBuildFields();
        for (clas in classes) {
            switch clas {
                case FVar(_, _):
                    // Skip variable declarations
                case FMethod(_, func):
                    // Skip method declarations
                case FEnum(_, _):
                    // Skip enum declarations
                case FTypedef(_, _):
                    // Skip typedef declarations
                case FClass(c):
                    // Scramble the class fields
                    scrambleClassFields(c);
                case _:
            }
            case FVar(_, field):
                // Scramble the variable name and value
                scrambleVariable(field);
            case _:
        }
        var fields = Context.getLocalClass();
        for (field in fields) {
            switch field.kind {
                case FVar(t, e):
                    var newName = Math.random() < 0.5 ? scrambleName(field.name) : field.name;
                    var newValue:Expr = Math.random() < 0.5 ? macro $v{Std.int(Math.random() * 100)} : macro $v{Math.random()};
                    field.name = newName;
                    field.kind = FVar(t, switch e { case null: newValue; case _: newValue; });
                case _:
            }
        }
        return macro null;
    }

    static function scrambleClassFields(c:ClassType):Void {
        for (field in c.fields) {
            field.name = scrambleName(field.name);
        }
    }

    static function scrambleVariable(field:Field):Void {
        field.name = scrambleName(field.name);
    }

    static function scrambleName(name:String):String {
        // Simple scramble function (for demonstration)
        return haxe.crypto.Md5.encode(name).substr(0, 8);
    }
}
