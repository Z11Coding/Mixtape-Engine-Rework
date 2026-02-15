package yutautil.typeregistry;

import yutautil.typeregistry.TypeInfo;

/**
 * Base class for typed objects - objects that have been validated against the type system
 */
class Typed {
    public var originalValue(default, null):Dynamic;
    public var typeName(default, null):String;
    public var typeInfo(default, null):TypeInfo;
    public var validationResult(default, null):TypeValidationResult;

    public function new(value:Dynamic, typeName:String, typeInfo:TypeInfo, validationResult:TypeValidationResult) {
        this.originalValue = value;
        this.typeName = typeName;
        this.typeInfo = typeInfo;
        this.validationResult = validationResult;
    }

    /**
     * Get the original value
     */
    public function getValue():Dynamic {
        return originalValue;
    }

    /**
     * Check if this typed object is valid
     */
    public function isValid():Bool {
        return validationResult.isValid;
    }

    /**
     * Get validation errors if any
     */
    public function getErrors():Array<String> {
        return validationResult.errors;
    }

    /**
     * Get validation warnings if any
     */
    public function getWarnings():Array<String> {
        return validationResult.warnings;
    }

    /**
     * Cast to a specific type if possible
     */
    public function castTo<T>(targetType:Class<T>):Null<T> {
        try {
            if (Std.isOfType(originalValue, targetType)) {
                return cast originalValue;
            }
            return null;
        } catch (e:Dynamic) {
            return null;
        }
    }

    /**
     * Try to cast to a specific abstract type
     */
    public function castToAbstract(abstractTypeName:String):Dynamic {
        var registry = RuntimeRegistry.get();
        var abstractInfo = registry.getAbstractInfo(abstractTypeName);

        if (abstractInfo == null) {
            return null;
        }

        if (abstractInfo.couldBeType(originalValue)) {
            return originalValue; // Return as-is since abstract casting is compile-time
        }

        return null;
    }

    public function toString():String {
        return 'Typed<$typeName>(${originalValue})';
    }
}

/**
 * Result of type validation
 */
class TypeValidationResult {
    public var isValid(default, null):Bool;
    public var errors(default, null):Array<String>;
    public var warnings(default, null):Array<String>;
    public var confidence(default, null):Float; // 0.0 to 1.0

    public function new(isValid:Bool, errors:Array<String>, warnings:Array<String>, confidence:Float = 1.0) {
        this.isValid = isValid;
        this.errors = errors != null ? errors : [];
        this.warnings = warnings != null ? warnings : [];
        this.confidence = confidence;
    }

    public static function valid(confidence:Float = 1.0):TypeValidationResult {
        return new TypeValidationResult(true, [], [], confidence);
    }

    public static function invalid(errors:Array<String>, warnings:Array<String> = null):TypeValidationResult {
        return new TypeValidationResult(false, errors, warnings != null ? warnings : [], 0.0);
    }

    public static function uncertain(errors:Array<String>, warnings:Array<String>, confidence:Float):TypeValidationResult {
        return new TypeValidationResult(false, errors, warnings, confidence);
    }
}
