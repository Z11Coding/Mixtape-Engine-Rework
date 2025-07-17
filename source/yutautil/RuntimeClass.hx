package yutautil;

enum RuntimeClassFieldVisibility {
    Public;
    Private;
    Static;
}

typedef RuntimeClassField = {
    name:String,
    type:Dynamic,
    visibility:RuntimeClassFieldVisibility,
    value:Dynamic
}

typedef RuntimeClassMethod = {
    name:String,
    fn:haxe.Constraints.Function,
    visibility:RuntimeClassFieldVisibility
}

typedef RuntimeClassStructure = {
    className:String,
    CLASS:{
        fields:Map<String, RuntimeClassField>,
        methods:Map<String, RuntimeClassMethod>,
        staticFields:Map<String, RuntimeClassField>,
        staticMethods:Map<String, RuntimeClassMethod>,
        constructor:Null<haxe.Constraints.Function>,
        typeName:String,
        genericType:Dynamic
    },
    parent:Null<Classable>,
    instances:Array<Dynamic>
}

typedef ClassableStructure = {
    className:String,
    isRuntimeClass:Bool,
    classReference:Dynamic,
    constructor:Null<haxe.Constraints.Function>,
    staticFields:Map<String, Dynamic>,
    staticMethods:Map<String, haxe.Constraints.Function>,
    instanceFields:Map<String, Dynamic>,
    instanceMethods:Map<String, haxe.Constraints.Function>,
    superClass:Null<Classable>
}

/**
 * RuntimeClass is an abstract that simulates a class-like structure at runtime.
 * It supports inheritance, generic typing, static fields/methods, instance fields/methods,
 * and can be used to build dynamic "classes" with similar abilities as native classes.
 * It can extend both native classes and other RuntimeClasses through the Classable system.
 */
