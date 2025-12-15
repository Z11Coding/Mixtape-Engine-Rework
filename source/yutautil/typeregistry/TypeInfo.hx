package yutautil.typeregistry;

import haxe.macro.Position;

/**
 * Base type information class for all type system elements
 */
class TypeInfo {
    public var name:String;
    public var pack:Array<String>;
    public var module:String;
    public var isAbstract:Bool;
    public var fields:Array<FieldInfo>;
    public var doc:String;
    public var pos:Position;

    public function new() {
        fields = [];
        pack = [];
    }

    public function getFullName():String {
        return pack.length > 0 ? pack.join(".") + "." + name : name;
    }

    public function getField(name:String):FieldInfo {
        for (field in fields) {
            if (field.name == name) return field;
        }
        return null;
    }

    public function hasField(name:String):Bool {
        return getField(name) != null;
    }
}
