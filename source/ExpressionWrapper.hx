package;

import haxe.macro.Context;
import haxe.macro.Expr;

    
    class ExpressionWrapper {
        public static macro function wrapExpressions():Void {
            Context.onGenerate(function(types) {
                for (type in types) {
                    switch type.kind {
                        case TClassDecl(c):
                            for (field in c.fields) {
                                switch field.kind {
                                    case FMethod(m):
                                        field.expr = switch field.expr {
                                            case null: null;
                                            case var expr: transform(expr);
                                        };
                                    case _:
                                }
                            }
                        case _:
                    }
                }
            });
        }

    static function transform(expr:Expr):Expr {
        switch expr.expr {
            case EVar(_):
                // Wrap variable access
                return wrapInFunction(expr);
            case EBinop(_, _, _):
                // Wrap binary operations (calculations)
                return wrapInFunction(expr);
            case ECall(_,_):
                // Optionally wrap function calls
                return wrapInFunction(expr);
            case _:
                // Recursively transform expressions
                return Context.transform(expr, transform);
        }
        return null; // Should never happen
    }

    static function wrapInFunction(expr:Expr):Expr {
        // Create a new function that returns the original expression
        return macro function() return $expr;
    }
}