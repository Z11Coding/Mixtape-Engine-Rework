package backend;

class DynamicIterator2<T> {
    var current:Int = 0;
    var dynamicValue:Dynamic;
    var keys:Array<String>;
    var isArray:Bool;
    var isMap:Bool;
    var isObject:Bool;

    public inline function new(value:Dynamic) {
        this.dynamicValue = value;
        this.isArray = Std.is(value, Array);
        this.isMap = Std.is(value, Map);
        this.isObject = !isArray && !isMap && Std.is(value, Dynamic);
        if (isObject) {
            if (Type.getClass(value) != null) {
            this.keys = Type.getInstanceFields(Type.getClass(value));
            } else {
            this.keys = Reflect.fields(value);
            }
        }
    }

    public inline function hasNext():Bool {
        if (isArray) {
            return current < dynamicValue.length;
        } else if (isMap) {
            return current < dynamicValue.keys().length;
        } else if (isObject) {
            return current < keys.length;
        }
        return false;
    }

    public inline function next():Dynamic {
        if (isArray) {
            return dynamicValue[current++];
        } else if (isMap) {
            var key = dynamicValue.keys()[current];
            return {key: key, value: dynamicValue.get(key)};
        } else if (isObject) {
            var key = keys[current];
            return {key: key, value: Reflect.field(dynamicValue, key)};
        }
        return null;
    }

    public static function mapping(obj:Dynamic):Map<String, Dynamic> {
        var map = new Map<String, Dynamic>();
        var fields = Reflect.fields(obj);
        for (field in fields) {
            map.set(field, Reflect.field(obj, field));
        }
        return map;
    }

    public static function values(obj:Dynamic):Array<Dynamic> {
        var values = [];
        var fields = Reflect.fields(obj);
        for (field in fields) {
            values.push(Reflect.field(obj, field));
        }
        return values;
    }
}