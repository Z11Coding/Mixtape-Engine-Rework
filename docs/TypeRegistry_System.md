# YutaUtil Type Registry System

A comprehensive macro-based type discovery and runtime type checking system for Haxe that enables complete introspection of types, abstracts, typedefs, and their source code at runtime.

## Overview

The Type Registry System provides:

- **Compile-time Type Discovery**: Macro-based discovery of all types, abstracts, typedefs, and enums in the compilation
- **Runtime Type Checking**: Advanced type validation and casting with detailed error reporting
- **Abstract Recognition**: Intelligent detection of abstract types from runtime values
- **Source Code Access**: Complete access to source code, positions, and metadata at runtime
- **Debug Object Creation**: Runtime object creation with full source traceability
- **HScript Integration**: Enable abstract type usage in HScript environments

## Architecture

### Core Components

- **TypeRegistry.hx**: Macro system that discovers and registers all types during compilation
- **RuntimeRegistry.hx**: Runtime access to type information with lazy initialization
- **Typer.hx**: Main type checking and casting utility
- **Typed.hx**: Wrapper for type-validated objects with metadata
- **AbstractRecognizer.hx**: Advanced abstract type detection from runtime values
- **SourceMapper.hx**: Complete source code access and analysis
- **TypeRegistryAPI.hx**: Simplified API for easy system access

### Type Information Classes

- **TypeInfo.hx**: Base type information (fields, documentation, positions)
- **AbstractInfo.hx**: Extended info for abstracts (underlying types, casts, value recognition)
- **ClassInfo.hx**: Extended info for classes (constructors, inheritance, static fields)
- **TypedefInfo.hx**: Extended info for typedefs (structure validation, field checking)

## Basic Usage

### Initialization

```haxe
import yutautil.typeregistry.TypeRegistryAPI;

// Initialize the system (called automatically on first use)
TypeRegistryAPI.initialize();
```

### Type Checking

```haxe
// Check if a value matches a specific type
var result = TypeRegistryAPI.checkType(someValue, "MyClass");
if (result.isValid()) {
    trace("Value is a valid MyClass!");
} else {
    trace("Errors: " + result.getErrors().join(", "));
}

// Auto-detect possible types
var possibleTypes = TypeRegistryAPI.detectTypes(someValue);
for (typed in possibleTypes) {
    trace('Could be: ${typed.typeName} (${typed.validationResult.confidence * 100}% confidence)');
}

// Quick inspection
var info = TypeRegistryAPI.inspect(someValue);
trace('Best match: ${info.bestMatch} (${info.confidence * 100}% confidence)');
```

### Abstract Recognition

```haxe
// Find abstract types that could match a value
var num = 42;
var abstractCandidates = TypeRegistryAPI.findAbstracts(num);

for (candidate in abstractCandidates) {
    trace('${candidate.getTypeName()}: ${candidate.confidence * 100}% confidence');
    trace('Reasons: ${candidate.reasons.join(", ")}');
}

// Get the best abstract match
var bestMatch = TypeRegistryAPI.getBestAbstract(num);
if (bestMatch != null) {
    trace('Best abstract match: ${bestMatch.getTypeName()}');
}

// Try to cast to a specific abstract
var wrapped = TypeRegistryAPI.castToAbstract(num, "yutautil.Num");
if (wrapped != null) {
    trace('Successfully wrapped as abstract: $wrapped');
}
```

### Source Code Access

```haxe
// Get source code for a type
var sourceInfo = TypeRegistryAPI.getSource("MyClass");
if (sourceInfo != null) {
    trace('Source file: ${sourceInfo.filePath}');
    trace('Source snippet:\n${sourceInfo.getSourceSnippet()}');
}

// Find where a type is defined
var location = TypeRegistryAPI.findDefinition("MyClass");
if (location != null) {
    trace('Defined at: ${location.toString()}'); // File:line:column
}

// Get comprehensive debug information
var debugInfo = TypeRegistryAPI.getDebugInfo("MyClass");
if (debugInfo != null) {
    trace('Type: ${debugInfo.typeName}');
    trace('Location: ${debugInfo.location}');
    trace('Source available: ${debugInfo.sourceInfo != null}');
}
```

