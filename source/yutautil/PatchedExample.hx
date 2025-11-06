package yutautil;

/**
 * Example and test file demonstrating the Patched<T> type system.
 * Shows how to use runtime patching to extend classes with new fields and methods.
 */

// Example base class to patch
class ExampleClass {
    public var baseField:String = "base";
    public var number:Int = 42;

    public function new() {}

    public function baseMethod():String {
        return "Hello from base class";
    }

    public function calculate(x:Int):Int {
        return x * 2;
    }
}

// Another example class
class TestTarget {
    public var name:String;
    public var value:Float;

    public function new(name:String, value:Float) {
        this.name = name;
        this.value = value;
    }

    public function getValue():Float {
        return value;
    }
}

class PatchedExample {
    /**
     * Demonstrates basic patching functionality.
     */
    public static function basicExample():Void {
        trace("=== Basic Patching Example ===");

        // Create a base object
        var obj = new ExampleClass();
        trace('Base field: ${obj.baseField}');
        trace('Base method: ${obj.baseMethod()}');

        // Convert to patched object
        var patched:Patched<ExampleClass> = obj;

        // Add an extension with new fields and methods
        patched.addExtension("MyExtension", [
            {
                name: "newField",
                type: "String",
                isMethod: false,
                defaultValue: "Hello from patch!"
            },
            {
                name: "patchedNumber",
                type: "Int",
                isMethod: false,
                defaultValue: 100
            },
            {
                name: "patchedMethod",
                type: "Void->String",
                isMethod: true,
                defaultValue: function():String {
                    return "Hello from patched method!";
                }
            },
            {
                name: "advancedMethod",
                type: "Int->String",
                isMethod: true,
                defaultValue: function(x:Int):String {
                    return "Processed: " + (x * 3);
                }
            }
        ]);

        // Access patched fields (this would have compile-time validation)
        trace('Patched field: ${patched.getField("newField")}');
        trace('Patched number: ${patched.getField("patchedNumber")}');

        // Call patched methods
        trace('Patched method: ${patched.callMethod("patchedMethod", [])}');
        trace('Advanced method: ${patched.callMethod("advancedMethod", [10])}');

        // Still can access base fields/methods
        trace('Still has base field: ${patched.getField("baseField")}');
        trace('Base calculate method: ${patched.callMethod("calculate", [5])}');

        // Set patched field values
        patched.setField("newField", "Modified patch field!");
        patched.setField("patchedNumber", 200);

        trace('Modified patched field: ${patched.getField("newField")}');
        trace('Modified patched number: ${patched.getField("patchedNumber")}');
    }

    /**
     * Demonstrates multiple extensions on the same object.
     */
    public static function multipleExtensionsExample():Void {
        trace("\\n=== Multiple Extensions Example ===");

        var target = new TestTarget("TestObject", 3.14);
        var patched:Patched<TestTarget> = target;

        // Add first extension - mathematical operations
        patched.addExtension("MathExtension", [
            {
                name: "multiplier",
                type: "Float",
                isMethod: false,
                defaultValue: 2.0
            },
            {
                name: "multiply",
                type: "Float->Float",
                isMethod: true,
                defaultValue: function(x:Float):Float {
                    var mult = patched.getField("multiplier");
                    return x * mult;
                }
            },
            {
                name: "square",
                type: "Void->Float",
                isMethod: true,
                defaultValue: function():Float {
                    var val = patched.getField("value");
                    return val * val;
                }
            }
        ]);

        // Add second extension - string operations
        patched.addExtension("StringExtension", [
            {
                name: "prefix",
                type: "String",
                isMethod: false,
                defaultValue: "Object:"
            },
            {
                name: "getDisplayName",
                type: "Void->String",
                isMethod: true,
                defaultValue: function():String {
                    var prefix = patched.getField("prefix");
                    var name = patched.getField("name");
                    return prefix + " " + name;
                }
            },
            {
                name: "describe",
                type: "Void->String",
                isMethod: true,
                defaultValue: function():String {
                    var displayName = patched.callMethod("getDisplayName", []);
                    var value = patched.getField("value");
                    return displayName + " (value: " + value + ")";
                }
            }
        ]);

        // Use both extensions
        trace('Display name: ${patched.callMethod("getDisplayName", [])}');
        trace('Description: ${patched.callMethod("describe", [])}');
        trace('Original value: ${patched.getField("value")}');
        trace('Squared value: ${patched.callMethod("square", [])}');
        trace('Multiplied value: ${patched.callMethod("multiply", [5.0])}');

        // Modify extension fields
        patched.setField("prefix", "Enhanced Object:");
        patched.setField("multiplier", 3.0);

        trace('Modified display name: ${patched.callMethod("getDisplayName", [])}');
        trace('Modified multiplication: ${patched.callMethod("multiply", [5.0])}');

        // List all extensions
        trace('Active extensions: ${patched.getExtensionNames().join(", ")}');
    }

