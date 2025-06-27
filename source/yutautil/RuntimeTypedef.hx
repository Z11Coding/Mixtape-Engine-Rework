package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Printer;

class RuntimeTypedef {
    public static macro function processTypedef():Array<Field> {
        var fields = Context.getBuildFields();
        var pos = Context.currentPos();
        var typedefE = Context.getLocalType();

        trace('Fetched build fields.');
        trace('Build Fields: ' + fields);
        trace('Current position: ' + pos);
        trace('Current typedef expression: ' +(typedefE));

        switch (typedefE) {
            case TType(t, params):
                var tdef = t.get();
                trace('Processing typedef: ' + tdef.name);
                var meta = tdef.meta.get();
                var hasMeta = false;
                for (m in meta) {
                    trace('Found meta: ' + m.name);
                    if (m.name == ":runtime" || m.name == ":typed") {
                        hasMeta = true;
                        trace('Matched meta: ' + m.name);
                        break;
                    }
                }
                if (hasMeta) {
                    var absName = tdef.name;
                    var absType = haxe.macro.TypeTools.toComplexType(TType(t, params));
                    trace('Generating type alias for: ' + absName);

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

                    var fullName = (tdef.pack.length > 0 ? tdef.pack.join(".") + "." : "") + absName;
                    Context.warning('Type alias "$fullName" generated. You can access it as $fullName in your code.', pos);
                    trace('Type alias "' + fullName + '" defined.');
                } else {
                    trace('No relevant meta found, skipping.');
                }
            default:
                trace('Not a typedef, skipping.');
        }
        return fields;
    }
}