abstract RuntimeClass(RuntimeClassStructure) {
    public inline function new(className:String, ?parent:Classable) {
        this = {
            className: className,
            CLASS: {
                fields: new Map<String, RuntimeClassField>(),
                methods: new Map<String, RuntimeClassMethod>(),
                staticFields: new Map<String, RuntimeClassField>(),
                staticMethods: new Map<String, RuntimeClassMethod>(),
                constructor: null,
                typeName: className,
                genericType: null
            },
            parent: parent,
            instances: []
        };
    }

    /**
     * Add a field to the runtime class
     */
    public function addField(name:String, type:Dynamic, visibility:RuntimeClassFieldVisibility = Public, ?defaultValue:Dynamic):RuntimeClass {
        var field:RuntimeClassField = {
            name: name,
            type: type,
            visibility: visibility,
            value: defaultValue
        };
        
        if (visibility == Static) {
            this.CLASS.staticFields.set(name, field);
        } else {
            this.CLASS.fields.set(name, field);
        }
        
        return cast this;
    }

    /**
     * Add a method to the runtime class
     */
    public function addMethod(name:String, fn:haxe.Constraints.Function, visibility:RuntimeClassFieldVisibility = Public):RuntimeClass {
        var method:RuntimeClassMethod = {
            name: name,
            fn: fn, 
            visibility: visibility
        };
        
        if (visibility == Static) {
            this.CLASS.staticMethods.set(name, method);
        } else {
            this.CLASS.methods.set(name, method);
        }
        
        return cast this;
    }

    /**
     * Set the constructor function
     */
    public function setConstructor(fn:haxe.Constraints.Function):RuntimeClass {
        this.CLASS.constructor = fn;
        return cast this;
    }

    /**
     * Create an instance of this runtime class
     */
    public function createInstance(?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        var instance = {};
        
        // Handle inheritance - create parent instance first
        if (this.parent != null) {
            var parentInstance = this.parent.createInstance(args);
            for (field in Reflect.fields(parentInstance)) {
                Reflect.setField(instance, field, Reflect.field(parentInstance, field));
            }
        }
        
        // Copy instance fields with their default values
        for (field in this.CLASS.fields) {
            if (field.visibility == Public || field.visibility == Private) {
                Reflect.setField(instance, field.name, field.value);
            }
        }
        
        // Copy instance methods
        for (method in this.CLASS.methods) {
            if (method.visibility == Public || method.visibility == Private) {
                Reflect.setField(instance, method.name, method.fn);
            }
        }
        
        // Call constructor if it exists
        if (this.CLASS.constructor != null) {
            Reflect.callMethod(instance, this.CLASS.constructor, args);
        }
        
        // Add instance to tracking
        this.instances.push(instance);
        
        return instance;
    }

    /**
     * Get static field value
     */
    public function getStaticField(name:String):Dynamic {
        var field = this.CLASS.staticFields.get(name);
        if (field != null) {
            return field.value;
        }
        
        // Check parent class for static field
        if (this.parent != null) {
            return this.parent.getStaticField(name);
        }
        
        return null;
    }

    /**
     * Set static field value
     */
    public function setStaticField(name:String, value:Dynamic):RuntimeClass {
        var field = this.CLASS.staticFields.get(name);
        if (field != null) {
            field.value = value;
            this.CLASS.staticFields.set(name, field);
        }
        return cast this;
    }

    /**
     * Call static method
     */
    public function callStaticMethod(name:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        var method = this.CLASS.staticMethods.get(name);
        if (method != null) {
            return Reflect.callMethod(null, method.fn, args);
        }
        
        // Check parent class for static method
        if (this.parent != null) {
            return this.parent.callStaticMethod(name, args);
        }
        
        return null;
    }

    /**
     * Get all instances of this class
     */
    public function getInstances():Array<Dynamic> {
        return this.instances.copy();
    }

    /**
     * Get class name
     */
    public function getClassName():String {
        return this.className;
    }

    /**
     * Get parent class
     */
    public function getParent():Null<Classable> {
        return this.parent;
    }

    /**
     * Check if this class extends another class
     */
    public function extendsClass(other:Classable):Bool {
        var current = this.parent;
        while (current != null) {
            if (current.getClassName() == other.getClassName()) {
                return true;
            }
            current = current.getSuperClass();
        }
        return false;
    }

    /**
     * Check if an instance is of this class type
     */
    public function isInstance(obj:Dynamic):Bool {
        return this.instances.indexOf(obj) != -1;
    }

    @:from
    public static function fromClass<T>(cls:Class<T>):RuntimeClass {
        var className = Type.getClassName(cls);
        var runtimeClass = new RuntimeClass(className);
        
        // Get instance fields
        var instanceFields = Type.getInstanceFields(cls);
        for (field in instanceFields) {
            runtimeClass.addField(field, Dynamic, Public);
        }
        
        // Get class fields (static)
        var classFields = Type.getClassFields(cls);
        for (field in classFields) {
            runtimeClass.addField(field, Dynamic, Static);
        }

        // Try to get the constructor function for the class.
        // Haxe does not expose the constructor directly, but we can create a wrapper.
        var constructor:Null<haxe.Constraints.Function> = switch (Type.getClassFields(cls).indexOf("new") != -1) {
            case true:
            // Use Reflect to get the constructor function dynamically.
            cast Reflect.field(cls, "new");
            case false:
            null;
        };
        runtimeClass.setConstructor(constructor);
        

        return runtimeClass;
    }

    @:to
    public function toClassableStructure():ClassableStructure {
        var staticFields = new Map<String, Dynamic>();
        var staticMethods = new Map<String, haxe.Constraints.Function>();
        var instanceFields = new Map<String, Dynamic>();
        var instanceMethods = new Map<String, haxe.Constraints.Function>();
        
        for (field in this.CLASS.staticFields) {
            staticFields.set(field.name, field.value);
        }
        
        for (method in this.CLASS.staticMethods) {
            staticMethods.set(method.name, method.fn);
        }
        
        for (field in this.CLASS.fields) {
            instanceFields.set(field.name, field.value);
        }
        
        for (method in this.CLASS.methods) {
            instanceMethods.set(method.name, method.fn);
        }
        
        return {
            className: this.className,
            isRuntimeClass: true,
            classReference: cast this,
            constructor: this.CLASS.constructor,
            staticFields: staticFields,
            staticMethods: staticMethods,
            instanceFields: instanceFields,
            instanceMethods: instanceMethods,
            superClass: this.parent
        };
    }

    @:to
    public function toClassable():Classable {
        return new Classable(this.toClassableStructure());
    }
}

