package undertale;

import haxe.macro.Expr;

class NullFloat {
    public static function replaceNullChecks(expr:Expr):Expr {
        return switch (expr.expr) {
            case EIf(cond, eif, eelse):
                var newCond = replaceNullCheckInCondition(cond);
                var newEif = replaceNullChecks(eif);
                var newEelse = eelse != null ? replaceNullChecks(eelse) : null;
                macro if ($newCond) $newEif else $newEelse;
            case _:
                expr.map(replaceNullChecks)
        }
    }

    static function replaceNullCheckInCondition(cond:Expr):Expr {
        return switch (cond.expr) {
            case EBinop(OpEq, left, right):
                if (isNonNullableType(left) && isNullLiteral(right)) {
                    macro $left == -1;
                } else if (isNonNullableType(right) && isNullLiteral(left)) {
                    macro $right == -1;
                } else {
                    cond;
                }
            case _:
                cond;
        }
    }

    static function isNonNullableType(expr:Expr):Bool {
        switch (expr.expr) {
            case EField(_, _):
                var t = Context.typeof(expr);
                return switch (t) {
                    case TAbstract({ name: "Int" }, _):
                        true;
                    case TAbstract({ name: "Float" }, _):
                        true;
                    case _:
                        false;
                }
            case _:
                false;
        }
    }

    static function isNullLiteral(expr:Expr):Bool {
        return switch (expr.expr) {
            case EConst(CIdent("null")):
                true;
            case _:
                false;
        }
    }
}