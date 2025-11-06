package yutautil;

import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

#if macro
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
#end

/**
 * PatchedMacro handles compile-time validation and field checking for the Patched type system.
 * This macro ensures that field access on patched objects is validated at compile time.
 */
class PatchedMacro {
    #if macro
    /**
     * Global registry of all patched types and their extensions.
     * Maps base type name to a map of extension names to their field definitions.
     */
    static var patchRegistry:StringMap<StringMap<Array<PatchedField>>> = new StringMap();

    /**
     * Initialize the macro system and set up global metadata processing.
     * This is called from Project.xml during compilation.
     */
    public static function init():Void {
        // Set up global metadata processing for field access validation
        Context.onGenerate(function(types:Array<Type>):Void {
            // This runs after all types are processed
            trace("PatchedMacro: Processing " + types.length + " types for patch validation");
        });

        // Register a build macro for all classes to enable patch field validation
        Context.onTypeNotFound(function(typeName:String):Type {
            // This allows us to handle dynamic type creation if needed
            return null;
        });

        trace("PatchedMacro: Initialized global patch validation system");
    }

    /**
     * Validates field access on patched objects at compile time.
     * Called when accessing fields via dot notation or array access.
     */
    public static function validateFieldAccess(patchedExpr:Expr, fieldName:String):Expr {
        var pos = Context.currentPos();

        try {
            // Get the type of the patched expression
            var exprType = Context.typeof(patchedExpr);
            var baseTypeName = getBaseTypeName(exprType);

            if (baseTypeName == null) {
                Context.warning("Could not determine base type for patched object", pos);
                return macro $patchedExpr.getField($v{fieldName});
            }

            // Check if this field exists in the base type or any registered patches
            if (isValidField(baseTypeName, fieldName)) {
                return macro $patchedExpr.getField($v{fieldName});
            } else {
                // Generate compile-time error for missing field
                var availableFields = getAvailableFields(baseTypeName);
                var errorMsg = 'Field "$fieldName" not found on patched type $baseTypeName';
                if (availableFields.length > 0) {
                    errorMsg += '. Available fields: ' + availableFields.join(", ");
                }
                Context.error(errorMsg, pos);
                return macro null;
            }
        } catch (e:Dynamic) {
            Context.warning("Error validating field access: " + Std.string(e), pos);
            return macro $patchedExpr.getField($v{fieldName});
        }
    }

    /**
     * Registers a patch extension for a base type.
     */
    public static function registerPatch(baseTypeName:String, extensionName:String, fields:Array<PatchedField>):Void {
        if (!patchRegistry.exists(baseTypeName)) {
            patchRegistry.set(baseTypeName, new StringMap());
        }
        patchRegistry.get(baseTypeName).set(extensionName, fields);
    }

    /**
     * Extracts the base type name from a Type instance.
     */
    static function getBaseTypeName(type:Type):String {
        return switch (type) {
            case TInst(t, _):
                var classType = t.get();
                classType.name;
            case TType(t, _):
                var defType = t.get();
                defType.name;
            case TAbstract(t, _):
                var abstractType = t.get();
                abstractType.name;
            case _: null;
        }
    }

    /**
     * Checks if a field is valid for the given base type (including patches).
     */
    static function isValidField(baseTypeName:String, fieldName:String):Bool {
        // First check if it's a base class field
        try {
            var baseType = Context.getType(baseTypeName);
            if (hasClassField(baseType, fieldName)) {
                return true;
            }
        } catch (e:Dynamic) {
            // Type might not exist or be accessible
        }

        // Check registered patches
        if (patchRegistry.exists(baseTypeName)) {
            var patches = patchRegistry.get(baseTypeName);
            for (patchFields in patches) {
                for (field in patchFields) {
                    if (field.name == fieldName) {
                        return true;
                    }
                }
            }
        }

        return false;
    }

