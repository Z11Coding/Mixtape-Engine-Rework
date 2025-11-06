# Patched<T> Type System Documentation

The `Patched<T>` type is a sophisticated runtime patching system for Haxe that allows you to extend existing classes with new fields and methods without modifying the original class definition. It combines runtime flexibility with compile-time safety through macro validation.

## Features

- **Runtime Field Addition**: Add new fields and methods to existing objects at runtime
- **Compile-Time Validation**: Macro system validates field access at compile time
- **Type Safety**: Maintains type safety while allowing dynamic extensions
- **Multiple Extensions**: Support for multiple patch extensions per object
- **Custom Getters/Setters**: Advanced property handling with custom accessor functions
- **Method Patching**: Add new methods with proper `this` binding
- **Introspection**: Query available fields and extensions
- **Error Handling**: Comprehensive error reporting for invalid operations

## Basic Usage

### Creating a Patched Object

```haxe
// Start with any existing object
var myObject = new SomeClass();

// Convert to patched object
var patched:Patched<SomeClass> = myObject;
```

### Adding Extensions

```haxe
// Define fields and methods for the extension
patched.addExtension("MyExtension", [
    {
        name: "newField",
        type: "String",
        isMethod: false,
        defaultValue: "Hello World"
    },
    {
        name: "newMethod",
        type: "Int->String",
        isMethod: true,
        defaultValue: function(x:Int):String {
            return "Result: " + x;
        }
    }
]);
```

### Accessing Patched Fields

```haxe
// Get field values
var fieldValue = patched.getField("newField");

// Set field values
patched.setField("newField", "New Value");

// Call methods
var result = patched.callMethod("newMethod", [42]);

// Array-style access also works
var value = patched["newField"];
patched["newField"] = "Another Value";
```

## Advanced Features

### Custom Getters and Setters

```haxe
patched.addExtension("PropertyExtension", [
    {
        name: "computedProperty",
        type: "String",
        isMethod: false,
        defaultValue: "initial",
        getter: function(currentValue:Dynamic):Dynamic {
            return "Computed: " + currentValue;
        },
        setter: function(currentValue:Dynamic, newValue:Dynamic):Void {
            trace("Setting property from " + currentValue + " to " + newValue);
            // Custom validation or transformation logic here
        }
    }
]);
```

### Multiple Extensions

```haxe
// Add multiple extensions to the same object
patched.addExtension("MathExtension", [
    { name: "multiplier", type: "Float", isMethod: false, defaultValue: 2.0 },
    { name: "multiply", type: "Float->Float", isMethod: true,
      defaultValue: function(x:Float) return x * patched.getField("multiplier") }
]);

patched.addExtension("StringExtension", [
    { name: "prefix", type: "String", isMethod: false, defaultValue: "Result:" },
    { name: "format", type: "String->String", isMethod: true,
      defaultValue: function(s:String) return patched.getField("prefix") + " " + s }
]);
```

### Extension Management

```haxe
// Check if extension exists
if (patched.hasExtension("MyExtension")) {
    // Extension is available
}

// Get all extension names
var extensions = patched.getExtensionNames();

// Remove an extension
patched.removeExtension("MyExtension");
```

### Introspection

```haxe
// Get information about all available fields
var fieldInfo = patched.getFieldInfo();
for (info in fieldInfo) {
    trace('Field: ${info.name} (${info.type}) from ${info.source}');
}
```

## Compile-Time Validation

The Patched type system includes macro-based compile-time validation that checks field access at compilation time:

```haxe
var patched:Patched<SomeClass> = someObject;

// Add known extension
patched.addExtension("TestExt", [
    { name: "validField", type: "String", isMethod: false, defaultValue: "test" }
]);

// This works - accessing known base field
var baseField = patched.getField("existingField");

// This works - accessing known patched field
var patchedField = patched.getField("validField");

// This causes a COMPILE-TIME ERROR - field doesn't exist
var invalid = patched.getField("nonExistentField"); // Error!
```

The macro system:
- Validates field names at compile time
- Provides helpful error messages with available field suggestions
- Maintains type safety while allowing runtime flexibility
- Integrates with Haxe's standard error reporting

## Field Definition Structure

Each field in an extension is defined using the `PatchedField` typedef:

```haxe
typedef PatchedField = {
    name: String,           // Field name
    type: String,           // Type description (for documentation)
    isMethod: Bool,         // Whether this is a method or property
    ?defaultValue: Dynamic, // Initial value or function
    ?getter: Dynamic->Dynamic,                    // Custom getter function
    ?setter: Dynamic->Dynamic->Void               // Custom setter function
}
```

