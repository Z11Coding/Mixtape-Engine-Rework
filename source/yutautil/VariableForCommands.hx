package yutautil;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.TypeTools;

class VariableForCommands {
    public static macro function generateVariableMap(traceFields:Bool = false):Expr {
        var classes = Context.getBuildFields();
        var fieldExprs = [];
        trace(classes);
        trace("Preprocessing classes for variable map generation...");

        for (cls in classes) {
            var fields = Context.getFields(cls);
            for (field in fields) {
                var fieldType = TypeTools.toString(field.type);
                var fieldName = field.name;
                var className = TypeTools.toString(cls);
                
                if (traceFields) {
                    trace("Processing field: " + className + "." + fieldName + " of type " + fieldType);
                }
                
                fieldExprs.push(macro {
                    this.variables.set($v{className + "." + fieldName}, {type: $v{fieldType}, reference: Reflect.field($v{className}, $v{fieldName})});
                });
            }
        }

        trace("Variable map generation complete.");

        return macro {
            $a{fieldExprs}
        };
    }
}