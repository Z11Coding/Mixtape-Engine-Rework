package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

#if macro
class DynamicAbstract {
    /**
     * This macro injects dynamic access handling into abstracts.
     * Usage: @dynamicAccess on a function inside an abstract.
     * Any unknown field access or call will be redirected to the marked function.
     */
    public static function build():Array<Field> {
        var fields = Context.getBuildFields();
        var pos = Context.currentPos();

        // Find the function with @dynamicAccess
        var handlerName:String = null;
        var handlerType:String = null; // "get", "call", "access"
        for (field in fields) {
            if (field.meta != null) {
                for (meta in field.meta) {
                    if (meta.name == ":dynamicAccess") {
                        handlerName = field.name;
                        // Determine handler type by function signature
                        switch (field.kind) {
                            case FFun(f):
                                if (f.args.length == 1) handlerType = "get";
                                else if (f.args.length == 2) handlerType = "call";
                                else handlerType = "access";
                            default:
                        }
                    }
                }
            }
        }

        if (handlerName == null) {
            // No handler found, do nothing
            return fields;
        }

        // Inject __getField and __callField to redirect to the handler
        // (Haxe uses __getField and __callField for dynamic access)
        if (!fields.exists(f -> f.name == "__getField")) {
            fields.push({
                name: "__getField",
                access: [APublic],
                kind: FFun({
                    args: [{name: "field", type: macro:String}],
                    ret: macro:Dynamic,
                    expr: switch (handlerType) {
                        case "get":
                            macro return this.$handlerName(field);
                        case "access":
                            macro return this.$handlerName(field, []);
                        case "call":
                            macro throw "Dynamic call handler requires arguments array.";
                        default:
                            macro throw "No dynamic access handler found.";
                    }
                }),
                pos: pos,
                doc: "Handles dynamic field access via @dynamicAccess."
            });
        }

        if (!fields.exists(f -> f.name == "__callField")) {
            fields.push({
                name: "__callField",
                access: [APublic],
                kind: FFun({
                    args: [
                        {name: "field", type: macro:String},
                        {name: "args", type: macro:Array<Dynamic>}
                    ],
                    ret: macro:Dynamic,
                    expr: switch (handlerType) {
                        case "call":
                            macro return this.$handlerName(field, args);
                        case "access":
                            macro return this.$handlerName(field, args);
                        case "get":
                            macro throw "Dynamic get handler does not support call.";
                        default:
                            macro throw "No dynamic access handler found.";
                    }
                }),
                pos: pos,
                doc: "Handles dynamic method calls via @dynamicAccess."
            });
        }

        return fields;
    }
}
#end