/**
 * Classable is an abstract that can represent either a native Class or a RuntimeClass.
 * It provides a unified interface for working with both types of classes with full compatibility.
 * This is the main interface for class operations in the runtime system.
 */
abstract Classable(ClassableStructure) {
    public inline function new(structure:ClassableStructure) {
        this = structure;
    }

    /**
     * Create an instance of this class
     */
    public function createInstance(?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        if (this.isRuntimeClass) {
            var runtimeClass:RuntimeClass = cast this.classReference;
            return runtimeClass.createInstance(args);
        } else {
            // Native class - handle inheritance properly
            var cls:Class<Dynamic> = cast this.classReference;
            var instance = Type.createInstance(cls, args);
            
            // For native classes, we need to set up the inheritance chain if there's a super class
            if (this.superClass != null && this.superClass.isRuntimeClass()) {
                var superInstance = this.superClass.createInstance(args);
                for (field in Reflect.fields(superInstance)) {
                    if (!Reflect.hasField(instance, field)) {
                        Reflect.setField(instance, field, Reflect.field(superInstance, field));
                    }
                }
            }
            
            return instance;
        }
    }

    /**
     * Get class name
     */
    public function getClassName():String {
        return this.className;
    }

    /**
     * Check if this is a runtime class
     */
    public function isRuntimeClass():Bool {
        return this.isRuntimeClass;
    }

    /**
     * Get the underlying class reference
     */
    public function getClassReference():Dynamic {
        return this.classReference;
    }

    /**
     * Get super class
     */
    public function getSuperClass():Null<Classable> {
        return this.superClass;
    }

    /**
     * Check if this class extends another class
     */
    public function extendsClass(other:Classable):Bool {
        var current = this.superClass;
        while (current != null) {
            if (current.getClassName() == other.getClassName()) {
                return true;
            }
            current = current.getSuperClass();
        }
        return false;
    }

    /**
     * Check if an object is an instance of this class
     */
    public function isInstance(obj:Dynamic):Bool {
        if (this.isRuntimeClass) {
            var runtimeClass:RuntimeClass = cast this.classReference;
            return runtimeClass.isInstance(obj);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            return Std.isOfType(obj, cls);
        }
    }

    /**
     * Call static method
     */
    public function callStaticMethod(name:String, ?args:Array<Dynamic>):Dynamic {
        if (args == null) args = [];
        
        if (this.isRuntimeClass) {
            var runtimeClass:RuntimeClass = cast this.classReference;
            return runtimeClass.callStaticMethod(name, args);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            var method = Reflect.field(cls, name);
            if (method != null && Reflect.isFunction(method)) {
                return Reflect.callMethod(cls, method, args);
            }
            
            // Check superclass for static method
            if (this.superClass != null) {
                return this.superClass.callStaticMethod(name, args);
            }
        }
        return null;
    }

    /**
     * Get static field value
     */
    public function getStaticField(name:String):Dynamic {
        if (this.isRuntimeClass) {
            var runtimeClass:RuntimeClass = cast this.classReference;
            return runtimeClass.getStaticField(name);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            var value = Reflect.field(cls, name);
            if (value != null) {
                return value;
            }
            
            // Check superclass for static field
            if (this.superClass != null) {
                return this.superClass.getStaticField(name);
            }
        }
        return null;
    }

    /**
     * Set static field value
     */
    public function setStaticField(name:String, value:Dynamic):Classable {
        if (this.isRuntimeClass) {
            var runtimeClass:RuntimeClass = cast this.classReference;
            runtimeClass.setStaticField(name, value);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            Reflect.setField(cls, name, value);
        }
        return cast this;
    }

    /**
     * Get instance field names
     */
    public function getInstanceFields():Array<String> {
        if (this.isRuntimeClass) {
            return [for (name in this.instanceFields.keys()) name];
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            return Type.getInstanceFields(cls);
        }
    }

    /**
     * Get static field names
     */
    public function getStaticFields():Array<String> {
        if (this.isRuntimeClass) {
            return [for (name in this.staticFields.keys()) name];
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            return Type.getClassFields(cls);
        }
    }

    /**
     * Create a new class that extends this one (works for both native and runtime classes)
     */
    public function createSubclass(className:String):RuntimeClass {
        return new RuntimeClass(className, cast this);
    }

    /**
     * Get all methods of this class (both static and instance)
     */
    public function getAllMethods():Array<String> {
        var methods = [];
        
        if (this.isRuntimeClass) {
            methods = methods.concat([for (name in this.staticMethods.keys()) name]);
            methods = methods.concat([for (name in this.instanceMethods.keys()) name]);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            methods = methods.concat(Type.getClassFields(cls).filter(function(field) {
                return Reflect.isFunction(Reflect.field(cls, field));
            }));
            methods = methods.concat(Type.getInstanceFields(cls));
        }
        
        return methods;
    }

    /**
     * Get all fields of this class (both static and instance)
     */
    public function getAllFields():Array<String> {
        var fields = [];
        
        if (this.isRuntimeClass) {
            fields = fields.concat([for (name in this.staticFields.keys()) name]);
            fields = fields.concat([for (name in this.instanceFields.keys()) name]);
        } else {
            var cls:Class<Dynamic> = cast this.classReference;
            fields = fields.concat(Type.getClassFields(cls).filter(function(field) {
                return !Reflect.isFunction(Reflect.field(cls, field));
            }));
            // Instance fields for native classes are harder to get at runtime
            fields = fields.concat(Type.getInstanceFields(cls));
        }
        
        return fields;
    }

    /**
     * Check if a class (native or runtime) extends another class
     */
    public static function classExtends(child:Classable, parent:Classable):Bool {
        return child.extendsClass(parent);
    }

    /**
     * Check if an object is an instance of a class (native or runtime)
     */
    public static function isInstanceOf(obj:Dynamic, cls:Classable):Bool {
        return cls.isInstance(obj);
    }

    /**
     * Get the inheritance chain of a class
     */
    public static function getInheritanceChain(cls:Classable):Array<Classable> {
        var chain = [cls];
        var current = cls.getSuperClass();
        while (current != null) {
            chain.push(current);
            current = current.getSuperClass();
        }
        return chain;
    }

    /**
     * Create a RuntimeClass that mimics an existing class structure
     */
    public static function cloneClassStructure(sourceClass:Classable, newClassName:String):RuntimeClass {
        var runtimeClass = new RuntimeClass(newClassName, sourceClass.getSuperClass());
        
        // Copy instance fields
        for (field in sourceClass.getInstanceFields()) {
            runtimeClass.addField(field, Dynamic, Public, null);
        }
        
        // Copy static fields
        for (field in sourceClass.getStaticFields()) {
            var value = sourceClass.getStaticField(field);
            if (Reflect.isFunction(value)) {
                runtimeClass.addMethod(field, value, Static);
            } else {
                runtimeClass.addField(field, Dynamic, Static, value);
            }
        }
        
        return runtimeClass;
    }

    /**
     * Create a RuntimeClass that extends a native class easily
     */
    public static function extendNativeClass<T>(cls:Class<T>, newClassName:String):RuntimeClass {
        var classable:Classable = cls;
        return new RuntimeClass(newClassName, classable);
    }

    /**
     * Create a mixed inheritance chain (native -> runtime -> runtime)
     */
    public static function createMixedInheritance(nativeClass:Class<Dynamic>, runtimeClassName:String):RuntimeClass {
        var baseClassable:Classable = nativeClass;
        return new RuntimeClass(runtimeClassName, baseClassable);
    }

    /**
     * Batch create multiple RuntimeClasses with a common parent
     */
    public static function createClassFamily(parent:Classable, classNames:Array<String>):Array<RuntimeClass> {
        return classNames.map(function(name) {
            return new RuntimeClass(name, parent);
        });
    }

    /**
     * Create a RuntimeClass from a JSON-like class definition
     */
    public static function createFromDefinition(definition:Dynamic):RuntimeClass {
        var className = definition.className != null ? definition.className : "GeneratedClass";
        var parent:Classable = definition.parent != null ? toClassable(definition.parent) : null;
        
        var runtimeClass = new RuntimeClass(className, parent);
        
        // Add fields
        if (definition.fields != null) {
            for (field in Reflect.fields(definition.fields)) {
                var fieldData = Reflect.field(definition.fields, field);
                var visibility = fieldData.visibility != null ? fieldData.visibility : Public;
                var defaultValue = fieldData.defaultValue;
                runtimeClass.addField(field, fieldData.type, visibility, defaultValue);
            }
        }
        
        // Add methods
        if (definition.methods != null) {
            for (method in Reflect.fields(definition.methods)) {
                var methodData = Reflect.field(definition.methods, method);
                var visibility = methodData.visibility != null ? methodData.visibility : Public;
                runtimeClass.addMethod(method, methodData.fn, visibility);
            }
        }
        
        // Add static fields
        if (definition.staticFields != null) {
            for (field in Reflect.fields(definition.staticFields)) {
                var fieldData = Reflect.field(definition.staticFields, field);
                var defaultValue = fieldData.defaultValue != null ? fieldData.defaultValue : fieldData;
                runtimeClass.addField(field, fieldData.type != null ? fieldData.type : Dynamic, Static, defaultValue);
            }
        }
        
        // Add static methods
        if (definition.staticMethods != null) {
            for (method in Reflect.fields(definition.staticMethods)) {
                var methodFn = Reflect.field(definition.staticMethods, method);
                runtimeClass.addMethod(method, methodFn, Static);
            }
        }
        
        // Set constructor
        if (definition.constructor != null) {
            runtimeClass.setConstructor(definition.constructor);
        }
        
        return runtimeClass;
    }
}

