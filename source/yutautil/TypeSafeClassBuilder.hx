import haxe.ds.StringMap;

class TypedField<T> {
    public var name:String;
    public var type:Class<Dynamic>;
    private var _value:T;

    public function new(name:String, type:Class<Dynamic>, initialValue:T) {
        this.name = name;
        this.type = type;
        this._value = initialValue;
    }

    public function getValue():T {
        return _value;
    }

    public function setValue(newValue:T):T {
        if (type != Dynamic && type != Any && Type.typeof(newValue) != Type.getClass(type)) {
            throw 'Type mismatch: Expected ' + type + ' but got ' + Type.typeof(newValue);
        }
        if (type == Any && _value == null) {
            type = Type.getClass(newValue);
        }
        _value = newValue;
        return _value;
    }
}

class MethodWrapper {
    public var name:String;
    public var method:Dynamic;

    public function new(name:String, method:Dynamic) {
        if (!Reflect.isFunction(method)) {
            throw 'Cannot add method: Provided value is not a function: ' + name;
        }
        this.name = name;
        this.method = method;
    }
}

class TypeSafeClassBuilder<T> {
    private var fields:StringMap<TypedField<T>>;
    private var methods:StringMap<MethodWrapper>;

    public static var PublicClasses:Map<String, Dynamic> = new Map<String, Dynamic>();

    public function new() {
        fields = new StringMap<TypedField<T>>();
        methods = new StringMap<MethodWrapper>();
    }

    public function addField(fieldName:String, type:Class<Dynamic>, value:T):Void {
        if (methods.exists(fieldName)) {
            throw 'Cannot add field: A method with the same name already exists: ' + fieldName;
        }
        fields.set(fieldName, new TypedField<T>(fieldName, type, value));
        Reflect.setField(this, fieldName, function(newValue:T):T {
            return fields.get(fieldName)._value = newValue;
        });
    }

    public function addEmptyField(fieldName:String, ?type:Class<Dynamic>):Void {
        addField(fieldName, type != null ? type : Dynamic, null);
    }

    public function addMethod(methodName:String, method:Dynamic):Void {
        if (fields.exists(methodName)) {
            throw 'Cannot add method: A field with the same name already exists: ' + methodName;
        }
        methods.set(methodName, new MethodWrapper(methodName, method));
    }

    public function hasField(fieldName:String):Bool {
        return fields.exists(fieldName);
    }

    public function hasMethod(methodName:String):Bool {
        return methods.exists(methodName);
    }

    public function build(?name:String, ?perm:Bool):Dynamic {
        var instance = {};

        for (fieldName in fields.keys()) {
            Reflect.setField(instance, fieldName, fields.get(fieldName).value);
        }

        for (methodName in methods.keys()) {
            Reflect.setField(instance, methodName, methods.get(methodName).method);
        }

        if (perm) {
            if (name == null) {
                throw 'Cannot build: Name cannot be null';
            }
            PublicClasses.set(name, instance);
        }

        return instance;
    }

    public function getField(fieldName:String):T {
        if (!fields.exists(fieldName)) {
            throw 'Field not found: ' + fieldName;
        }
        return fields.get(fieldName).value;
    }

    public function getMethod(methodName:String):Dynamic {
        if (!methods.exists(methodName)) {
            throw 'Method not found: ' + methodName;
        }
        return methods.get(methodName).method;
    }

    public function removeField(fieldName:String):Void {
        if (!fields.exists(fieldName)) {
            throw 'Cannot remove field: Field not found: ' + fieldName;
        }
        fields.remove(fieldName);
    }

    public function removeMethod(methodName:String):Void {
        if (!methods.exists(methodName)) {
            throw 'Cannot remove method: Method not found: ' + methodName;
        }
        methods.remove(methodName);
    }
}