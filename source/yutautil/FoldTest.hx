package yutautil;

import yutautil.Fold;

/**
 * Test and demonstration file for the Fold type system
 * Now with @:genericBuild support for automatic compile-time validation
 */
class FoldTest {

    // Example typedef
    typedef PersonData = {
        name:String,
        age:Int,
        ?email:String  // Optional field
    };

    // Example interface
    interface Position {
        var x:Float;
        var y:Float;
        @:optional var z:Float;
    }

    public static function testFoldUsage():Void {
        trace("=== Fold Type System Tests (with @:genericBuild) ===");

        // Test 1: Implicit assignment with compile-time validation via @:genericBuild
        var personFold:Fold<PersonData> = {
            name: "John Doe",
            age: 30,
            email: "john@example.com",
            extraField: "This is allowed"  // Extra fields are fine
        };
        trace('Person: ${personFold.name}, Age: ${personFold.age}');

        // Test 2: Another implicit assignment - compile-time validated automatically
        var validatedPerson:Fold<PersonData> = {
            name: "Jane Smith",
            age: 25,
            department: "Engineering"  // Extra field allowed
        };
        trace('Validated Person: ${validatedPerson.name}, Age: ${validatedPerson.age}');

        // Test 3: Anonymous object constraint with @:genericBuild validation
        var posFold:Fold<{x:Float, y:Float}> = {
            x: 10.5,
            y: 20.3,
            extraData: "Additional data"  // Extra fields allowed
        };
        trace('Position: (${posFold.x}, ${posFold.y})');

        // Test 4: Interface compatibility with automatic validation
        var interfaceFold:Fold<Position> = {
            x: 1.0,
            y: 2.0,
            z: 3.0,
            rotation: 45.0  // Extra field
        };
        trace('Interface Position: (${interfaceFold.x}, ${interfaceFold.y}, ${interfaceFold.z})');

        // Test 5: Optional fields work correctly with @:genericBuild
        var personWithoutEmail:Fold<PersonData> = {
            name: "Bob Wilson",
            age: 25
            // email is optional, so this should work
        };
        trace('Person without email: ${personWithoutEmail.name}');

        // Test 6: Nested object constraint with automatic validation
        var nestedFold:Fold<{user:PersonData, settings:{theme:String}}> = {
            user: {
                name: "Admin",
                age: 35,
                email: "admin@example.com"
            },
            settings: {
                theme: "dark",
                customProperty: "allowed"
            },
            metadata: "Extra top-level field"
        };
        trace('Nested: ${nestedFold.user.name}, Theme: ${nestedFold.settings.theme}');

        // Test 7: Using explicit macro validation (still available)
        var explicitFold = Fold.create({
            name: "Explicit User",
            age: 28,
            bonus: "extra"
        });
        trace('Explicit validation: ${explicitFold.name}');

        trace("=== All Fold tests completed ===");
    }

    // Example of a function that accepts Fold parameters
    public static function processPersonData(person:Fold<PersonData>):String {
        return 'Processing ${person.name} (${person.age} years old)';
    }

    // Example of returning Fold types with macro validation
    public static function createValidatedPosition(x:Float, y:Float):Fold<{x:Float, y:Float}> {
        return Fold.create({x: x, y: y, timestamp: Date.now().getTime()});
    }

    // Example with generic function
    public static function validateAndStore<T>(data:Fold<T>):T {
        // The Fold ensures the data has the required structure
        return data.toUnderlying();
    }

    // Demonstrating the power of @:genericBuild validation
    public static function demonstrateValidationMethods():Void {
        trace("=== @:genericBuild Validation Demo ===");

        // All assignments are now compile-time validated automatically!
        var autoValidated:Fold<PersonData> = {
            name: "Auto Validated User",
            age: 30
        };
        trace('Auto-validated fold created: ${autoValidated.name}');

        // Explicit validation still available for complex cases
        var explicitValidated = Fold.create({
            name: "Explicitly Validated User",
            age: 25,
            metadata: "Extra field allowed"
        });
        trace('Explicitly validated fold created: ${explicitValidated.name}');

        trace("=== @:genericBuild validation demo completed ===");
    }
}

// Example compile-time errors that would be caught by @:genericBuild:
/*
class FoldErrorExamples {
    typedef RequiredFields = {
        name:String,
        value:Int
    };

    public static function demonstrateErrors():Void {
        // These would cause compile errors with @:genericBuild - missing required field 'value'
        // var invalid:Fold<RequiredFields> = {name: "Test"};

        // This would cause compile error - wrong type for 'value'
        // var wrongType:Fold<RequiredFields> = {name: "Test", value: "not an int"};

        // This would cause compile error - missing required field 'name'
        // var missingName:Fold<RequiredFields> = {value: 42};
    }
}
*/
