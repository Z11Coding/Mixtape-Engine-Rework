package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

class TypeChecker {
    public static macro function checkTypedef(expr:Expr):Expr {
        var t:Type = Context.typeof(expr);
        trace(t);
        typingContext = Context.follow(t, false)
        return macro $v{expr};
    }
}