package yutautil;

import haxe.ds.StringMap;
import haxe.DynamicAccess;

typedef FieldCallback = (field:String, value:Dynamic) -> Void;

class UndefinedFieldException extends haxe.Exception {
    public function new(field:String) {
        super("Field '" + field + "' is not defined in GenericObject.", null, null);
    }
}

class UndefinedField<T> {
    public function new() {}

    public function type():String {
        return Type.getClassName(Type.getClass(this));
    }

    public function toString():String {
        return 'undefined (${type()})';
    }
}

class TypedField<T> {
    public var value:T;

    public function new(value:T) {
        this.value = value;
    }

    public function type():String {
        return Type.getClassName(Type.getClass(this));
    }
    public function toString():String {
        return 'typed (${type()})';
    }
}

abstract DefinedField<T>(TypedField<T>) from TypedField<T> to Dynamic {
    public function new(value:T) {
        this = new TypedField<T>(value);
    }

    public inline function get():T {
        return this.value;
    }

    public inline function set(value:T):T {
        this.value = value;
        return value;
    }
}

class GenericObject {
    private var fields:DynamicAccess<Dynamic>;
    // Private backing fields
    private var _onFieldSet:FieldCallback = null;
    private var _onFieldGet:(field:String) -> Void = null;
    private var _onFieldRemove:(field:String) -> Void = null;
    private var _onFieldCreate:FieldCallback = null;

    // Property for onFieldSet
    public var onFieldSet(get, set):FieldCallback;
    function get_onFieldSet():FieldCallback return _onFieldSet;
    function set_onFieldSet(cb:FieldCallback):FieldCallback {
        if (cb == null) {
            _onFieldSet = null;
        } else {
            _onFieldSet = function(field:String, value:Dynamic) {
                try cb(field, value) catch (e:Dynamic) {};
            }
        }
        return cb;
    }

    // Property for onFieldGet
    public var onFieldGet(get, set):(field:String) -> Void;
    function get_onFieldGet() return _onFieldGet;
    function set_onFieldGet(cb:(field:String) -> Void):(field:String) -> Void {
        if (cb == null) {
            _onFieldGet = null;
        } else {
            _onFieldGet = function(field:String) {
                try cb(field) catch (e:Dynamic) {};
            }
        }
        return cb;
    }

    // Property for onFieldRemove
    public var onFieldRemove(get, set):(field:String) -> Void;
    function get_onFieldRemove() return _onFieldRemove;
    function set_onFieldRemove(cb:(field:String) -> Void):(field:String) -> Void {
        if (cb == null) {
            _onFieldRemove = null;
        } else {
            _onFieldRemove = function(field:String) {
                try cb(field) catch (e:Dynamic) {};
            }
        }
        return cb;
    }

    // Property for onFieldCreate
    public var onFieldCreate(get, set):FieldCallback;
    function get_onFieldCreate():FieldCallback return _onFieldCreate;
    function set_onFieldCreate(cb:FieldCallback):FieldCallback {
        if (cb == null) {
            _onFieldCreate = null;
        } else {
            _onFieldCreate = function(field:String, value:Dynamic) {
                try cb(field, value) catch (e:Dynamic) {};
            }
        }
        return cb;
    }
    public var autoRemoveNull:Bool = false;
    public var giveNullOnUndefined:Bool = true;
    public var allowNullAccess:Bool = true;

    public function new() {
        fields = {};
    }

    public function setField(field:String, value:Dynamic):Void {
        var exists = fields.exists(field);
        fields.set(field, value);
        if (!exists && onFieldCreate != null) onFieldCreate(field, value);
        if (onFieldSet != null) onFieldSet(field, value);
    }

    public function getField(field:String):Dynamic {
        if (onFieldGet != null) onFieldGet(field);
        if (!fields.exists(field)) {
            if (giveNullOnUndefined) return null;
            return new UndefinedField<Dynamic>();
        }
        var value = fields.get(field);
        return (value == null)
            ? (giveNullOnUndefined ? null : new UndefinedField<Dynamic>())
            : value;
    }

    public function removeField(field:String):Bool {
        var exists = fields.exists(field);
        if (exists) {
            fields.remove(field);
            if (onFieldRemove != null) onFieldRemove(field);
        }
        return exists;
    }

    public function exists(field:String):Bool {
        return fields.exists(field);
    }

    public function toAnonymous():Dynamic {
        var obj = {};
        for (k in fields.keys()) Reflect.setField(obj, k, fields.get(k));
        return obj;
    }