### Field Types

- **Properties**: `isMethod: false` - Store and retrieve values
- **Methods**: `isMethod: true` - Executable functions with arguments
- **Computed Properties**: Properties with custom getters/setters
- **Hybrid Fields**: Can act as both property and method depending on usage

## Error Handling

The system provides comprehensive error handling:

```haxe
try {
    patched.getField("nonExistentField");
} catch (e:Dynamic) {
    trace("Field not found: " + e);
}

try {
    patched.callMethod("notAMethod", []);
} catch (e:Dynamic) {
    trace("Method call failed: " + e);
}
```

Common error scenarios:
- Accessing non-existent fields
- Calling non-existent methods
- Calling properties as methods
- Setting read-only computed properties

## Integration with Existing Code

The Patched type integrates seamlessly with existing Haxe code:

```haxe
// Can be used with any existing class
class MyClass {
    public var originalField:String = "original";
    public function originalMethod():String return "original method";
    public function new() {}
}

var obj = new MyClass();
var patched:Patched<MyClass> = obj;

// Original functionality still works
trace(patched.getField("originalField"));     // "original"
trace(patched.callMethod("originalMethod", [])); // "original method"

// Plus new patched functionality
patched.addExtension("Enhancement", [...]);
```

## Performance Considerations

- **Runtime Overhead**: Field access goes through reflection, so there's some overhead compared to direct access
- **Memory Usage**: Each patched object stores extension data and field mappings
- **Compile-Time Benefits**: Macro validation catches errors early, reducing runtime debugging
- **Lazy Loading**: Extensions are only created when needed

## Best Practices

1. **Use Descriptive Extension Names**: Makes debugging and introspection easier
2. **Group Related Fields**: Put related fields and methods in the same extension
3. **Validate Input**: Use custom setters to validate field values
4. **Document Field Types**: Use meaningful type descriptions in field definitions
5. **Handle Errors Gracefully**: Always wrap field access in try-catch for production code
6. **Clean Up Extensions**: Remove unused extensions to save memory

## Use Cases

- **Plugin Systems**: Add functionality to objects without modifying base classes
- **Runtime Configuration**: Add configuration fields based on runtime conditions
- **API Extensions**: Extend objects received from external APIs
- **Testing**: Add test-specific methods to objects during testing
- **Dynamic UIs**: Add UI-specific properties to data objects
- **Backwards Compatibility**: Add new features while maintaining old interfaces

## Limitations

- **Performance**: Slightly slower than direct field access
- **Serialization**: Patched fields may not serialize automatically
- **Type Information**: Limited compile-time type checking for patched fields
- **Reflection Dependency**: Relies on Haxe reflection system

## Example: Complete Usage Pattern

```haxe
// Define base class
class GameEntity {
    public var name:String;
    public var health:Int;

    public function new(name:String) {
        this.name = name;
        this.health = 100;
    }

    public function takeDamage(amount:Int):Void {
        health -= amount;
    }
}

// Create and patch
var player = new GameEntity("Player");
var patchedPlayer:Patched<GameEntity> = player;

// Add RPG stats extension
patchedPlayer.addExtension("RPGStats", [
    { name: "level", type: "Int", isMethod: false, defaultValue: 1 },
    { name: "experience", type: "Int", isMethod: false, defaultValue: 0 },
    { name: "levelUp", type: "Void->Void", isMethod: true,
      defaultValue: function():Void {
          var currentLevel = patchedPlayer.getField("level");
          patchedPlayer.setField("level", currentLevel + 1);
          patchedPlayer.setField("experience", 0);
          trace("Level up! Now level " + patchedPlayer.getField("level"));
      }
    }
]);

// Add inventory extension
patchedPlayer.addExtension("Inventory", [
    { name: "items", type: "Array<String>", isMethod: false, defaultValue: [] },
    { name: "addItem", type: "String->Void", isMethod: true,
      defaultValue: function(item:String):Void {
          var items:Array<String> = patchedPlayer.getField("items");
          items.push(item);
          trace("Added " + item + " to inventory");
      }
    }
]);

// Use both original and patched functionality
patchedPlayer.takeDamage(25); // Original method
patchedPlayer.setField("experience", 1000); // Patched field
patchedPlayer.callMethod("levelUp", []); // Patched method
patchedPlayer.callMethod("addItem", ["Sword"]); // Another patched method

trace("Player: " + patchedPlayer.getField("name") +
      ", Level: " + patchedPlayer.getField("level") +
      ", Health: " + patchedPlayer.getField("health"));
```

This creates a powerful and flexible system for extending objects at runtime while maintaining compile-time safety and type checking.
