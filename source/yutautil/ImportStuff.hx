import haxe.macro.Expr;
import haxe.macro.Context;

class ImportMacro {
    public static macro function injectImports():Array<Field> {
        var fields = Context.getBuildFields();
        for (field in fields) {
            if (field.meta.has(":import")) {
                var imports = field.meta.get(":import").params;
                for (imp in imports) {
                    var importExpr = macro import $v{imp};
                    Context.addGlobalMetadata(importExpr);
                }
            }
        }
        return fields;
    }
}