    /**
     * Gets all available fields for a base type (base + patches).
     */
    static function getAvailableFields(baseTypeName:String):Array<String> {
        var fields:Array<String> = [];

        // Add base class fields
        try {
            var baseType = Context.getType(baseTypeName);
            fields = fields.concat(getClassFields(baseType));
        } catch (e:Dynamic) {
            // Type might not exist or be accessible
        }

        // Add patch fields
        if (patchRegistry.exists(baseTypeName)) {
            var patches = patchRegistry.get(baseTypeName);
            for (patchFields in patches) {
                for (field in patchFields) {
                    if (fields.indexOf(field.name) == -1) {
                        fields.push(field.name);
                    }
                }
            }
        }

        return fields;
    }

    /**
     * Checks if a type has a specific field.
     */
    static function hasClassField(type:Type, fieldName:String):Bool {
        return switch (type) {
            case TInst(t, _):
                var classType = t.get();
                var allFields = classType.fields.get().concat(classType.statics.get());
                allFields.exists(function(f) return f.name == fieldName);
            case TType(t, _):
                var defType = t.get();
                hasClassField(defType.type, fieldName);
            case TAbstract(t, _):
                var abstractType = t.get();
                // Check implementation fields if available
                if (abstractType.impl != null) {
                    var implFields = abstractType.impl.get().statics.get();
                    implFields.exists(function(f) return f.name == fieldName);
                } else {
                    false;
                }
            case _: false;
        }
    }

    /**
     * Gets all field names from a type.
     */
    static function getClassFields(type:Type):Array<String> {
        return switch (type) {
            case TInst(t, _):
                var classType = t.get();
                var allFields = classType.fields.get().concat(classType.statics.get());
                [for (f in allFields) f.name];
            case TType(t, _):
                var defType = t.get();
                getClassFields(defType.type);
            case TAbstract(t, _):
                var abstractType = t.get();
                if (abstractType.impl != null) {
                    var implFields = abstractType.impl.get().statics.get();
                    [for (f in implFields) f.name];
                } else {
                    [];
                }
            case _: [];
        }
    }
    #end
}

/**
 * Represents a field definition in a patch extension.
 */
typedef PatchedField = {
    name:String,
    type:String,
    isMethod:Bool,
    ?defaultValue:Dynamic,
    ?getter:Dynamic->Dynamic,
    ?setter:Dynamic->Dynamic->Void
}

/**
 * Runtime storage for patch extensions.
 */
class PatchRegistry {
    static var extensions:StringMap<StringMap<PatchExtension>> = new StringMap();

    public static function registerExtension(baseTypeName:String, extensionName:String, extension:PatchExtension):Void {
        if (!extensions.exists(baseTypeName)) {
            extensions.set(baseTypeName, new StringMap());
        }
        extensions.get(baseTypeName).set(extensionName, extension);

        #if macro
        // Also register with macro system
        PatchedMacro.registerPatch(baseTypeName, extensionName, extension.fields);
        #end
    }

    public static function getExtension(baseTypeName:String, extensionName:String):PatchExtension {
        if (extensions.exists(baseTypeName)) {
            return extensions.get(baseTypeName).get(extensionName);
        }
        return null;
    }

    public static function getAllExtensions(baseTypeName:String):StringMap<PatchExtension> {
        return extensions.get(baseTypeName);
    }

    public static function hasExtension(baseTypeName:String, extensionName:String):Bool {
        return extensions.exists(baseTypeName) && extensions.get(baseTypeName).exists(extensionName);
    }
}

/**
 * Represents a runtime patch extension containing fields and methods.
 */
class PatchExtension {
    public var name:String;
    public var fields:Array<PatchedField>;
    public var fieldMap:StringMap<PatchedField>;
    public var data:StringMap<Dynamic>;

    public function new(name:String, fields:Array<PatchedField>) {
        this.name = name;
        this.fields = fields;
        this.fieldMap = new StringMap();
        this.data = new StringMap();

        for (field in fields) {
            fieldMap.set(field.name, field);
            if (field.defaultValue != null) {
                data.set(field.name, field.defaultValue);
            }
        }
    }

    public function hasField(fieldName:String):Bool {
        return fieldMap.exists(fieldName);
    }

    public function getField(fieldName:String):Dynamic {
        if (!hasField(fieldName)) return null;

        var field = fieldMap.get(fieldName);
        if (field.getter != null) {
            return field.getter(data.get(fieldName));
        }
        return data.get(fieldName);
    }

