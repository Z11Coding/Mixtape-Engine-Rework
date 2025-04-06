package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

// Work in progress, this will allow handling certain things at compile time
// and also allow for compile time only functions to be used in the game.

class CompileScript {
    public static macro function specialCompileOperation(expr:Expr):Expr {
        try {
            var result = Context.typeExpr(expr);
            return Context.makeExpr(result, Context.currentPos());
        } catch (e:Dynamic) {
            Context.error("This operation cannot be done during compile time: " + e, Context.currentPos());
            return macro null;
        }
    }

    public static macro function compileOnlyFunction(expr:Expr):Expr {
        var args = Context.getBuildFields();
        if (args.exists("-livereload")) {
            return expr;
        } else {
            Context.warning("This operation is skipped because '-livereload' is not present.", Context.currentPos());
            return macro null;
        }
    }

    public static macro function globalCompileFunction(stateClass:Expr, expr:Expr):Expr {
        return macro {
            if (Std.is(FlxG.state, $stateClass)) {
                $expr;
            }
        };
    }
}