/**
 * Helper class for working with RuntimeClass and Classable
 */
class ClassUtils {
    /**
     * Create a RuntimeClass with a fluent API
     */
    public static function createRuntimeClass(className:String, ?parent:Classable):RuntimeClassBuilder {
        return new RuntimeClassBuilder(className, parent);
    }

    /**
     * Convert any class-like object to Classable
     */
    public static function toClassable(value:Dynamic):Classable {
        if (Std.isOfType(value, Class)) {
            return Classable.fromClass(value);
        } else if (Std.isOfType(value, RuntimeClass)) {
            return Classable.fromRuntimeClass(value);
        } else if (Reflect.hasField(value, "className") && Reflect.hasField(value, "isRuntimeClass")) {
            return Classable.fromStructure(value);
        } else {
            throw 'Cannot convert value to Classable: ' + Std.string(value);
        }
    }

    /**
     * Convert an anonymous structure to a RuntimeClass
     * All fields are considered public instance fields
     */
    public static function structureToRuntimeClass(structure:Dynamic, className:String = "AnonymousClass", ?parent:Classable):RuntimeClass {
        var runtimeClass = new RuntimeClass(className, parent);
        
        // Add all fields from the structure as public instance fields
        for (field in Reflect.fields(structure)) {
            var value = Reflect.field(structure, field);
            if (Reflect.isFunction(value)) {
                runtimeClass.addMethod(field, value, Public);
            } else {
                runtimeClass.addField(field, Dynamic, Public, value);
            }
        }
        
        return runtimeClass;
    }

