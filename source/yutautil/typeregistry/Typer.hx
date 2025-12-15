package yutautil.typeregistry;

/**
 * Type identifier for the enhanced 'is' function
 * Allows both Class/Enum types and string-based type names
 */
abstract TypeIdentifier(Dynamic) from Class<Dynamic> from Enum<Dynamic> from String {
    public function toString():String {
        if (Std.isOfType(this, String)) {
            return cast this;
        } else if (Std.isOfType(this, Class)) {
            return Type.getClassName(cast this);
        } else if (Std.isOfType(this, Enum)) {
            return Type.getEnumName(cast this);
        }
        return Std.string(this);
    }

    public function getClass():Class<Dynamic> {
        if (Std.isOfType(this, Class)) {
            return cast this;
        } else if (Std.isOfType(this, String)) {
            return Type.resolveClass(cast this);
        }
        return null;
    }

    public function getEnum():Enum<Dynamic> {
        if (Std.isOfType(this, Enum)) {
            return cast this;
        } else if (Std.isOfType(this, String)) {
            return Type.resolveEnum(cast this);
        }
        return null;
    }
}

/**
 * Main type checking and casting utility
 * Converts objects into typed objects with comprehensive validation
 * Enhanced with improved 'is' function supporting both runtime and registry-based checking
 */
class Typer {
    private static var registry:RuntimeRegistry;

    static function __init__() {
        registry = RuntimeRegistry.get();
    }

    /**
     * Attempt to type an object as a specific type
     */
    public static function type(obj:Dynamic, typeName:String):Typed {
        registry.initialize();

        var typeInfo = registry.getTypeInfo(typeName);
        if (typeInfo == null) {
            return new Typed(obj, typeName, null, TypeValidationResult.invalid(['Type not found in registry: $typeName']));
        }

        var validationResult = validateType(obj, typeInfo);
        return new Typed(obj, typeName, typeInfo, validationResult);
    }

    /**
     * Auto-detect the most likely type for an object
     */
    public static function autoType(obj:Dynamic):Array<Typed> {
        registry.initialize();

        var results = [];

        // Try all registered types
        for (typeName in registry.getAllTypes()) {
            var typeInfo = registry.getTypeInfo(typeName);
            var validationResult = validateType(obj, typeInfo);

            if (validationResult.isValid || validationResult.confidence > 0.5) {
                results.push(new Typed(obj, typeName, typeInfo, validationResult));
            }
        }

        // Sort by confidence
        results.sort(function(a, b) {
            return Std.int((b.validationResult.confidence - a.validationResult.confidence) * 100);
        });

        return results;
    }

    /**
     * Check if an object can be typed as a specific abstract
     */
    public static function checkAbstract(obj:Dynamic, abstractTypeName:String):Typed {
        registry.initialize();

        var abstractInfo = registry.getAbstractInfo(abstractTypeName);
        if (abstractInfo == null) {
            return new Typed(obj, abstractTypeName, null, TypeValidationResult.invalid(['Abstract type not found: $abstractTypeName']));
        }

        var validationResult = validateAbstract(obj, abstractInfo);
        return new Typed(obj, abstractTypeName, abstractInfo, validationResult);
    }

    /**
     * Check if an object matches a typedef structure
     */
    public static function checkTypedef(obj:Dynamic, typedefName:String):Typed {
        registry.initialize();

        var typedefInfo = registry.getTypedefInfo(typedefName);
        if (typedefInfo == null) {
            return new Typed(obj, typedefName, null, TypeValidationResult.invalid(['Typedef not found: $typedefName']));
        }

        var validationResult = validateTypedef(obj, typedefInfo);
        return new Typed(obj, typedefName, typedefInfo, validationResult);
    }

    /**
     * Check if an object is an instance of a class
     */
    public static function checkClass(obj:Dynamic, className:String):Typed {
        registry.initialize();

        var classInfo = registry.getClassInfo(className);
        if (classInfo == null) {
            return new Typed(obj, className, null, TypeValidationResult.invalid(['Class not found: $className']));
        }

        var validationResult = validateClass(obj, classInfo);
        return new Typed(obj, className, classInfo, validationResult);
    }

    /**
     * Find all possible abstract types that could match a value
     */
    public static function findPossibleAbstracts(obj:Dynamic):Array<Typed> {
        registry.initialize();

        var results = [];
        var possibleAbstracts = registry.findAbstractsForValue(obj);

        for (abstractInfo in possibleAbstracts) {
            var validationResult = validateAbstract(obj, abstractInfo);
            results.push(new Typed(obj, abstractInfo.getFullName(), abstractInfo, validationResult));
        }

        return results;
    }

