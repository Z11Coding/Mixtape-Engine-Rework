package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class JavaLoop {
    public static macro function transformJavaLoops(expr:Expr):Expr {
        return switch (expr) {
            case macro for ($v in $it) $body:
                // This is already a Haxe-compatible for loop, no transformation needed
                expr;
            case macro for ($v: $t in $it) $body:
                // This is already a Haxe-compatible for loop with type, no transformation needed
                expr;
            case macro for ($v = $start; $cond; $inc) $body:
                // Transform Java-style for loop to Haxe-compatible for loop
                var init = $v;
                var condition = $cond;
                var increment = $inc;
                var loopBody = $body;
                macro {
                    {
                        $init;
                        while ($condition) {
                            $loopBody;
                            $increment;
                        }
                    }
                };
            case _:
                // Recursively transform sub-expressions
                Context.mapExpr(transformJavaLoops, expr);
        }
    }
}

