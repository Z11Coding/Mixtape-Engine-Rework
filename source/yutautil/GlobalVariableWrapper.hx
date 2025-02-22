import haxe.macro.Context;
import haxe.macro.Expr;

class GlobalVariableWrapper {
    public static function wrapVariableAccesses():Void {
        Context.onAfterTyping(wrapExpressions);
    }

    static function wrapExpressions(types:Array<haxe.macro.Type>):Void {
        for (type in types) {
            switch type {
                case TClassDecl(c):
                    for (field in c.fields) {
                        switch field.kind {
                            case FVar(_, _), FProp(_, _, _, _):
                                // Skip variable declarations and properties
                            case FMethod(_, func):
                                field.expr = macro {
                                    var originalFunction = $v{func.expr};
                                    return function() {
                                        return $a{transformExpr(originalFunction)};
                                    };
                                };
                        }
                    }
                case _:
            }
        }
    }

    static function transformExpr(e:Expr):Expr {
        return switch e.expr {
            case EVar(v):
                macro HoldableVariable.createVariable($v{v});
            case EField(e, f):
                macro HoldableVariable.createVariable($e{e}.$f{f});
            case _:
                e; // Return the expression unchanged if it's not a variable access
        };
    }
}