    public function toMap():StringMap<Dynamic> {
        var map = new StringMap<Dynamic>();
        for (k in fields.keys()) map.set(k, fields.get(k));
        return map;
    }

    public function toDynamicAccess():DynamicAccess<Dynamic> {
        var da:DynamicAccess<Dynamic> = {};
        for (k in fields.keys()) da.set(k, fields.get(k));
        return da;
    }

    public function keys():Iterator<String> {
        return fields.keys().iterator();
    }

    public function values():Iterator<Dynamic> {
        return fields.iterator();
    }

    public static function fromAnonymous(obj:Dynamic):GenericObject {
        var go = new GenericObject();
        for (field in Reflect.fields(obj)) {
            go.setField(field, Reflect.field(obj, field));
        }
        return go;
    }

    public static function fromMap(map:StringMap<Dynamic>):GenericObject {
        var go = new GenericObject();
        for (field in map.keys()) {
            go.setField(field, map.get(field));
        }
        return go;
    }

    public static function fromDynamicAccess(da:DynamicAccess<Dynamic>):GenericObject {
        var go = new GenericObject();
        for (field in da.keys()) {
            go.setField(field, da.get(field));
        }
        return go;
    }

    public function toString():String {
        var str = "{";
        var first = true;
        for (field in fields.keys()) {
            if (!first) str += ", ";
            first = false;
            str += field + ": " + Std.string(fields.get(field));
        }
        str += "}";
        return str;
    }

    public function toJSON():String {
        var json = "{";
        var first = true;
        for (field in fields.keys()) {
            if (!first) json += ", ";
            first = false;
            json += '"' + field + '": ' + Std.string(fields.get(field));
        }
        json += "}";
        return json;
    }

    public function clone():GenericObject {
        var clone = new GenericObject();
        for (field in fields.keys()) {
            clone.setField(field, fields.get(field));
        }
        clone.onFieldSet = this.onFieldSet;
        clone.onFieldGet = this.onFieldGet;
        clone.onFieldRemove = this.onFieldRemove;
        clone.onFieldCreate = this.onFieldCreate;
        clone.autoRemoveNull = this.autoRemoveNull;
        clone.giveNullOnUndefined = this.giveNullOnUndefined;
        clone.allowNullAccess = this.allowNullAccess;
        return clone;
    }

    public function merge(other:GenericObject):GenericObject {
        var merged = this.clone();
        for (field in other.fields.keys()) {
            merged.setField(field, other.fields.get(field));
        }
        return merged;
    }

    public function clear():Void {
        fields = {};
        if (onFieldRemove != null) {
            for (field in fields.keys()) onFieldRemove(field);
        }
    }

    public function isEmpty():Bool {
        return fields.keys().length == 0;
    }

    public static function hxFromDynamicAccess(da:DynamicAccess<Dynamic>, safety:Bool = true):GenericObject {
        var go = safety ? new SafeHxObject() : new HxObject();
        for (field in da.keys()) {
            go[field] = da.get(field);
        }
        return go;
    }
}

enum HxObjType {
    Safe;
    Unsafe;
}

abstract HxObject(GenericObject) from GenericObject to Dynamic {
    public function new() {
        this = new GenericObject();
    }

    @:arrayAccess
    public inline function setField(field:String, value:Dynamic):Void {
        this.setField(field, value);
    }
    @:arrayAccess
    public inline function getField(field:String):Dynamic {
        return this.getField(field);
    }

    public inline function removeField(field:String):Bool {
        return this.removeField(field);
    }

    public inline function exists(field:String):Bool {
        return this.exists(field);
    }
    
}

abstract SafeHxObject(GenericObject) from GenericObject to Dynamic {
    public function new() {
        this = new GenericObject(); 
    }

    @:arrayAccess
    public inline function setField(field:String, value:Dynamic):Void {
        var existing = this.getField(field);
        if (existing is TypedField) {
            var typed:TypedField<Dynamic> = cast existing;
            var expectedType = typed.type();
            var valueType = new TypedField(value).type();
            if (valueType != expectedType && valueType != null && expectedType != null) {
                throw 'Type mismatch: expected $expectedType for field "$field", got $valueType';
            }
            this.setField(field, new DefinedField(value));
        } else {
            this.setField(field, new DefinedField(value));
        }
    }
    @:arrayAccess
    public inline function getField(field:String):Dynamic {
        var value = this.getField(field);
        return (value is TypedField) ? value.value : value;
    }

    public inline function removeField(field:String):Bool {
        return this.removeField(field);
    }

    public inline function exists(field:String):Bool {
        return this.exists(field);
    }
}