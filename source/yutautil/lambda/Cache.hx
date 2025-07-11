package yutautil.lambda;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.ds.StringMap;

using haxe.macro.Tools;

class Cache {
    // Runtime cache storage: Map<FunctionKey, Map<ArgsKey, Value>>
    static var _caches:StringMap<Dynamic> = new StringMap();

    // Macro entry point
    public static macro function build():Array<Field> {
        var fields = Context.getBuildFields();
        for (field in fields) {
            if (field.meta != null) {
                for (meta in field.meta) {
                    if (meta.name == ":cache") {
                        field = injectCache(field);
                    }
                }
            }
        }
        return fields;
    }

    // Injects caching logic into the function
    static function injectCache(field:Field):Field {
        switch (field.kind) {
            case FFun(f):
                var funcName = field.name;
                var argNames = [for (a in f.args) a.name];
                var keyExprs = [macro $i{n} for (n in argNames)];
                var funcKey = '${Context.getLocalClass().get().name}.${funcName}';

                // Generate code to create a unique key for arguments
                var argsKeyExpr = macro {
                    var _argsKey = "";
                    if (${keyExprs.length} > 0) {
                        _argsKey = [for (a in [${keyExprs}]) Std.string(a)].join(":");
                    }
                    _argsKey;
                };

                // Injected body
                var newBody = macro {
                    var _funcKey = $v{funcKey};
                    var _cache:Map<String, Dynamic> = yutautil.lambda.Cache.getCache(_funcKey);
                    var _argsKey = [for (a in [${keyExprs}]) Std.string(a)].join(":");
                    if (_cache.exists(_argsKey)) {
                        return _cache.get(_argsKey);
                    }
                    var _result = ${f.expr};
                    _cache.set(_argsKey, _result);
                    return _result;
                };

                // Replace function body
                f.expr = newBody;
                field.kind = FFun(f);
                return field;
            default:
                Context.error('Cache can only be applied to functions. Cannot apply to ${field.kind}', field.pos);
                return field; // Should not reach here, but just in case
        }
    }

    // Runtime: Get cache for a function
    public static function getCache(funcKey:String):Map<String, Dynamic> {
        if (!_caches.exists(funcKey)) {
            _caches.set(funcKey, new Map());
        }
        return cast _caches.get(funcKey);
    }

    // Runtime: Clear cache for a function
    public static function clearCache(funcKey:String):Void {
        _caches.remove(funcKey);
    }

    // Runtime: Get info about a cache
    public static function cacheInfo(funcKey:String):{size:Int, keys:Array<String>} {
        var cache = getCache(funcKey);
        return {
            size: cache.keys().length,
            keys: [for (k in cache.keys()) k]
        };
    }
}