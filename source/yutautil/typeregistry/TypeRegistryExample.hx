package yutautil.typeregistry;

import yutautil.typeregistry.TypeRegistryAPI;

/**
 * Example demonstrating the Type Registry System capabilities
 */
class TypeRegistryExample {
    public static function demonstrateSystem():Void {
        trace("=== Type Registry System Demonstration ===");

        // Initialize the system
        TypeRegistryAPI.initialize();

        // === Basic Type Checking ===
        trace("\n1. Basic Type Checking:");

        var intValue = 42;
        var stringValue = "Hello World";
        var boolValue = true;

        // Check specific types
        var intCheck = TypeRegistryAPI.checkType(intValue, "Int");
        trace('  Int 42 as Int: ${intCheck.isValid()}');

        var stringAsInt = TypeRegistryAPI.checkType(stringValue, "Int");
        trace('  String "Hello" as Int: ${stringAsInt.isValid()} (${stringAsInt.getErrors().join(", ")})');

        // === Auto Type Detection ===
        trace("\n2. Auto Type Detection:");

        var detectedTypes = TypeRegistryAPI.detectTypes(intValue);
        trace('  Value 42 could be:');
        for (typed in detectedTypes.slice(0, 3)) { // Show top 3
            trace('    - ${typed.typeName} (${Math.round(typed.validationResult.confidence * 100)}% confidence)');
        }

        // === Object Inspection ===
        trace("\n3. Object Inspection:");

        var inspection = TypeRegistryAPI.inspect(stringValue);
        trace('  String "Hello World":');
        trace('    - Native Type: ${inspection.nativeType}');
        trace('    - Best Match: ${inspection.bestMatch}');
        trace('    - Confidence: ${Math.round(inspection.confidence * 100)}%');

        // === Abstract Recognition ===
        trace("\n4. Abstract Recognition:");

        // This will work better when there are actual abstracts in the compilation
        var abstractCandidates = TypeRegistryAPI.findAbstracts(intValue);
        if (abstractCandidates.length > 0) {
            trace('  Value 42 could be these abstracts:');
            for (candidate in abstractCandidates.slice(0, 3)) {
                trace('    - ${candidate.getTypeName()} (${Math.round(candidate.confidence * 100)}%)');
                if (candidate.reasons.length > 0) {
                    trace('      Reasons: ${candidate.reasons.join(", ")}');
                }
            }
        } else {
            trace('  No abstract candidates found for value 42');
        }

        // === Registry Queries ===
        trace("\n5. Registry Information:");

        var totalTypes = TypeRegistryAPI.getAllTypes().length;
        var totalAbstracts = TypeRegistryAPI.getAllAbstracts().length;
        var totalClasses = TypeRegistryAPI.getAllClasses().length;
        var totalTypedefs = TypeRegistryAPI.getAllTypedefs().length;

        trace('  Total registered types: $totalTypes');
        trace('  - Abstracts: $totalAbstracts');
        trace('  - Classes: $totalClasses');
        trace('  - Typedefs: $totalTypedefs');

        // Search for types
        var numTypes = TypeRegistryAPI.searchTypes("Num");
        if (numTypes.length > 0) {
            trace('  Types containing "Num": ${numTypes.join(", ")}');
        }

        // === Source Code Access ===
        trace("\n6. Source Code Access:");

        var sampleType = TypeRegistryAPI.getAllTypes()[0];
        if (sampleType != null) {
            trace('  Checking source for type: $sampleType');

            var sourceInfo = TypeRegistryAPI.getSource(sampleType);
            if (sourceInfo != null) {
                trace('    - File: ${sourceInfo.filePath}');
                trace('    - Source lines: ${sourceInfo.sourceLines.length}');
                trace('    - Position: ${sourceInfo.minPos}-${sourceInfo.maxPos}');
            } else {
                trace('    - No source information available');
            }

            var location = TypeRegistryAPI.findDefinition(sampleType);
            if (location != null) {
                trace('    - Definition: ${location.toString()}');
            }
        }

        // === Debug Object Creation ===
        trace("\n7. Debug Object Creation:");

        var debugObj = TypeRegistryAPI.createDebugObject("TestObject", {
            name: "Example Object",
            value: 123,
            active: true
        });

        trace('  Created debug object at: ${debugObj.getSourceLocation()}');
        trace('  Object properties:');
        trace('    - name: ${debugObj.getProperty("name")}');
        trace('    - value: ${debugObj.getProperty("value")}');
        trace('    - active: ${debugObj.getProperty("active")}');

        // Modify properties
        debugObj.setProperty("value", 456);
        trace('  Modified value to: ${debugObj.getProperty("value")}');

        // === Custom Checkers ===
        trace("\n8. Custom Type Checkers:");

        var isString = TypeRegistryAPI.createChecker("String");
        trace('  Custom string checker on "hello": ${isString("hello")}');
        trace('  Custom string checker on 123: ${isString(123)}');

        // === System Statistics ===
        trace("\n9. System Statistics:");
        TypeRegistryAPI.printStats();

        trace("\n=== Demonstration Complete ===");
    }

    /**
     * Demonstrate typedef validation
     */
    public static function demonstrateTypedefValidation():Void {
        trace("\n=== Typedef Validation Demo ===");

        // Example object that might match a typedef structure
        var sampleObject = {
            name: "Test",
            value: 42,
            optional: "maybe"
        };

        // Check against available typedefs
        var typedefs = TypeRegistryAPI.getAllTypedefs();
        if (typedefs.length > 0) {
            var sampleTypedef = typedefs[0];
            var result = TypeRegistryAPI.checkType(sampleObject, sampleTypedef);

            trace('Testing object against typedef: $sampleTypedef');
            trace('  Valid: ${result.isValid()}');
            if (!result.isValid()) {
                trace('  Errors: ${result.getErrors().join(", ")}');
            }
            if (result.getWarnings().length > 0) {
                trace('  Warnings: ${result.getWarnings().join(", ")}');
            }
        } else {
            trace("No typedefs found in registry");
        }
    }

    /**
     * Demonstrate advanced source analysis
     */
    public static function demonstrateSourceAnalysis():Void {
        trace("\n=== Source Analysis Demo ===");

        var classes = TypeRegistryAPI.getAllClasses();
        if (classes.length > 0) {
            var sampleClass = classes[0];
            var analysis = TypeRegistryAPI.analyzeSource(sampleClass);

            if (analysis != null) {
                trace('Analyzing source for: $sampleClass');
                trace('  Imports (${analysis.imports.length}): ${analysis.imports.slice(0, 3).join(", ")}...');
                trace('  Dependencies (${analysis.dependencies.length}): ${analysis.dependencies.slice(0, 3).join(", ")}...');
                trace('  Documentation lines: ${analysis.documentation.length}');
                trace('  Complexity: ${analysis.complexity.toString()}');
            } else {
                trace('No source analysis available for: $sampleClass');
            }
        }
    }
}

/**
 * Sample typedef for testing
 */
typedef SampleTypedef = {
    name: String,
    value: Int,
    ?optional: String
}

/**
 * Sample abstract for testing
 */
abstract SampleAbstract(Int) from Int to Int {
    public function new(value:Int) {
        this = value;
    }

    public function getValue():Int {
        return this;
    }
}