### Debug Object Creation

```haxe
// Create a debug object with full traceability
var debugObj = TypeRegistryAPI.createDebugObject("MyClass", {
    name: "test",
    value: 123
});

trace('Debug object created at: ${debugObj.getSourceLocation()}');
trace('Property "name": ${debugObj.getProperty("name")}');

// Modify properties
debugObj.setProperty("value", 456);
```

## Advanced Features

### Registry Queries

```haxe
// Get all registered types
var allTypes = TypeRegistryAPI.getAllTypes();
var allAbstracts = TypeRegistryAPI.getAllAbstracts();
var allClasses = TypeRegistryAPI.getAllClasses();
var allTypedefs = TypeRegistryAPI.getAllTypedefs();

// Search for types by pattern
var matches = TypeRegistryAPI.searchTypes("Num");
// Returns: ["yutautil.Num", "NumberUtil", etc.]

// Check if a type exists
if (TypeRegistryAPI.hasType("MyClass")) {
    var typeInfo = TypeRegistryAPI.getTypeInfo("MyClass");
    // Access fields, methods, etc.
}
```

### Source Analysis

```haxe
// Analyze source code
var analysis = TypeRegistryAPI.analyzeSource("MyClass");
if (analysis != null) {
    trace('Imports: ${analysis.imports.join(", ")}');
    trace('Dependencies: ${analysis.dependencies.join(", ")}');
    trace('Complexity: ${analysis.complexity.toString()}');
    trace('Documentation lines: ${analysis.documentation.length}');
}
```

### Custom Type Checkers and Casters

```haxe
// Create reusable type checker
var isMyClass = TypeRegistryAPI.createChecker("MyClass");
if (isMyClass(someObject)) {
    trace("Object is MyClass!");
}

// Create reusable caster
var castToMyClass = TypeRegistryAPI.createCaster("MyClass", MyClass);
try {
    var typedObject = castToMyClass(someObject);
    // Use typedObject as MyClass
} catch (e:Dynamic) {
    trace("Casting failed: " + e);
}
```

## Abstract Type Integration

### Automatic Abstract Detection

The system can recognize abstract types from their underlying values:

```haxe
// If you have: abstract MyNum(Int) from Int to Int
var num = 42;
var candidates = TypeRegistryAPI.findAbstracts(num);
// Will find MyNum as a candidate if the value pattern matches
```

### HScript Integration

Enable abstract types in HScript environments:

```haxe
// In your HScript setup
var registry = TypeRegistryAPI;
hscript.interp.variables.set("TypeRegistry", registry);

// In HScript:
// var num = 42;
// var asAbstract = TypeRegistry.castToAbstract(num, "yutautil.Num");
```

## Macro Integration

### Compile-time Registration

Add to your build macro or main class:

```haxe
#if macro
import yutautil.typeregistry.TypeRegistry;

// Register the macro
@:build(yutautil.typeregistry.TypeRegistry.build())
#end
class Main {
    // Your main class
}
```

### Custom Type Metadata

The system automatically generates @:to casts for abstracts to enable type checking:

```haxe
// Your abstract automatically gets:
// @:to public function toTyped():Typed { ... }
```

## Future Development Plans

### Runtime Source Code Editing

**Planned Features:**
- **Source Code Modification**: Runtime editing of source code with automatic recompilation triggers
- **Hot Swapping**: Replace type definitions at runtime without full application restart
- **Code Generation**: Generate new types dynamically based on runtime data
- **Template System**: Create type templates that can be instantiated with different parameters

**Implementation Strategy:**
```haxe
// Planned API
TypeRegistryAPI.editSource("MyClass", newSourceCode);
TypeRegistryAPI.generateType("DynamicClass", templateData);
TypeRegistryAPI.hotSwapType("MyClass", newDefinition);
```