    // Validation methods

    private static function validateType(obj:Dynamic, typeInfo:TypeInfo):TypeValidationResult {
        if (typeInfo == null) {
            return TypeValidationResult.invalid(['TypeInfo is null']);
        }

        if (typeInfo.isAbstract) {
            return validateAbstract(obj, cast(typeInfo, AbstractInfo));
        } else if (Std.isOfType(typeInfo, ClassInfo)) {
            return validateClass(obj, cast(typeInfo, ClassInfo));
        } else if (Std.isOfType(typeInfo, TypedefInfo)) {
            return validateTypedef(obj, cast(typeInfo, TypedefInfo));
        }

        // Basic validation for generic types
        return TypeValidationResult.valid(0.5);
    }

    private static function validateAbstract(obj:Dynamic, abstractInfo:AbstractInfo):TypeValidationResult {
        if (abstractInfo.couldBeType(obj)) {
            return TypeValidationResult.valid(0.8);
        }

        return TypeValidationResult.invalid(['Value does not match abstract type ${abstractInfo.getFullName()}']);
    }

    private static function validateClass(obj:Dynamic, classInfo:ClassInfo):TypeValidationResult {
        if (obj == null) {
            return TypeValidationResult.invalid(['Object is null']);
        }

        var objClass = Type.getClass(obj);
        if (objClass == null) {
            return TypeValidationResult.invalid(['Object has no class type']);
        }

        var objClassName = Type.getClassName(objClass);
        if (objClassName == classInfo.getFullName()) {
            return TypeValidationResult.valid();
        }

        // Check if it's a subclass
        var superClass = Type.getSuperClass(objClass);
        while (superClass != null) {
            if (Type.getClassName(superClass) == classInfo.getFullName()) {
                return TypeValidationResult.valid(0.9);
            }
            superClass = Type.getSuperClass(superClass);
        }

        return TypeValidationResult.invalid(['Object is not an instance of ${classInfo.getFullName()}']);
    }

    private static function validateTypedef(obj:Dynamic, typedefInfo:TypedefInfo):TypeValidationResult {
        if (!typedefInfo.matchesStructure(obj)) {
            var missing = typedefInfo.getMissingFields(obj);
            var errors = ['Object does not match typedef structure'];

            if (missing.length > 0) {
                errors.push('Missing required fields: ${missing.join(", ")}');
            }

            var extra = typedefInfo.getExtraFields(obj);
            var warnings = extra.length > 0 ? ['Extra fields found: ${extra.join(", ")}'] : [];

            return TypeValidationResult.invalid(errors, warnings);
        }

        return TypeValidationResult.valid();
    }

    /**
     * Create a strongly typed object with runtime validation
     */
    public static function createTyped<T>(value:Dynamic, typeName:String, targetClass:Class<T>):T {
        var typed = type(value, typeName);

        if (!typed.isValid()) {
            throw 'Cannot create typed object: ${typed.getErrors().join(", ")}';
        }

        var casted = typed.cast(targetClass);
        if (casted == null) {
            throw 'Cannot cast to target class ${Type.getClassName(targetClass)}';
        }

        return casted;
    }

    /**
     * Enhanced type checking function similar to Std.isOfType but with registry support
     * Supports both Class/Enum types and string-based type names from the registry
     */
    public static function is(obj:Dynamic, type:TypeIdentifier):Bool {
        if (obj == null) {
            return false;
        }

        // Try standard Std.isOfType first for performance
        var typeClass = type.getClass();
        if (typeClass != null) {
            if (Std.isOfType(obj, typeClass)) {
                return true;
            }
        }

        // Try enum check
        var typeEnum = type.getEnum();
        if (typeEnum != null) {
            return Type.typeof(obj).match(TEnum(typeEnum));
        }

        // Fall back to registry-based checking
        registry.initialize();
        var typeName = type.toString();

        if (registry.hasType(typeName)) {
            var typed = type(obj, typeName);
            return typed.isValid();
        }

        // Try abstract recognition
        var abstractCandidates = findPossibleAbstracts(obj);
        for (candidate in abstractCandidates) {
            if (candidate.typeName == typeName && candidate.validationResult.confidence > 0.7) {
                return true;
            }
        }

        return false;
    }