    /**
     * Convert an anonymous structure to a Classable
     * All fields are considered public instance fields
     */
    public static function structureToClassable(structure:Dynamic, className:String = "AnonymousClass", ?parent:Classable):Classable {
        return structureToRuntimeClass(structure, className, parent).toClassable();
    }

    /**
     * Create a RuntimeClass from a structure with more control over field visibility
     */
    public static function structureToRuntimeClassAdvanced(structure:Dynamic, className:String = "AnonymousClass", ?parent:Classable, ?fieldVisibility:RuntimeClassFieldVisibility):RuntimeClass {
        if (fieldVisibility == null) fieldVisibility = Public;
        
        var runtimeClass = new RuntimeClass(className, parent);
        
        // Add all fields from the structure
        for (field in Reflect.fields(structure)) {
            var value = Reflect.field(structure, field);
            if (Reflect.isFunction(value)) {
                runtimeClass.addMethod(field, value, fieldVisibility);
            } else {
                runtimeClass.addField(field, Dynamic, fieldVisibility, value);
            }
        }
        
        return runtimeClass;
    }

    /**
     * Create a RuntimeClass that can extend both native classes and other RuntimeClasses
     */
    public static function createExtendedRuntimeClass(className:String, parent:Classable):RuntimeClass {
        return new RuntimeClass(className, parent);
    }