    /**
     * Demonstrates advanced patching with getters and setters.
     */
    public static function advancedPatchingExample():Void {
        trace("\\n=== Advanced Patching Example ===");

        var obj = new ExampleClass();
        var patched:Patched<ExampleClass> = obj;

        // Add extension with custom getter/setter
        patched.addExtension("PropertyExtension", [
            {
                name: "computedProperty",
                type: "String",
                isMethod: false,
                defaultValue: "initial",
                getter: function(currentValue:Dynamic):Dynamic {
                    trace("Getting computedProperty, current value: " + currentValue);
                    return "Computed: " + currentValue;
                },
                setter: function(currentValue:Dynamic, newValue:Dynamic):Void {
                    trace("Setting computedProperty from " + currentValue + " to " + newValue);
                    // Custom setter logic could go here
                }
            },
            {
                name: "counter",
                type: "Int",
                isMethod: false,
                defaultValue: 0
            },
            {
                name: "increment",
                type: "Void->Int",
                isMethod: true,
                defaultValue: function():Int {
                    var current = patched.getField("counter");
                    var newValue = current + 1;
                    patched.setField("counter", newValue);
                    return newValue;
                }
            }
        ]);

        // Test getter/setter
        trace('Initial computed property: ${patched.getField("computedProperty")}');
        patched.setField("computedProperty", "modified");
        trace('After setting: ${patched.getField("computedProperty")}');

        // Test counter
        trace('Initial counter: ${patched.getField("counter")}');
        trace('After increment: ${patched.callMethod("increment", [])}');
        trace('After increment: ${patched.callMethod("increment", [])}');
        trace('Counter value: ${patched.getField("counter")}');
    }

    /**
     * Demonstrates field information and introspection.
     */
    public static function introspectionExample():Void {
        trace("\\n=== Introspection Example ===");

        var obj = new ExampleClass();
        var patched:Patched<ExampleClass> = obj;

        // Add some extensions
        patched.addExtension("Extension1", [
            { name: "field1", type: "String", isMethod: false, defaultValue: "value1" },
            { name: "method1", type: "Void->String", isMethod: true, defaultValue: function() return "result1" }
        ]);

        patched.addExtension("Extension2", [
            { name: "field2", type: "Int", isMethod: false, defaultValue: 42 },
            { name: "method2", type: "Int->Int", isMethod: true, defaultValue: function(x) return x * 2 }
        ]);

        // Get field information
        var fieldInfo = patched.getFieldInfo();
        trace("All available fields:");
        for (info in fieldInfo) {
            trace('  - ${info.name} (${info.type}) from ${info.source}');
        }

        // Extension management
        trace('\\nExtension management:');
        trace('Has Extension1: ${patched.hasExtension("Extension1")}');
        trace('Has Extension3: ${patched.hasExtension("Extension3")}');
        trace('All extensions: ${patched.getExtensionNames().join(", ")}');

        // Remove an extension
        patched.removeExtension("Extension1");
        trace('After removing Extension1: ${patched.getExtensionNames().join(", ")}');

        // Try to access removed field (this would cause a runtime error)
        try {
            patched.getField("field1");
        } catch (e:Dynamic) {
            trace('Expected error accessing removed field: $e');
        }
    }

    /**
     * Demonstrates error handling and validation.
     */
    public static function errorHandlingExample():Void {
        trace("\\n=== Error Handling Example ===");

        var obj = new ExampleClass();
        var patched:Patched<ExampleClass> = obj;

        // Try to access non-existent field
        try {
            patched.getField("nonExistentField");
        } catch (e:Dynamic) {
            trace('Error accessing non-existent field: $e');
        }

        // Try to call non-existent method
        try {
            patched.callMethod("nonExistentMethod", []);
        } catch (e:Dynamic) {
            trace('Error calling non-existent method: $e');
        }

        // Try to set non-existent field
        try {
            patched.setField("nonExistentField", "value");
        } catch (e:Dynamic) {
            trace('Error setting non-existent field: $e');
        }

        // Add extension and then try invalid operations
        patched.addExtension("TestExtension", [
            { name: "testField", type: "String", isMethod: false, defaultValue: "test" },
            { name: "testMethod", type: "Void->String", isMethod: true, defaultValue: function() return "test result" }
        ]);

        // Valid operations
        trace('Valid field access: ${patched.getField("testField")}');
        trace('Valid method call: ${patched.callMethod("testMethod", [])}');

        // Invalid method call (calling field as method)
        try {
            patched.callMethod("testField", []);
        } catch (e:Dynamic) {
            trace('Error calling field as method: $e');
        }
    }

    /**
     * Run all examples.
     */
    public static function runAllExamples():Void {
        trace("Running Patched<T> Examples\\n");

        basicExample();
        multipleExtensionsExample();
        advancedPatchingExample();
        introspectionExample();
        errorHandlingExample();

        trace("\\n=== All Examples Complete ===");
    }
}

/**
 * Helper class for testing compile-time validation.
 * Uncomment the lines below to test macro validation errors.
 */
class CompileTimeValidationTest {
    public static function testValidation():Void {
        var obj = new ExampleClass();
        var patched:Patched<ExampleClass> = obj;

        // Add a known extension
        patched.addExtension("TestExt", [
            { name: "validField", type: "String", isMethod: false, defaultValue: "test" }
        ]);

        // This should work (accessing known base field)
        var baseField = patched.getField("baseField");

        // This should work (accessing known patched field)
        var patchedField = patched.getField("validField");

        // Uncomment these lines to test compile-time errors:
        // var invalidField = patched.getField("invalidField"); // Should cause compile error
        // patched.setField("invalidField", "value"); // Should cause compile error
    }
}
