package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Printer;

class RuntimeTypedef {
    public static macro function processTypedef():Array<Field> {
        var fields = Context.getBuildFields();
        Context.onAfterTyping(function(_modules:Array<haxe.macro.ModuleType>) {
            var pos = Context.currentPos();
            var typedefE = Context.getLocalType();

            switch (typedefE) {
                case TType(t, params):
                    var tdef = t.get();
                    var meta = tdef.meta.get();
                    var hasMeta = false;
                    for (m in meta) {
                        if (m.name == ":runtime" || m.name == ":typed") {
                            hasMeta = true;
                            break;
                        }
                    }
                    if (hasMeta) {
                        // Generate abstract using a simplified approach
                        var absName = tdef.name;
                        var absType = haxe.macro.TypeTools.toComplexType(TType(t, params));
                        
                        // Create a type alias instead of a complex abstract to avoid type conversion issues
                        var aliasTypeDef:TypeDefinition = {
                            pos: pos,
                            name: absName,
                            pack: tdef.pack,
                            params: null,
                            meta: null,
                            kind: TDAlias(absType),
                            fields: [],
                            doc: null
                        };
                        Context.defineType(aliasTypeDef);

                        // Trace how to access the new abstract
                        var fullName = (tdef.pack.length > 0 ? tdef.pack.join(".") + "." : "") + absName;
                        Context.warning('Type alias "$fullName" generated. You can access it as $fullName in your code.', pos);
                    }
                default:
                    // Not a typedef, do nothing
            }
        });
        return fields;
    }
}
