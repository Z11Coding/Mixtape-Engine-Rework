package yutautil;

/**
 * Simple test to verify the Patched<T> type system works correctly.
 * This can be run to test the runtime patching functionality.
 */
class PatchedTest {
    public static function main():Void {
        trace("Testing Patched<T> Type System");
        trace("================================");

        // Run the comprehensive examples
        PatchedExample.runAllExamples();

        // Quick smoke test
        quickTest();
    }

    static function quickTest():Void {
        trace("\\n=== Quick Smoke Test ===");

        // Create a simple object
        var obj = { name: "TestObject", value: 42 };
        var patched:Patched<Dynamic> = obj;

        // Add a simple extension
        patched.addExtension("QuickExt", [
            {
                name: "doubled",
                type: "Int",
                isMethod: false,
                defaultValue: 84
            },
            {
                name: "getInfo",
                type: "Void->String",
                isMethod: true,
                defaultValue: function():String {
                    var name = patched.getField("name");
                    var value = patched.getField("value");
                    var doubled = patched.getField("doubled");
                    return 'Object: $name, Value: $value, Doubled: $doubled';
                }
            }
        ]);

        // Test basic functionality
        trace('Original name: ${patched.getField("name")}');
        trace('Original value: ${patched.getField("value")}');
        trace('Patched doubled: ${patched.getField("doubled")}');
        trace('Info method: ${patched.callMethod("getInfo", [])}');

        // Modify values
        patched.setField("doubled", 168);
        trace('Modified info: ${patched.callMethod("getInfo", [])}');

        trace("Quick test completed successfully!");
    }
}
