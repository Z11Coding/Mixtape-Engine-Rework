package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

typedef AnyOf = Dynamic;

class AnyOfMacro {
    macro static public function build():Void {
        Context.onTypeCheck(function(_) {
            var fields = Context.getBuildFields();
            for (field in fields) {
                if (field.type != null && isAnyOf(field.type)) {
                    field.type = macro Dynamic;
                }
                if (field.expr != null) {
                    validateAssignments(field.expr, field.type);
                }
            }
            Context.addBuildFields(fields);
        });
    }

    static private function isAnyOf(type:Expr):Bool {
        return switch (type) {
            case { expr: EType(typeName, _) } if typeName == "AnyOf":
                true;
            default:
                false;
        }
    }

    static private function validateAssignments(expr:Expr, expectedType:Expr):Void {
        switch (expr) {
            case { expr: EBinop(OpAssign, { expr: EVar(v) }, value) }:
                if (isAnyOf(expectedType)) {
                    validateValue(value, expectedType);
                }
            case { expr: EFunction(_, body) }:
                for (statement in body) {
                    validateAssignments(statement, expectedType);
                }
            default:
                // Handle other cases as needed
        }
    }

    static private function validateValue(value:Expr, expectedType:Expr):Void {
        // Add logic to validate the value against the allowed types in AnyOf
        // This can involve checking the type of the value against the allowed types
    }
}
