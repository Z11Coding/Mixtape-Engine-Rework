package yutautil;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.Constraints.IMap;



class FieldMap {
    var ref:Dynamic;
    var fields:Array<FieldAccess>;
    var isClass:Bool = false;

    public function new(obj:Dynamic) {
        this.ref = obj;
        this.fields = buildFields();
    }

    function buildFields():Array<FieldAccess> {
        if (ref == null) return [];
        if (Std.isOfType(ref, Array)) {
            var arr:Array<Dynamic> = cast ref;
            return [for (i in 0...arr.length) new ArrayField(ref, i, arr[i])];
        } else if (Std.isOfType(ref, StringMap) || Std.isOfType(ref, IntMap) || Std.isOfType(ref, IMap)) {
            var map:IMap<Dynamic, Dynamic> = cast ref;
            var fields:Array<FieldAccess> = [];
            for (k in map.keys()) {
                fields.push(new MapField(ref, k, map.get(k)));
            }
            return fields;
        } else if (Type.getClass(ref) != null) {
            this.isClass = true;
            var cls = Type.getClass(ref);
            var instanceFields = Type.getInstanceFields(cls);
            var privFields = getPrivateFields(cls, instanceFields);
            var fields:Array<FieldAccess> = [];
            for (f in instanceFields) {
                if (!privFields.contains(f)) {
                    fields.push(new InstanceField(ref, f, Reflect.field(ref, f)));
                }
            }
            for (f in privFields) {
                fields.push(new PrivateField(ref, f, Reflect.field(ref, f)));
            }
            return convertMethodsInPlace.funcAndReturn(fields);
        } else {
            var fields:Array<FieldAccess> = [];
            for (f in Reflect.fields(ref)) {
                fields.push(new StaticField(ref, f, Reflect.field(ref, f)));
            }
            return convertMethodsInPlace.funcAndReturn(fields);
        }
    }
    static function getPrivateFields(cls:Class<Dynamic>, instanceFields:Array<String>):Array<String> {
        var privFields = [];
        @:privateAccess
        {
            var fields = Reflect.fields(cls).concat(Type.getInstanceFields(cls));
            for (f in fields) {
                if (!instanceFields.contains(f)) {
                    privFields.push(f);
                }
            }
        }
        return privFields;
    }

    public function getFields():Array<FieldAccess> {
        if (ref == null) {
            // All fields become DeadField
            return [for (f in fields) new DeadField(f.name, f.value)];
        }
        // Rebuild fields to stay up-to-date
        this.fields = buildFields();
        return fields;
    }

    public function getRef():Dynamic return ref;
    public function setRef(obj:Dynamic):Void {
        this.ref = obj;
        this.fields = buildFields();
    }

    /**
     * Iterates over all fields and replaces any callable value with the appropriate Method variant.
     * This acts similarly to forEach, but mutates the fields array in-place.
     */
    public function convertMethodsInPlace():Void {
        for (i in 0...fields.length) {
            var field = fields[i];
            var val = field.value;
            if (Reflect.isFunction(val)) {
                // Replace with appropriate Method variant
                if (field is StaticField && !(field is StaticMethod)) {
                    fields[i] = new StaticMethod(field.ref, field.name, val);
                } else if (field is StaticPrivateField && !(field is StaticPrivateMethod)) {
                    fields[i] = new StaticPrivateMethod(field.ref, field.name, val);
                } else if (field is InstanceField && !(field is InstanceMethod)) {
                    fields[i] = new InstanceMethod(field.ref, field.name, val);
                } else if (field is PrivateField && !(field is PrivateMethod)) {
                    fields[i] = new PrivateMethod(field.ref, field.name, val);
                } else if (field is MapField) {
                    // Optionally, you could define a MapMethod if needed
                    // For now, leave as MapField
                } else if (field is ArrayField) {
                    // Optionally, you could define an ArrayMethod if needed
                    // For now, leave as ArrayField
                } else if (field is DeadField && !(field is DeadMethod)) {
                    fields[i] = new DeadMethod(field.name, val);
                }
            }
        }
    }
}

class FieldAccess {
    public var name(default, null):String;
    public var value(get, never):Dynamic;
    public var ref(default, null):Dynamic;

    public function new(ref:Dynamic, name:String, value:Dynamic) {
        this.ref = ref;
        this.name = name;
        this._value = value;
    }

    var _value:Dynamic;
    function get_value():Dynamic return _value;
}

class StaticField extends FieldAccess {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class StaticMethod extends StaticField {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class StaticPrivateField extends FieldAccess {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class StaticPrivateMethod extends StaticPrivateField {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class InstanceField extends FieldAccess {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class InstanceMethod extends InstanceField {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class PrivateField extends FieldAccess {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class PrivateMethod extends PrivateField {
    public function new(ref:Dynamic, name:String, value:Dynamic) {
        super(ref, name, value);
    }
}

class MapField extends FieldAccess {
    public function new(ref:Dynamic, key:Dynamic, value:Dynamic) {
        super(ref, Std.string(key), value);
    }
}

class ArrayField extends FieldAccess {
    public function new(ref:Dynamic, index:Int, value:Dynamic) {
        super(ref, Std.string(index), value);
    }
}

class DeadField extends FieldAccess {
    public function new(name:String, value:Dynamic) {
        super(null, name, value);
    }
}

class DeadMethod extends DeadField {
    public function new(name:String, value:Dynamic) {
        value = function() {
            throw 'Method $name is dead and cannot be called.';
        };
        super(name, value);
    }
}

abstract FieldOwner(Dynamic) from Dynamic to Dynamic {
    public inline function new(value:Dynamic) {
        this = value;
    }
}

abstract Fields(FieldMap) from FieldMap to FieldMap {
    public inline function new(value:FieldMap) {
        "this is a special object that allows you to access fields of an object dynamically, similar to a map, but with type safety and reflection capabilities.".NativeComment();
        this = value;
    }

    @:from
    public static function fromDynamic(value:Dynamic):Fields {
        return new FieldMap(value);
    }

    @:to
    public function owner():FieldOwner {
        @:privateAccess
        return new FieldOwner(this.ref);
    }

    @:to
    public function toFieldMap():FieldMap {
                @:privateAccess
        return new FieldMap(this.ref);
    }

    @:to
    public function toDynamic():Dynamic {
        "If not specified, returns the underlying reference object.".NativeComment();
                @:privateAccess
        return this.ref;
    }

    @:arrayAccess
    public function get(thing:String):Dynamic {
                @:privateAccess
        for (field in this.fields) {
            if (field.name == thing) {
                return field.value;
            }
        }
                @:privateAccess
        if (!this.isClass) {
            return null;
        }
        throw 'Field $thing not found in Fields.';
    }

    @:arrayAccess
    public function set(thing:String, value:Dynamic):Void {
        // Check if the field exists
        var exists = false;
                @:privateAccess
        for (field in this.fields) {
            if (field.name == thing) {
                exists = true;
                break;
            }
        }
                @:privateAccess
        if (!exists && this.isClass) {
            throw 'Field $thing does not exist in Fields.';
        }
        // Set the value in the underlying reference
                @:privateAccess
        if (this.ref != null) {
            Reflect.setField(this.ref, thing, value);
            // Rebuild fields to reflect the change
            this.fields = this.buildFields();
            return;
        }
        // If ref is null, kill the fields, by updating. this will make them DeadFields
                @:privateAccess
        this.fields = this.buildFields(); // Rebuild to update state
        return;
    }
}