### Advanced Debug Object Creation

**Planned Features:**
- **Runtime Type Creation**: Create entirely new types at runtime based on specifications
- **Debug Proxy Objects**: Objects that track all property access and method calls
- **Memory Tracking**: Comprehensive memory usage tracking for debug objects
- **State Serialization**: Full state capture and restoration for debug objects

**Implementation Strategy:**
```haxe
// Planned API
var proxyObj = TypeRegistryAPI.createProxy(originalObject, {
    trackAccess: true,
    trackMemory: true,
    enableTimeTravel: true
});

var dynamicType = TypeRegistryAPI.createRuntimeType("DynamicClass", {
    fields: ["name:String", "value:Int"],
    methods: ["toString():String"]
});
```

### Comprehensive Debugging Tools

**Planned Features:**
- **Call Stack Analysis**: Deep analysis of type usage in call stacks
- **Type Flow Tracking**: Track how types flow through the application
- **Performance Profiling**: Type-specific performance metrics
- **Memory Leak Detection**: Identify type-related memory leaks

### Integration Enhancements

**Planned Features:**
- **Visual Studio Code Extension**: IDE integration for type browsing and debugging
- **Web Dashboard**: Browser-based type registry explorer
- **REPL Integration**: Interactive type exploration in runtime REPL
- **Documentation Generation**: Automatic documentation generation from type registry data

## Performance Considerations

### Macro Performance
- Type discovery happens at compile-time, minimal runtime overhead
- Source information is embedded as strings in the compiled output
- Registry data is JSON-serialized for fast runtime parsing

### Runtime Performance
- Lazy initialization - registry only loads when first accessed
- Source file caching to avoid repeated file I/O
- Type information caching for repeated lookups
- Confidence-based abstract recognition to avoid expensive checks

### Memory Usage
- Source code is cached but can be cleared with `SourceMapper.clearCache()`
- Type information is kept in memory for the application lifetime
- Debug objects maintain full traceability but can be heavy for large objects

## System Testing

```haxe
// Run comprehensive system tests
TypeRegistryAPI.runSystemTest();

// Print system statistics
TypeRegistryAPI.printStats();
```

## Integration with Existing Mixtape Engine Features

### Command System Integration

The Type Registry integrates with the Mixtape Engine command system:

```haxe
// In Main.CommandPrompt, add type registry commands:
// "typeinfo <TypeName>" - Get information about a type
// "findtype <value>" - Find types that could match a value
// "source <TypeName>" - Show source code for a type
```

### YutaUtil Integration

Works seamlessly with existing YutaUtil types:

```haxe
// Automatic recognition of Num, Temp, HaxePointer, etc.
var num = new Num(42);
var recognized = TypeRegistryAPI.getBestAbstract(num);
// Will correctly identify as yutautil.Num
```

### HScript and Lua Integration

Enables abstract type usage in scripting environments:

```haxe
// Make type registry available to scripts
psychlua.FunkinLua.addGlobalCallback("checkType", TypeRegistryAPI.checkType);
psychlua.FunkinLua.addGlobalCallback("findAbstracts", TypeRegistryAPI.findAbstracts);
```

## Error Handling

The system provides comprehensive error handling:

- **Compilation Errors**: Graceful fallbacks if macro discovery fails
- **Runtime Errors**: Detailed error messages with suggestions
- **Source Access Errors**: Fallback behavior when source files are unavailable
- **Type Validation Errors**: Detailed validation results with confidence scores

## Thread Safety

The system is designed to be thread-safe:

- Registry initialization uses singleton pattern with thread-safe lazy loading
- Source file access is cached and thread-safe
- Type information is immutable after initialization

This Type Registry System provides comprehensive runtime type introspection capabilities while maintaining performance and integrating seamlessly with the existing Mixtape Engine architecture.
