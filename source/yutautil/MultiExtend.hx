package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class MultiExtend<T> {
    private var extended:T;

    public function new(base:T) {
        this.extended = base;
    }

    public function superCall<U>(method:String, args:Array<Dynamic>):U {
        return Reflect.callMethod(extended, Reflect.field(extended, method), args);
    }

    public function getExtended():T {
        return this.extended;
    }
}

class MultiExtendMacro {
    public static macro function enforceSuper():Expr {
        var fields = Context.getBuildFields();
        for (field in fields) {
            if (field.kind == FieldType.FFun) {
                var hasSuperCall = false;
                for (expr in field.expr.expr) {
                    if (expr.expr == ECall(EField(EConst(CIdent("this")), "super"), _)) {
                        hasSuperCall = true;
                        break;
                    }
                }
                if (!hasSuperCall) {
                    Context.error("Method '" + field.name + "' must call 'super' or use 'superCall'!", field.pos);
                }
            }
        }
        return macro {};
    }
}
