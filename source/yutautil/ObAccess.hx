package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class ObAccess {
    /**
     * Usage:
     * var obj = ObAccess.withIt(MyClass, { foo: 1 }, it -> {
     *     it.bar = 2;
     * });
     */
    macro public static function withIt(type:Expr, ctorArgs:Expr, fn:Expr):Expr {
        // Generate a unique variable name
        var itName = Context.freshLocal("it");
        // Build: var it = new type ctorArgs; fn(it); it;
        return macro {
            var $itName = new $type $ctorArgs;
            $fn($itName);
            $itName;
        }
    }
}