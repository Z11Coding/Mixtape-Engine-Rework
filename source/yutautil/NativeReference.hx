package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class NativeReference {
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var posInfos = Context.getPosInfos(Context.currentPos());
        var className = Context.getLocalClass().get().name;

        // For each field, if it's a function, wrap its body to inject comments
        for (field in fields) {
            switch (field.kind) {
                case FFun(f):
                    if (f.expr != null) {
                        f.expr = injectComments(f.expr);
                    }
                default:
            }
        }
        return fields;
    }

    static function injectComments(expr:Expr):Expr {
        return switch (expr.expr) {
            case EBlock(exprs):
                // For each expression, prepend a comment with the original source
                var newExprs = [];
                for (e in exprs) {
                    var info = Context.getPosInfos(e.pos);
                    var src = Context.getSourceFile(e.pos);
                    var line = info.lineNumber;
                    var comment = "// " + Context.getTypedExpr(e).toString();
                    newExprs.push(macro $v{comment});
                    newExprs.push(e);
                }
                { expr: EBlock(newExprs), pos: expr.pos };
            default:
                expr;
        }
    }
}

@:build(yutautil.NativeReference.build())