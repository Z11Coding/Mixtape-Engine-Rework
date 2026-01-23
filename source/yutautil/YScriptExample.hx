package yutautil;

import yutautil.YScript;

/**
 * Example usage of the new YScript system
 */
class YScriptExample {
    public static function main() {
        // Create a YScript instance
        var script = new YScript();

        // Simple variable example
        var simpleScript = '
            var message: String = "Hello from YScript!";
            var number: Int = 42;

            function getMessage(): String {
                return message + " The number is: " + number;
            }
        ';

        try {
            // Execute the script
            var result = script.execute(simpleScript);
            trace("Script executed successfully");

            // Call a function from the script
            var functionResult = script.callFunction("getMessage", []);
            trace("Function result: " + functionResult);

            // Get a variable from the script
            var messageValue = script.getVariable("message");
            trace("Message variable: " + messageValue);

            // Set a variable in the script
            script.setVariable("newVar", "This is a new variable", String);
            trace("Set new variable: " + script.getVariable("newVar"));

        } catch (e:Dynamic) {
            trace("Script execution error: " + e);
        }

        // Example with classes
        var classScript = '
            class TestClass {
                var value: Int;

                function new(initialValue: Int) {
                    value = initialValue;
                }

                function getValue(): Int {
                    return value;
                }

                function setValue(newValue: Int): Void {
                    value = newValue;
                }
            }

            var instance = new TestClass(100);
        ';

        try {
            script.execute(classScript);
            trace("Class script executed successfully");
        } catch (e:Dynamic) {
            trace("Class script execution error: " + e);
        }
    }
}
