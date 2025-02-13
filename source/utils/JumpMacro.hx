package backend.util;

import haxe.macro.Context;
import haxe.macro.Expr;

class JumpMacro {
    public static macro function jumpTo(label:Expr):Expr {
        return macro untyped __cpp__('goto ' + $label);
    }

    public static macro function jumpToIf(label:Expr, condition:Expr):Expr {
        return macro if ($condition) untyped __cpp__('goto ' + $label);
    }

    public static macro function jumpToIfNot(label:Expr, condition:Expr):Expr {
        return macro if (!$condition) untyped __cpp__('goto ' + $label);
    }

    public static macro function addLabel(label:Expr):Expr {
        return macro untyped __cpp__($label + ':');
    }
}

class JumpHack {
    public static inline function jumpTo(label:String) {
        JumpMacro.jumpTo(macro $v{label});
    }

    public static inline function jumpToIf(label:String, condition:Bool) {
        JumpMacro.jumpToIf(macro $v{label}, macro $v{condition});
    }

    public static inline function jumpToIfNot(label:String, condition:Bool) {
        JumpMacro.jumpToIfNot(macro $v{label}, macro $v{condition});
    }

    public static inline function addLabel(label:String) {
        JumpMacro.addLabel(macro $v{label});
    }
}