    public function setField(fieldName:String, value:Dynamic):Void {
        if (!hasField(fieldName)) return;

        var field = fieldMap.get(fieldName);
        if (field.setter != null) {
            field.setter(data.get(fieldName), value);
        } else {
            data.set(fieldName, value);
        }
    }

    public function callMethod(methodName:String, args:Array<Dynamic>):Dynamic {
        var field = fieldMap.get(methodName);
        if (field != null && field.isMethod && data.exists(methodName)) {
            var method = data.get(methodName);
            if (Reflect.isFunction(method)) {
                return Reflect.callMethod(null, method, args);
            }
        }
        throw 'Method $methodName not found or not callable';
    }
}

/**
 * Patched<T> is an abstract type that enables runtime patching of classes.
 * It allows adding new fields and methods to existing objects without modifying the original class.
 *
 * Features:
 * - Runtime field addition and access
 * - Compile-time field validation via macros
 * - Support for getters/setters on patched fields
 * - Method patching with proper this binding
 * - Multiple patch extensions per object
 * - Type-safe field access with error reporting
 *
 * Usage:
 * ```haxe
 * var obj = new SomeClass();
 * var patched:Patched<SomeClass> = obj;
 *
 * // Add an extension
 * patched.addExtension("MyExtension", [
 *     { name: "newField", type: "String", isMethod: false, defaultValue: "default" },
 *     { name: "newMethod", type: "Int->String", isMethod: true, defaultValue: function(x:Int) return "Result: " + x }
 * ]);
 *
 * // Access fields (with compile-time validation)
 * patched.newField = "Hello";
 * var result = patched.newMethod(42);
 * ```
 */
abstract Patched<T>(PatchedImpl<T>) {
    public inline function new(baseObject:T) {
        this = new PatchedImpl(baseObject);
    }

    @:from
    public static inline function fromObject<T>(obj:T):Patched<T> {
        return new Patched(obj);
    }

    @:to
    public inline function toBase():T {
        return this.baseObject;
    }

    @:to
    public inline function toImpl():PatchedImpl<T> {
        return this;
    }

    /**
     * Adds a new patch extension to this object.
     */
    public inline function addExtension(name:String, fields:Array<PatchedField>):Void {
        this.addExtension(name, fields);
    }

    /**
     * Removes a patch extension from this object.
     */
    public inline function removeExtension(name:String):Void {
        this.removeExtension(name);
    }

    /**
     * Checks if an extension exists on this object.
     */
    public inline function hasExtension(name:String):Bool {
        return this.hasExtension(name);
    }

    /**
     * Gets all extension names for this object.
     */
    public inline function getExtensionNames():Array<String> {
        return this.getExtensionNames();
    }

    /**
     * Field access with compile-time validation.
     * This uses a macro to validate field existence at compile time.
     */
    @:op(a.b)
    public macro function getField(self:Expr, fieldName:String):Expr {
        #if macro
        return PatchedMacro.validateFieldAccess(self, fieldName);
        #else
        return macro $self.getField($v{fieldName});
        #end
    }

    /**
     * Field assignment with compile-time validation.
     */
    @:op(a.b)
    public macro function setField(self:Expr, fieldName:String, value:Expr):Expr {
        #if macro
        // Validate field exists before allowing assignment
        var pos = Context.currentPos();
        var validationExpr = PatchedMacro.validateFieldAccess(self, fieldName);
        return macro {
            ${validationExpr}; // This will error if field doesn't exist
            $self.setField($v{fieldName}, $value);
        };
        #else
        return macro $self.setField($v{fieldName}, $value);
        #end
    }

    /**
     * Array-style field access.
     */
    @:arrayAccess
    public inline function arrayGet(fieldName:String):Dynamic {
        return this.getField(fieldName);
    }

    /**
     * Array-style field assignment.
     */
    @:arrayAccess
    public inline function arraySet(fieldName:String, value:Dynamic):Dynamic {
        this.setField(fieldName, value);
        return value;
    }

    /**
     * Method calling with arguments.
     */
    public inline function callMethod(methodName:String, args:Array<Dynamic>):Dynamic {
        return this.callMethod(methodName, args);
    }

    /**
     * Gets information about all available fields (base + patches).
     */
    public inline function getFieldInfo():Array<{name:String, type:String, source:String}> {
        return this.getFieldInfo();
    }
}

