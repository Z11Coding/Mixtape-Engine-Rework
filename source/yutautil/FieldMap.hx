package yutautil;

import haxe.ds.StringMap;
import haxe.ds.IntMap;
import haxe.Constraints.IMap;



class FieldMap {
    var ref:HaxePointer<Dynamic>;
    var fields:Array<FieldAccess>;
    var isClass:Bool = false;

    public function new(obj:Dynamic) {
        trace('[FieldMap] new() called with obj: $obj');
        this.ref = obj;
        trace('[FieldMap] ref initialized: $ref');
        trace('[FieldMap] FieldMap initialized...');
        this.fields = buildFields();
        trace('[FieldMap] Fields built: ${fields.length} fields found.');
    }

    function buildFields():Array<FieldAccess> {
        trace('[FieldMap] buildFields() called');
        if (ref == null) {
            trace('[FieldMap] buildFields: ref is null, returning empty array');
            return [];
        }
        if (Std.isOfType(ref, Array)) {
            trace('[FieldMap] buildFields: ref is Array');
            var arr:Array<Dynamic> = cast ref.forceCast();
            var arrFields = [for (i in 0...arr.length) new ArrayField(ref, i, arr[i])];
            trace('[FieldMap] buildFields: ArrayField count: ${arrFields.length}');
            return cast arrFields;
        } else if (Std.isOfType(ref, StringMap) || Std.isOfType(ref, IntMap) || Std.isOfType(ref, IMap)) {
            trace('[FieldMap] buildFields: ref is Map');
            var map:IMap<Dynamic, Dynamic> = cast ref.forceCast();
            var fields:Array<FieldAccess> = [];
            for (k in map.keys()) {
                fields.push(new MapField(ref, k, map.get(k)));
            }
            trace('[FieldMap] buildFields: MapField count: ${fields.length}');
            return fields;
        } else if (Type.getClass(ref) != null) {
            this.isClass = true;
            var cls = Type.getClass(ref.forceCast());
            trace('[FieldMap] buildFields: ref is Class instance of ${Type.getClassName(cls)}');
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
            trace('[FieldMap] buildFields: InstanceField count: ${fields.length}');
            return convertMethodsInPlace.funcAndReturn(fields);
        } else {
            trace('[FieldMap] buildFields: ref is generic object');
            var fields:Array<FieldAccess> = [];
            for (f in Reflect.fields(ref)) {
                fields.push(new StaticField(ref, f, Reflect.field(ref, f)));
            }
            trace('[FieldMap] buildFields: StaticField count: ${fields.length}');
            return convertMethodsInPlace.funcAndReturn(fields);
        }
    }

    static function getPrivateFields(cls:Class<Dynamic>, instanceFields:Array<String>):Array<String> {
        trace('[FieldMap] getPrivateFields() called for class: ${Type.getClassName(cls)}');
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
        trace('[FieldMap] getPrivateFields: found ${privFields.length} private fields');
        return privFields;
    }

    public function getFields():Array<{ type:String, name:String, value:Dynamic }> {
        trace('[FieldMap] getFields() called');
        if (ref == null) {
            trace('[FieldMap] getFields: ref is null, returning DeadFields');
            // All fields become DeadField
            return [for (f in fields) {
                type: Type.getClassName(Type.getClass(f)),
                name: f.name,
                value: f.value
            }];
        }
        trace('[FieldMap] getFields: returning ${fields.length} fields');
        return [for (f in fields) {
            type: Type.getClassName(Type.getClass(f)),
            name: f.name,
            value: f.value
        }];
    }

    public function getRef():Dynamic {
        trace('[FieldMap] getRef() called, returning ref');
        return ref;
    }

    public function setRef(obj:Dynamic):Void {
        trace('[FieldMap] setRef() called with obj: $obj');
        this.ref = obj;
        this.fields = buildFields();
        trace('[FieldMap] setRef: fields rebuilt, count: ${fields.length}');
    }