    /**
     * Example usage of RuntimeClass and Classable
     */
    // public static function example():Void {
    //     // Create a simple RuntimeClass
    //     var personClass = ClassUtils.createRuntimeClass("Person")
    //         .addField("name", String, Public, "Unknown")
    //         .addField("age", Int, Public, 0)
    //         .addMethod("greet", function() {
    //             return "Hello, I'm " + Reflect.field(this, "name");
    //         }, Public)
    //         .addStaticField("species", String, "Homo sapiens")
    //         .addStaticMethod("getSpecies", function() {
    //             return "Homo sapiens";
    //         })
    //         .setConstructor(function(name:String, age:Int) {
    //             Reflect.setField(this, "name", name);
    //             Reflect.setField(this, "age", age);
    //         })
    //         .build();

    //     // Create an instance
    //     var person = personClass.createInstance(["Alice", 25]);
    //     trace("Person name: " + Reflect.field(person, "name"));
    //     trace("Person greeting: " + Reflect.callMethod(person, Reflect.field(person, "greet"), []));

    //     // Access static members
    //     trace("Species: " + personClass.getStaticField("species"));
    //     trace("Static method: " + personClass.callStaticMethod("getSpecies"));

    //     // Convert to Classable
    //     var classable:Classable = personClass;
    //     var anotherPerson = classable.createInstance(["Bob", 30]);
    //     trace("Another person: " + Reflect.field(anotherPerson, "name"));

    //     // Create inheritance example - extending a RuntimeClass
    //     var studentClass = ClassUtils.createRuntimeClass("Student", personClass.toClassable())
    //         .addField("studentId", String, Public, "")
    //         .addMethod("study", function() {
    //             return Reflect.field(this, "name") + " is studying";
    //         }, Public)
    //         .setConstructor(function(name:String, age:Int, studentId:String) {
    //             Reflect.setField(this, "name", name);
    //             Reflect.setField(this, "age", age);
    //             Reflect.setField(this, "studentId", studentId);
    //         })
    //         .build();

    //     var student = studentClass.createInstance(["Charlie", 20, "S001"]);
    //     trace("Student: " + Reflect.field(student, "name") + ", ID: " + Reflect.field(student, "studentId"));
    //     trace("Student studying: " + Reflect.callMethod(student, Reflect.field(student, "study"), []));
    //     trace("Student greeting: " + Reflect.callMethod(student, Reflect.field(student, "greet"), [])); // Inherited method

    //     // Create a RuntimeClass from anonymous structure
    //     var structure = {
    //         x: 10,
    //         y: 20,
    //         move: function(dx:Int, dy:Int) {
    //             this.x += dx;
    //             this.y += dy;
    //         }
    //     };
    //     var pointClass = ClassUtils.structureToRuntimeClass(structure, "Point");
    //     var point = pointClass.createInstance();
    //     trace("Point: " + Reflect.field(point, "x") + ", " + Reflect.field(point, "y"));

    //     // Extend native class with RuntimeClass
    //     var stringExtended = ClassUtils.createRuntimeClass("ExtendedString", String)
    //         .addMethod("repeat", function(times:Int) {
    //             var result = "";
    //             for (i in 0...times) {
    //                 result += this;
    //             }
    //             return result;
    //         })
    //         .build();
    //     // Usage would require proper setup of the inheritance chain
    // }
}

/**
 * Builder class for creating RuntimeClass instances with a fluent API
 */
class RuntimeClassBuilder {
    private var runtimeClass:RuntimeClass;

    public function new(className:String, ?parent:Classable) {
        this.runtimeClass = new RuntimeClass(className, parent);
    }

    public function addField(name:String, type:Dynamic, visibility:RuntimeClassFieldVisibility = Public, ?defaultValue:Dynamic):RuntimeClassBuilder {
        this.runtimeClass.addField(name, type, visibility, defaultValue);
        return this;
    }

    public function addMethod(name:String, fn:haxe.Constraints.Function, visibility:RuntimeClassFieldVisibility = Public):RuntimeClassBuilder {
        this.runtimeClass.addMethod(name, fn, visibility);
        return this;
    }

    public function addStaticField(name:String, type:Dynamic, ?defaultValue:Dynamic):RuntimeClassBuilder {
        this.runtimeClass.addField(name, type, Static, defaultValue);
        return this;
    }

    public function addStaticMethod(name:String, fn:haxe.Constraints.Function):RuntimeClassBuilder {
        this.runtimeClass.addMethod(name, fn, Static);
        return this;
    }