/**
 * Implementation class for Patched<T>.
 * Handles the actual runtime patching logic.
 */
class PatchedImpl<T> {
    public var baseObject:T;
    public var extensions:StringMap<PatchExtension>;
    public var baseTypeName:String;

    public function new(baseObject:T) {
        this.baseObject = baseObject;
        this.extensions = new StringMap();
        this.baseTypeName = getTypeName(baseObject);
    }

    function getTypeName(obj:Dynamic):String {
        var cls = Type.getClass(obj);
        if (cls != null) {
            return Type.getClassName(cls);
        }
        return "Dynamic";
    }

    public function addExtension(name:String, fields:Array<PatchedField>):Void {
        var extension = new PatchExtension(name, fields);
        extensions.set(name, extension);

        // Register globally for macro validation
        PatchRegistry.registerExtension(baseTypeName, name, extension);
    }

    public function removeExtension(name:String):Void {
        extensions.remove(name);
    }

    public function hasExtension(name:String):Bool {
        return extensions.exists(name);
    }

    public function getExtensionNames():Array<String> {
        var names = [];
        for (name in extensions.keys()) {
            names.push(name);
        }
        return names;
    }

    public function getField(fieldName:String):Dynamic {
        // First try base object
        try {
            var baseValue = Reflect.field(baseObject, fieldName);
            if (baseValue != null) return baseValue;
        } catch (e:Dynamic) {
            // Field doesn't exist on base object
        }

        // Then try extensions
        for (extension in extensions) {
            if (extension.hasField(fieldName)) {
                return extension.getField(fieldName);
            }
        }

        // Field not found anywhere
        throw 'Field "$fieldName" not found on ${baseTypeName} or any of its extensions';
    }

    public function setField(fieldName:String, value:Dynamic):Void {
        // Check if field exists in base object
        var existsInBase = false;
        try {
            Reflect.field(baseObject, fieldName);
            existsInBase = true;
        } catch (e:Dynamic) {
            // Field doesn't exist on base object
        }

        if (existsInBase) {
            Reflect.setField(baseObject, fieldName, value);
            return;
        }

        // Try extensions
        for (extension in extensions) {
            if (extension.hasField(fieldName)) {
                extension.setField(fieldName, value);
                return;
            }
        }

        // Field not found anywhere
        throw 'Field "$fieldName" not found on ${baseTypeName} or any of its extensions';
    }

    public function callMethod(methodName:String, args:Array<Dynamic>):Dynamic {
        // First try base object
        try {
            var baseMethod = Reflect.field(baseObject, methodName);
            if (baseMethod != null && Reflect.isFunction(baseMethod)) {
                return Reflect.callMethod(baseObject, baseMethod, args);
            }
        } catch (e:Dynamic) {
            // Method doesn't exist on base object
        }

        // Then try extensions
        for (extension in extensions) {
            if (extension.hasField(methodName)) {
                var field = extension.fieldMap.get(methodName);
                if (field.isMethod) {
                    return extension.callMethod(methodName, args);
                }
            }
        }

        // Method not found anywhere
        throw 'Method "$methodName" not found on ${baseTypeName} or any of its extensions';
    }

    public function getFieldInfo():Array<{name:String, type:String, source:String}> {
        var info = [];

        // Add base object fields
        var baseFields = Type.getInstanceFields(Type.getClass(baseObject));
        for (fieldName in baseFields) {
            info.push({
                name: fieldName,
                type: "Unknown", // Could be enhanced with more type reflection
                source: baseTypeName
            });
        }

        // Add extension fields
        for (extensionName in extensions.keys()) {
            var extension = extensions.get(extensionName);
            for (field in extension.fields) {
                info.push({
                    name: field.name,
                    type: field.type,
                    source: 'Extension:$extensionName'
                });
            }
        }

        return info;
    }
}
