package yutautil;

// import tink.CoreApi.Ref;
import haxe.ds.WeakMap;
import haxe.Timer;
// import haxe.macro.Context;
// import haxe.macro.Expr;

class MetaData {
    private static var metaMap:WeakMap<Dynamic, Dynamic> = new WeakMap();
    private static var cleanupTimer:Timer = new Timer(60000); // Cleanup every 60 seconds

    public static function init():Void {
        cleanupTimer.run = cleanup;
    }

    public static function metadata<T>(variable:T):Dynamic {
        if (!metaMap.exists(variable)) {
            var meta = {};
            metaMap.set(variable, meta);
            initializeMeta(variable, meta);
        }
        return metaMap.get(variable);
    }

    public static function addMeta<T>(variable:T, metaD:Dynamic):Void {
        if (!metaMap.exists(variable)) {
            var meta = {};
            metaMap.set(variable, meta);
            initializeMeta(variable, meta);
        }
        Reflect.setField(metaMap.get(variable), metaD, metaD);

    }

    public static function setMeta<T>(variable:T, key:String, value:Dynamic):Void {
        if (metaMap.exists(variable)) {
            var meta = metaMap.get(variable);
            Reflect.setField(meta, key, value);
        } else {
            throw "No metadata exists for the variable.";
        }
    }

    public static function remMeta<T>(variable:T):Void {
        if (metaMap.exists(variable)) {
            metaMap.remove(variable);
        }
    }

    private static function initializeMeta<T>(variable:T, meta:Dynamic):Void {

        function add(key:String, value:Dynamic):Void {
            Reflect.setField(meta, key, value);
        }

        switch (Type.typeof(variable)) {
            case TClass(c): // Maybe not recommended on giant classes or states...
                for (field in Type.getInstanceFields(c)) {
                    if (Reflect.isObject(Reflect.field(c, field))) {
                        for (stuff in Reflect.fields(Reflect.field(c, field))) {
                            metadata(Reflect.field(Reflect.field(c, field), stuff));
                        }
                    } 
                    else {
                        metadata(Reflect.field(c, field));
                    }
                }
                Reflect.setField(meta, "class", Type.getClassName(c));
                Reflect.setField(meta, "super", Type.getClassName(Type.getSuperClass(c)));
            case TInt:
                // Reflect.setField(meta, "e", Std.int(variable));

            case TFloat:
                Reflect.setField(meta, "int", Std.int(cast(variable, Float)));
            case TBool:
                Reflect.setField(meta, "binary", cast(variable, Bool) ? "1" : "0");
            // case TString:
            //     Reflect.setField(meta, "binary", StringTools.hex(Std.parseInt(variable)));

            case TFunction:
                Reflect.setField(meta, "call", function() {
                    if (Reflect.isFunction(variable)) {
                        (cast variable:Void->Void)();
                    }
                });
            default:
                // Handle other types if necessary

                if (variable is String) {
                    // Reflect.setField(meta, "base64", haxe.crypto.Base64.encode((cast variable : String));
                    Reflect.setField(meta, "char", (cast variable : String).split(""));
                }
                if (variable is Array) {
                    for (thing in cast(variable, Array<Dynamic>)) {
                        metadata(thing);
                    }
                }
                if (variable is haxe.Constraints.IMap) {
                    for (key in (cast variable:haxe.Constraints.IMap<Dynamic, Dynamic>).keys()) {
                        metadata(key);
                        metadata((cast variable:haxe.Constraints.IMap<Dynamic, Dynamic>).get(key));
                    }
                }
        }
    }

    private static function cleanup():Void {
        for (key in metaMap.keys()) {
            if (key == null) {
                metaMap.remove(key);
            }
        }
    }
}

// MetaData.init();