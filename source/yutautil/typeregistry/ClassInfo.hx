package yutautil.typeregistry;

import yutautil.typeregistry.ConstructorInfo;
import yutautil.typeregistry.FieldInfo;
import yutautil.typeregistry.TypeInfo;

/**
 * Extended type information for class types
 */
class ClassInfo extends yutautil.typeregistry.TypeInfo {
    public var isInterface:Bool;
    public var superClass:String;
    public var interfaces:Array<String>;
    public var staticFields:Array<FieldInfo>;
    public var constructorInfo:ConstructorInfo;

    public function new() {
        super();
        isAbstract = false;
        interfaces = [];
        staticFields = [];
    }

    public function getStaticField(name:String):FieldInfo {
        for (field in staticFields) {
            if (field.name == name) return field;
        }
        return null;
    }

    public function hasStaticField(name:String):Bool {
        return getStaticField(name) != null;
    }

    public function hasConstructor():Bool {
        return constructorInfo != null;
    }

    public function getConstructorArgs():Array<{name:String, type:String, opt:Bool}> {
        return constructorInfo != null ? constructorInfo.args : [];
    }
}
