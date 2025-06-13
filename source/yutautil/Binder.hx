package yutautil;

import haxe.macro.Context;
import haxe.macro.Expr;

class Binder {
    /**
     * Macro to auto-bind a Haxe class to a C/C++ class.
     * Usage: @:autoBind("CClassName") class MyClass { ... }
     */
    public static macro function autoBind():Array<Field> {
        var pos = Context.currentPos();
        var cls = Context.getLocalClass().get();
        var meta = cls.meta.extract(":autoBind");
        if (meta.length == 0) {
            Context.error("Missing @:autoBind metadata", pos);
        }
        var cppClassName = meta[0].params[0].getString();
        var fields = Context.getBuildFields();

        // Generate extern class for C/C++ binding
        var externFields:Array<Field> = [];
        for (field in fields) {
            switch (field.kind) {
                case FFun(f):
                    externFields.push({
                        name: field.name,
                        kind: FFun({
                            args: f.args,
                            expr: null,
                            ret: f.ret
                        }),
                        pos: field.pos,
                        access: [APublic, AExtern]
                    });
                case FVar(t, _):
                    externFields.push({
                        name: field.name,
                        kind: FVar(t, null),
                        pos: field.pos,
                        access: [APublic, AExtern]
                    });
                default:
            }
        }

        var externClass = {
            pack: cls.pack,
            name: cppClassName,
            pos: pos,
            kind: TDClass(),
            fields: externFields,
            meta: [{name: ":extern", params: [], pos: pos}]
        };

        Context.defineType(externClass);

        // Optionally, generate binding code here (e.g., cpp.Native calls)
        // For now, just return the original fields
        return fields;
    }
}