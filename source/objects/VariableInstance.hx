package objects;

class VariableInstance {
    public var variables:Map<String, Dynamic>;
    // Static map to hold instances
    private static var instances:Map<String, VariableInstance> = new Map<String, VariableInstance>();

    public function new(autoRegister:Bool = true) {
        variables = new Map<String, Dynamic>();
        if (autoRegister) {
            // Assuming a mechanism to generate a unique name or using a predefined one
            registerInstance(Reflect.callMethod(this, Reflect.field(this, "generateUniqueName"), []), this);
        }
    }

    // Method to add or update an instance in the holder
    public static function registerInstance(name:String, instance:VariableInstance):Void {
        instances.set(name, instance);
    }

    // Method to retrieve an instance by name
    public static function getInstance(name:String):VariableInstance {
        return instances.get(name);
    }

    // Optional: Method to remove an instance
    public static function removeInstance(name:String):Void {
        instances.remove(name);
    }

    // New method to copy variables from an anonymous structure or object
    public function copyVariablesFrom(obj:Dynamic):Void {
        for (field in Reflect.fields(obj)) {
            var value = Reflect.field(obj, field);
            variables.set(field, value);
        }
    }

    // Placeholder for a method to generate a unique name for auto-registration
    private function generateUniqueName():String {
        // Implementation depends on requirements, e.g., using a static counter or UUID
        return "UniqueName"; // Simplified for example purposes
    }
}

// Idea bin

// Inside MacroTools.hx
package objects;

import haxe.macro.Expr;
import haxe.macro.Context;

class MacroTools {
    public static macro function registerVariableWithReflection(name:Expr):Expr {
        // Macro logic here
        // pls
    }
}

public static function processVariableInstances():Array<Field> {
    var fields = Context.getBuildFields();
    // Logic... somewhere
    return fields;
}

