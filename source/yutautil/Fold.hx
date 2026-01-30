package yutautil;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;
using haxe.macro.Tools;
using haxe.macro.TypeTools;
#end

/**
 * Fold<T> - Structural typing constraint
 * 
 * A Fold type ensures that assigned values contain AT LEAST the fields defined in T.
 * Extra fields are allowed, making this a "structural supertype" constraint.
 * 
 * Example:
 * ```haxe
 * var person: Fold<{name:String, age:Int}> = {
 *     name: "John",
 *     age: 30,
 *     extraField: "This is allowed"  // Extra fields OK
 * };
 * ```
 */
@:forward
abstract Fold<T>(T) {
    /**
     * Implicit conversion that validates structure at compile-time
     */
    @:from public static macro function fromAny<T>(value:haxe.macro.Expr):haxe.macro.Expr {
        try {
            // Get the expected type context
            var expectedType = Context.getExpectedType();
            
            if (expectedType == null) {
                // No validation possible, return as-is
                return value;
            }

            // Check if this is a Fold assignment
            var constraintType = extractFoldConstraintType(expectedType);
            if (constraintType == null) {
                // Not a Fold type, return as-is
                return value;
            }

            // Validate the structure - check that required fields are present
            validateStructure(value, constraintType);
            
            // Return the original value - let Haxe handle the implicit conversion
            return value;
        } catch (e:Dynamic) {
            Context.error('Fold validation error: $e', value.pos);
            return value;
        }
    }

    static function extractFoldConstraintType(type:Type):Null<Type> {
        return switch (type.follow()) {
            case TAbstract(_.get() => ab, params):
                if (ab.name == "Fold" && ab.pack.join(".") == "yutautil" && params.length > 0) {
                    params[0];
                } else null;
            default: null;
        }
    }

#if macro
    static function validateStructure(value:Expr, constraintType:Type):Void {
        // Get required fields from constraint type
        var requiredFields = getRequiredFields(constraintType);
        
        if (requiredFields.length == 0) return; // No validation needed

        // Only validate object literals - other expressions can't be validated at compile time
        switch (value.expr) {
            case EObjectDecl(fields):
                // Check that all REQUIRED fields are present
                // Don't error on extra fields - they're allowed in a Fold
                for (requiredField in requiredFields) {
                    var found = false;
                    for (field in fields) {
                        if (field.field == requiredField.name) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        throw 'Missing required field "${requiredField.name}"';
                    }
                }
                
                #if verbose
                trace('Fold validation passed: all required fields present, extra fields allowed');
                #end
                
            default:
                // Can't validate non-object-literal expressions at compile time
                #if verbose
                trace('Fold validation skipped: non-literal expression');
                #end
        }
    }

    static function getRequiredFields(type:Type):Array<{name:String, type:Type}> {
        return switch (type.follow()) {
            case TAnonymous(_.get() => anon):
                anon.fields.map(field -> {
                    name: field.name,
                    type: field.type
                });
            default: [];
        }
    }
#end

    @:to public inline function toUnderlying():T {
        return this;
    }
}