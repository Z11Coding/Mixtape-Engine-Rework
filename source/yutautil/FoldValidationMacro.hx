package yutautil;

import haxe.macro.Compiler;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

using haxe.macro.ExprTools;

/**
 * Global macro for Fold type validation
 * Intercepts type checking to validate Fold assignments
 */
class FoldValidationMacro {
    static var initialized:Bool = false;
    static var tracesEnabled:Bool = #if verbose true #else false #end;

    /**
     * Initialize global Fold validation
     * This is called from Project.xml using --macro
     */
    public static function initialize():Void {
        if (initialized) return;
        initialized = true;

        if (tracesEnabled) trace("FoldValidationMacro: Initializing global Fold validation");

        // Apply build macro to all classes to intercept their assignments
        Compiler.addGlobalMetadata(
            "", // Apply to all types
            "@:autoBuild(yutautil.FoldValidationMacro.validateFoldAssignments())",
            true // Recursive
        );

        if (tracesEnabled) trace("FoldValidationMacro: Applied Fold validation globally");
    }

    /**
     * Build macro that intercepts and validates Fold assignments in each class
     */
    public static function validateFoldAssignments():Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass().get();
        
        if (tracesEnabled) trace('FoldValidationMacro: Processing class ${localClass.name}');

        // Transform each function to intercept Fold assignments
        for (field in fields) {
            if (field.kind.match(FFun(_))) {
                transformFunction(field);
            }
        }

        return fields;
    }

    static function transformFunction(field:Field):Void {
        switch (field.kind) {
            case FFun(func):
                if (func.expr != null) {
                    func.expr = transformExpression(func.expr);
                }
            default:
                // Not a function, skip
        }
    }

    static function transformExpression(expr:Expr):Expr {
        return switch (expr.expr) {
            // Intercept variable declarations with assignments
            case EVars(vars):
                for (v in vars) {
                    if (v.expr != null) {
                        validateFoldAssignment(v.type, v.expr);
                    }
                }
                expr;

            // Intercept regular assignments
            case EBinop(OpAssign, left, right):
                // Get the type of the left side and validate
                try {
                    var leftType = Context.typeof(left);
                    validateFoldAssignmentFromType(leftType, right);
                } catch (e:Dynamic) {
                    // Type checking failed, let normal compiler handle it
                }
                expr;

            // Recursively transform sub-expressions
            default:
                expr.map(transformExpression);
        }
    }

    static function validateFoldAssignment(typeHint:Null<ComplexType>, valueExpr:Expr):Void {
        if (typeHint == null) return;
        
        // Check if the type hint is a Fold type
        var typeString = haxe.macro.ComplexTypeTools.toString(typeHint);
        if (typeString.indexOf("yutautil.Fold<") == 0 || typeString.indexOf("Fold<") == 0) {
            if (tracesEnabled) trace('FoldValidationMacro: Found Fold assignment: $typeString');
            
            // Extract the constraint type parameter
            var constraintType = extractFoldConstraintType(typeHint);
            if (constraintType != null) {
                validateStructuralConstraint(constraintType, valueExpr);
            }
        }
    }

    static function validateFoldAssignmentFromType(leftType:Type, valueExpr:Expr):Void {
        // Check if the left type is a Fold type
        var typeString = TypeTools.toString(leftType);
        if (typeString.indexOf("yutautil.Fold<") == 0 || typeString.indexOf("Fold<") == 0) {
            if (tracesEnabled) trace('FoldValidationMacro: Found Fold assignment from type: $typeString');
            
            // Extract constraint from the actual type
            var constraintType = extractFoldConstraintFromType(leftType);
            if (constraintType != null) {
                validateStructuralConstraintFromType(constraintType, valueExpr);
            }
        }
    }

    static function extractFoldConstraintType(complexType:ComplexType):Null<ComplexType> {
        return switch (complexType) {
            case TPath(path):
                if (path.params != null && path.params.length > 0) {
                    switch (path.params[0]) {
                        case TPType(t): t;
                        default: null;
                    }
                } else null;
            default: null;
        }
    }

    static function extractFoldConstraintFromType(type:Type):Null<Type> {
        return switch (type) {
            case TAbstract(_.get() => ab, params):
                if (ab.name == "Fold" && params.length > 0) {
                    params[0];
                } else null;
            default: null;
        }
    }

    static function validateStructuralConstraint(constraintType:ComplexType, valueExpr:Expr):Void {
        try {
            // Convert ComplexType to Type for analysis
            var constraintActualType = haxe.macro.ComplexTypeTools.toType(constraintType);
            validateStructuralConstraintFromType(constraintActualType, valueExpr);
        } catch (e:Dynamic) {
            if (tracesEnabled) trace('FoldValidationMacro: Could not convert constraint type: $e');
        }
    }

    static function validateStructuralConstraintFromType(constraintType:Type, valueExpr:Expr):Void {
        // Get the fields required by the constraint
        var requiredFields = getTypeFields(constraintType);
        
        if (requiredFields.length == 0) return; // No validation needed
        
        // Get the fields provided by the value expression
        var providedFields = getExpressionFields(valueExpr);
        
        if (providedFields == null) {
            // Cannot determine structure at compile time, let runtime handle it
            return;
        }
        
        // Check that all required fields are present
        for (requiredField in requiredFields) {
            var found = false;
            for (providedField in providedFields) {
                if (providedField.name == requiredField.name) {
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                Context.error(
                    'Fold validation error: Missing required field "${requiredField.name}" of type ${TypeTools.toString(requiredField.type)}',
                    valueExpr.pos
                );
            }
        }
        
        if (tracesEnabled) trace('FoldValidationMacro: Validated Fold assignment - all required fields present');
    }

    static function getTypeFields(type:Type):Array<{name:String, type:Type}> {
        return switch (type) {
            case TAnonymous(_.get() => anon):
                anon.fields.map(field -> {
                    name: field.name,
                    type: field.type
                });
            default: [];
        }
    }

    static function getExpressionFields(expr:Expr):Null<Array<{name:String, expr:Expr}>> {
        return switch (expr.expr) {
            case EObjectDecl(fields):
                fields.map(field -> {
                    name: field.field,
                    expr: field.expr
                });
            default: null; // Cannot determine structure at compile time
        }
    }
}