    public function setConstructor(fn:haxe.Constraints.Function):RuntimeClassBuilder {
        this.runtimeClass.setConstructor(fn);
        return this;
    }

    public function build():RuntimeClass {
        return this.runtimeClass;
    }

    public function buildAsClassable():Classable {
        return this.runtimeClass.toClassable();
    }
}

// Example usage of RuntimeClass and Classable
/*
// Create a RuntimeClass
var myClass = ClassUtils.createRuntimeClass("MyClass")
    .addField("value", Int, Public, 0)
    .addMethod("getValue", function() { return Reflect.field(this, "value"); })
    .setConstructor(function(val:Int) { Reflect.setField(this, "value", val); })
    .build();

// Create instances
var instance1 = myClass.createInstance([42]);
var instance2 = myClass.createInstance([100]);

// Use as Classable
var classable:Classable = myClass;
var instance3 = classable.createInstance([200]);

// Native class to Classable
var stringClassable:Classable = String;
var stringInstance = stringClassable.createInstance(["Hello"]);
*/

/*
COMPREHENSIVE USAGE EXAMPLES:

1. Creating RuntimeClasses:
var personClass = ClassUtils.createRuntimeClass("Person")
    .addField("name", String, Public, "Unknown")
    .addField("age", Int, Public, 0)
    .addMethod("greet", function() {
        return "Hello, I'm " + Reflect.field(this, "name");
    }, Public)
    .addStaticField("species", String, "Homo sapiens")
    .addStaticMethod("getSpecies", function() {
        return "Homo sapiens";
    })
    .setConstructor(function(name:String, age:Int) {
        Reflect.setField(this, "name", name);
        Reflect.setField(this, "age", age);
    })
    .build();

2. Converting anonymous structures to classes:
var structure = {
    x: 10,
    y: 20,
    move: function(dx:Int, dy:Int) {
        this.x += dx;
        this.y += dy;
    }
};
var pointClass = ClassUtils.structureToRuntimeClass(structure, "Point");
var point = pointClass.createInstance();

3. Extending native classes with RuntimeClasses:
var stringClassable:Classable = String; // Convert native class to Classable
var extendedString = ClassUtils.createRuntimeClass("ExtendedString", stringClassable)
    .addMethod("repeat", function(times:Int) {
        var result = "";
        for (i in 0...times) {
            result += this;
        }
        return result;
    })
    .build();

4. RuntimeClass extending RuntimeClass:
var studentClass = ClassUtils.createRuntimeClass("Student", personClass.toClassable())
    .addField("studentId", String, Public, "")
    .addMethod("study", function() {
        return Reflect.field(this, "name") + " is studying";
    }, Public)
    .setConstructor(function(name:String, age:Int, studentId:String) {
        Reflect.setField(this, "name", name);
        Reflect.setField(this, "age", age);
        Reflect.setField(this, "studentId", studentId);
    })
    .build();

5. Full inheritance compatibility:
var student = studentClass.createInstance(["Alice", 20, "S001"]);
trace(student.greet()); // Inherited method from PersonClass
trace(student.study()); // Own method
trace(studentClass.extendsClass(personClass.toClassable())); // true

6. Working with Classable for unified interface:
var classable:Classable = personClass; // Can be either native or runtime class
var person = classable.createInstance(["Bob", 30]);
trace(classable.getClassName()); // "Person"
trace(classable.isRuntimeClass()); // true

7. Type checking and instance validation:
trace(personClass.isInstance(person)); // true
trace(ClassUtils.isInstanceOf(person, personClass.toClassable())); // true
trace(ClassUtils.classExtends(studentClass.toClassable(), personClass.toClassable())); // true

8. Advanced structure conversion:
var advancedStructure = {
    value: 42,
    getValue: function() { return this.value; },
    setValue: function(v) { this.value = v; }
};
var advancedClass = ClassUtils.structureToRuntimeClassAdvanced(
    advancedStructure, 
    "AdvancedClass", 
    null, 
    Public
);

This system provides:
- Full compatibility between native classes and RuntimeClasses
- Proper inheritance chains for both types
- Unified interface through Classable
- Easy conversion from anonymous structures to classes
- Type checking and instance validation
- Static and instance member support
- Method and field visibility control
*/