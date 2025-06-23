package yutautil;

import openfl.utils.ByteArray;
import haxe.rtti.Meta;
import haxe.ds.StringMap;
import haxe.Constraints.IMap;

import haxe.io.Bytes;

// Helper to describe field info
typedef FieldInfo = {
    var name:String;
    var type:Dynamic;
};

// TypedByteData holds the bytes and the type name
typedef TypedByteData = {var bytes:ByteArray; var typeName:String;}

// Registry for class field info
class TypeRegistry {
    static var fieldsMap:StringMap<Array<FieldInfo>> = new StringMap();

    public static function register<T>(cls:Class<T>, fields:Array<FieldInfo>) {
        fieldsMap.set(Type.getClassName(cls), fields);
    }

    public static function getFields(typeName:String):Array<FieldInfo> {
        return fieldsMap.get(typeName);
    }
}

// Main converter
class ByteConverter {
    // Converts TypedByteData to object of type T
    public static function toObject<T>(data:TypedByteData):T {
        var fields = TypeRegistry.getFields(data.typeName);
        if (fields == null) throw 'Unknown type: ' + data.typeName;

        var obj = Type.createInstance(Type.resolveClass(data.typeName), []);
        var bytes = data.bytes;
        bytes.position = 0;

        for (field in fields) {
            var value:Dynamic = switch (field.type) {
                case Int: bytes.readInt32();
                case Float: bytes.readDouble();
                case Bool: bytes.readBoolean();
                case String:
                    var len = bytes.readInt32();
                    bytes.readUTFBytes(len);
                default:
                    throw 'Unsupported field type: ' + field.type;
            }
            Reflect.setProperty(obj, field.name, value);
        }
        return obj;
    }

    // Converts object to TypedByteData
    public static function fromObject<T>(obj:T):TypedByteData {
        var cls = Type.getClass(obj);
        var typeName = Type.getClassName(cls);
        var fields = TypeRegistry.getFields(typeName);
        if (fields == null) throw 'Unknown type: ' + typeName;

        var bytes = new ByteArray();
        for (field in fields) {
            var value = Reflect.getProperty(obj, field.name);
            switch (field.type) {
                case Int: bytes.writeInt32(value);
                case Float: bytes.writeDouble(value);
                case Bool: bytes.writeBoolean(value);
                case String:
                    var str:String = value;
                    bytes.writeInt32(str.length);
                    bytes.writeUTFBytes(str);
                default:
                    throw 'Unsupported field type: ' + field.type;
            }
        }
        return { bytes: bytes, typeName: typeName };
    }
}

// Abstract for easy conversion
abstract ByteObject(Dynamic) from Dynamic to Dynamic {
    public inline function new(value:Dynamic) {
        this = value;
    }

    @:from
    public static function fromTypedByteData(data:TypedByteData):ByteObject {
        return ByteConverter.toObject(data);
    }

    @:from
    public static function fromByteArray(bytes:ByteArray):ByteObject {
        throw "Cannot convert ByteArray to ByteObject without type info";
    }

    @:to
    public function toTypedByteData():TypedByteData {
        return ByteConverter.fromObject(this);
    }

    @:to
    public function toByteArray():ByteArray {
        return ByteConverter.fromObject(this).bytes;
    }
}