    /**
     * Iterates over all fields and replaces any callable value with the appropriate Method variant.
     * This acts similarly to forEach, but mutates the fields array in-place.
     */
    public function convertMethodsInPlace(fields:OneOrMany<FieldAccess>):Void {
        trace('[FieldMap] convertMethodsInPlace() called');
        for (i in 0...fields.lengthTo()) {
            var field = fields[i];
            var val = field.value;
            if (Reflect.isFunction(val)) {
                trace('[FieldMap] convertMethodsInPlace: field "${field.name}" is a function');
                // Replace with appropriate Method variant
                if (field is StaticField && !(field is StaticMethod)) {
                    trace('[FieldMap] convertMethodsInPlace: converting StaticField "${field.name}" to StaticMethod');
                    fields[i] = new StaticMethod(field.ref, field.name, val);
                } else if (field is StaticPrivateField && !(field is StaticPrivateMethod)) {
                    trace('[FieldMap] convertMethodsInPlace: converting StaticPrivateField "${field.name}" to StaticPrivateMethod');
                    fields[i] = new StaticPrivateMethod(field.ref, field.name, val);
                } else if (field is InstanceField && !(field is InstanceMethod)) {
                    trace('[FieldMap] convertMethodsInPlace: converting InstanceField "${field.name}" to InstanceMethod');
                    fields[i] = new InstanceMethod(field.ref, field.name, val);
                } else if (field is PrivateField && !(field is PrivateMethod)) {
                    trace('[FieldMap] convertMethodsInPlace: converting PrivateField "${field.name}" to PrivateMethod');
                    fields[i] = new PrivateMethod(field.ref, field.name, val);
                } else if (field is MapField) {
                    trace('[FieldMap] convertMethodsInPlace: MapField "${field.name}" is a function (no conversion)');
                    // Optionally, you could define a MapMethod if needed
                    // For now, leave as MapField
                } else if (field is ArrayField) {
                    trace('[FieldMap] convertMethodsInPlace: ArrayField "${field.name}" is a function (no conversion)');
                    // Optionally, you could define an ArrayMethod if needed
                    // For now, leave as ArrayField
                } else if (field is DeadField && !(field is DeadMethod)) {
                    trace('[FieldMap] convertMethodsInPlace: converting DeadField "${field.name}" to DeadMethod');
                    fields[i] = new DeadMethod(field.name, val);
                }
            }
        }
        trace('[FieldMap] convertMethodsInPlace: done');
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
    public inline function new(value:ForceCasted<HaxePointer<Dynamic>>) {
        "this is a special object that allows you to access fields of an object dynamically, similar to a map, but with type safety and reflection capabilities.".NativeComment();
        this = new FieldMap(value);
    }

    @:from
    public static inline function fromDynamic(value:Dynamic):Fields {
        return new FieldMap(value);
    }

    @:to
    public inline function owner():FieldOwner {
        @:privateAccess
        return new FieldOwner(this.ref);
    }

    @:to
    public inline function toFieldMap():FieldMap {
        @:privateAccess
        return new FieldMap(this.ref);
    }

    @:to
    public inline function toDynamic():Dynamic {
        "If not specified, returns the underlying reference object.".NativeComment();
                @:privateAccess
        return this.ref;
    }

    @:arrayAccess @:op(a.b)
    public function get(thing:String):Dynamic {
        @:privateAccess
        for (field in this.fields) {
            if (field.name == thing) {
                trace('Field $thing found in Fields with value: ${field.value}');
                return field.value;
            }
        }
                @:privateAccess
        if (!this.isClass) {
            return null;
        }
        throw 'Field $thing not found in Fields.';
    }

    public inline function printFields():Void {
        @:privateAccess
        for (field in this.fields) {
            trace('Field: ${field.name}, Value: ${field.value}');
            this.buildFields(); // Rebuild fields to ensure they are up-to-date
        }
    }

    @:arrayAccess @:op(a.b)
    public inline function set(thing:String, value:Dynamic):Void {
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