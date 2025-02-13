package yutautil;

import haxe.macro.Expr;
import haxe.macro.Context;

class JavaLoop {
    public static macro function javaLoop(expr:Expr):Expr {
        return switch (expr.expr) {
            case ECall(e, [loopExpr]):
                switch (e.expr) {
                    case EField(_, "javaLoop"):
                        return transformJavaLoop(loopExpr);
                    default:
                        expr;
                }
            default:
                expr;
        };
    }

    private static function transformJavaLoop(loopExpr:Expr):Expr {
        return switch (loopExpr.expr) {
            case EFor(varDecl, cond, incr, body):
                var init = varDecl;
                var condition = cond;
                var increment = incr;
                var loopBody = body;

                macro {
                    $init;
                    while ($condition) {
                        $loopBody;
                        $increment;
                    }
                };
            default:
                Context.error("Expected a for loop", loopExpr.pos);
        };
    }
}