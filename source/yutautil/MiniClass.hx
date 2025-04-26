package yutautil;

import haxe.ds.StringMap;

class MiniClass {
    private var fields:StringMap<Dynamic>;

    public function new() {
        fields = new StringMap<Dynamic>();
    }

    public function addField(fieldName:String, value:Dynamic):Void {
        fields.set(fieldName, value);
    }

    public function getField(fieldName:String):Dynamic {
        return fields.get(fieldName);
    }

    public function removeField(fieldName:String):Void {
        fields.remove(fieldName);
    }

    public function hasField(fieldName:String):Bool {
        return fields.exists(fieldName);
    }

    public function invokeMethod(methodName:String, args:Array<Dynamic>):Dynamic {
        var method = fields.get(methodName);
        if (method != null && Reflect.isFunction(method)) {
            return Reflect.callMethod(this, method, args);
        }
        throw 'Method not found or is not callable: ' + methodName;
    }
}

