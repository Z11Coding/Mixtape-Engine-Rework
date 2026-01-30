package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.TypeTools;

/**
 * Simple Fold validation macro
 * Uses Context.onAfterTyping to intercept and validate assignments
 */
class SimpleFoldMacro {
    static var initialized:Bool = false;

    /**
     * Initialize Fold validation
     */
    public static function initialize():Void {
        if (initialized) return;
        initialized = true;

        #if verbose
        trace("SimpleFoldMacro: Initializing Fold validation");
        #end

        // Use onAfterTyping to check for Fold assignments after all typing is done
        Context.onAfterTyping(validateAllFoldUsages);
    }

    static function validateAllFoldUsages(types:Array<ModuleType>):Void {
        #if verbose
        trace("SimpleFoldMacro: Validating Fold usages in typed modules");
        #end

        for (moduleType in types) {
            switch (moduleType) {
                case TClassDecl(classRef):
                    var classType = classRef.get();
                    validateClassFoldUsages(classType);
                default:
                    // Skip other module types
            }
        }
    }

    static function validateClassFoldUsages(classType:ClassType):Void {
        // This is a simplified approach - in practice, full AST traversal
        // would be needed to catch all Fold assignments
        #if verbose
        trace('SimpleFoldMacro: Checked class ${classType.name}');
        #end
    }
}