package yutautil.typeregistry;

import yutautil.typeregistry.TypeInfo;

/**
 * Extended type information for abstract types
 */
class AbstractInfo extends yutautil.typeregistry.TypeInfo {
    public var type:String; // Underlying type
    public var fromCasts:Array<String>;
    public var toCasts:Array<String>;
    public var implClass:String; // Implementation class name

    public function new() {
        super();
        isAbstract = true;
        fromCasts = [];
        toCasts = [];
    }

    /**
     * Check if this abstract can be created from the given type
     */
    public function canCreateFrom(typeName:String):Bool {
        return fromCasts.indexOf(typeName) >= 0 || type == typeName;
    }

    /**
     * Check if this abstract can be cast to the given type
     */
    public function canCastTo(typeName:String):Bool {
        return toCasts.indexOf(typeName) >= 0 || type == typeName;
    }

    /**
     * Get the underlying value type for runtime recognition
     */
    public function getUnderlyingType():String {
        return type;
    }

    /**
     * Check if a value could potentially be of this abstract type
     * This uses the underlying type to make an educated guess
     */
    public function couldBeType(value:Dynamic):Bool {
        if (value == null) return false;

        var valueType = Type.typeof(value);
        var underlyingType = getUnderlyingType();

        return switch (underlyingType.toLowerCase()) {
            case "int" | "integer":
                Type.typeof(value).match(TInt);
            case "float" | "number":
                Type.typeof(value).match(TFloat) || Type.typeof(value).match(TInt);
            case "string":
                Type.typeof(value).match(TClass(String));
            case "bool" | "boolean":
                Type.typeof(value).match(TBool);
            case "array":
                Type.typeof(value).match(TClass(Array));
            case _:
                // For complex types, try to match class names
                var className = Type.getClassName(Type.getClass(value));
                className != null && (className == underlyingType || className.indexOf(underlyingType) >= 0);
        };
    }
}