    /**
     * Enhanced type checking with confidence score
     * Returns both the result and confidence level
     */
    public static function isWithConfidence(obj:Dynamic, type:TypeIdentifier):{result:Bool, confidence:Float} {
        if (obj == null) {
            return {result: false, confidence: 0.0};
        }

        // Try standard checks first with maximum confidence
        var typeClass = type.getClass();
        if (typeClass != null && Std.isOfType(obj, typeClass)) {
            return {result: true, confidence: 1.0};
        }

        var typeEnum = type.getEnum();
        if (typeEnum != null && Type.typeof(obj).match(TEnum(typeEnum))) {
            return {result: true, confidence: 1.0};
        }

        // Registry-based checking with confidence
        registry.initialize();
        var typeName = type.toString();

        if (registry.hasType(typeName)) {
            var typed = type(obj, typeName);
            return {result: typed.isValid(), confidence: typed.validationResult.confidence};
        }

        // Abstract recognition with confidence
        var abstractCandidates = findPossibleAbstracts(obj);
        for (candidate in abstractCandidates) {
            if (candidate.typeName == typeName) {
                return {result: candidate.confidence > 0.5, confidence: candidate.confidence};
            }
        }

        return {result: false, confidence: 0.0};
    }

    /**
     * Check if an object can be safely cast to a type
     */
    public static function canCast<T>(obj:Dynamic, type:TypeIdentifier, targetClass:Class<T>):Bool {
        if (!is(obj, type)) {
            return false;
        }

        try {
            var casted = Std.downcast(obj, targetClass);
            return casted != null;
        } catch (e:Dynamic) {
            return false;
        }
    }

    /**
     * Safe casting with type checking
     */
    public static function safeCast<T>(obj:Dynamic, type:TypeIdentifier, targetClass:Class<T>):T {
        if (canCast(obj, type, targetClass)) {
            return Std.downcast(obj, targetClass);
        }
        return null;
    }

    /**
     * Get all types that an object could potentially be
     */
    public static function getAllPossibleTypes(obj:Dynamic):Array<{name:String, confidence:Float, source:String}> {
        var results = [];

        // Add native type with maximum confidence
        var nativeType = Type.typeof(obj);
        switch (nativeType) {
            case TClass(c):
                results.push({
                    name: Type.getClassName(c),
                    confidence: 1.0,
                    source: "native"
                });
            case TEnum(e):
                results.push({
                    name: Type.getEnumName(e),
                    confidence: 1.0,
                    source: "native"
                });
            case _:
        }

        // Add registry types
        var registryTypes = autoType(obj);
        for (typed in registryTypes) {
            results.push({
                name: typed.typeName,
                confidence: typed.validationResult.confidence,
                source: "registry"
            });
        }

        // Add abstract types
        var abstractTypes = findPossibleAbstracts(obj);
        for (abstract in abstractTypes) {
            results.push({
                name: abstract.typeName,
                confidence: abstract.confidence,
                source: "abstract"
            });
        }

        // Sort by confidence
        results.sort(function(a, b) {
            return Std.int((b.confidence - a.confidence) * 100);
        });

        return results;
    }

    /**
     * Create a type checker function for a specific type
     */
    public static function createTypeChecker(type:TypeIdentifier):Dynamic->Bool {
        return function(obj:Dynamic):Bool {
            return is(obj, type);
        };
    }

    /**
     * Batch type checking for multiple objects
     */
    public static function checkMultiple(objects:Array<Dynamic>, type:TypeIdentifier):Array<Bool> {
        return [for (obj in objects) is(obj, type)];
    }

    /**
     * Find the most specific type for an object
     */
    public static function getMostSpecificType(obj:Dynamic):String {
        var allTypes = getAllPossibleTypes(obj);

        // Prefer native types, then registry types, then abstracts
        for (typeInfo in allTypes) {
            if (typeInfo.source == "native" && typeInfo.confidence == 1.0) {
                return typeInfo.name;
            }
        }

        // Return the highest confidence type
        return allTypes.length > 0 ? allTypes[0].name : "unknown";
    }

    /**
     * Utility to get comprehensive type information about any object
     */
    public static function inspect(obj:Dynamic):{
        value:Dynamic,
        nativeType:String,
        possibleTypes:Array<String>,
        bestMatch:String,
        confidence:Float,
        mostSpecific:String
    } {
        var nativeType = Std.string(Type.typeof(obj));
        var possibleTypes = autoType(obj);
        var allTypes = getAllPossibleTypes(obj);

        var bestMatch = possibleTypes.length > 0 ? possibleTypes[0].typeName : "unknown";
        var confidence = possibleTypes.length > 0 ? possibleTypes[0].validationResult.confidence : 0.0;
        var mostSpecific = getMostSpecificType(obj);

        return {
            value: obj,
            nativeType: nativeType,
            possibleTypes: [for (typed in possibleTypes) typed.typeName],
            bestMatch: bestMatch,
            confidence: confidence,
            mostSpecific: mostSpecific
        };
    }
}
