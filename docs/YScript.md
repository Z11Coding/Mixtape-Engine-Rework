# YScript - A Haxe-like Scripting Language

YScript is a powerful scripting language designed for the Mixtape Engine that provides Haxe-like syntax with the ability to interface directly with Haxe code.

## Features

- **Haxe-like Syntax**: Familiar syntax for Haxe developers
- **Strong Typing**: Type-safe variables and functions
- **Class Support**: Define classes with inheritance and interfaces
- **Haxe Integration**: Embed native Haxe code blocks
- **Lua Integration**: Support for Lua code blocks (planned)
- **Functional AST**: Proper Abstract Syntax Tree for advanced parsing
- **Runtime Execution**: Full interpreter with scope management

## Basic Syntax

### Variables
```yscript
var message: String = "Hello, World!";
var count: Int = 42;
const PI: Float = 3.14159;
```

### Functions
```yscript
function greet(name: String): String {
    return "Hello, " + name + "!";
}

function calculate(a: Int, b: Int): Int {
    return a + b;
}
```

### Classes
```yscript
class Player {
    var name: String;
    var health: Int;
    
    function new(playerName: String) {
        name = playerName;
        health = 100;
    }
    
    function takeDamage(damage: Int): Void {
        health = health - damage;
        if (health <= 0) {
            health = 0;
        }
    }
}
```

### Enums
```yscript
enum GameState {
    MENU,
    PLAYING,
    PAUSED,
    GAME_OVER
}
```

### Control Flow
```yscript
function gameLoop(state: GameState): Void {
    if (state == GameState.PLAYING) {
        // Game logic
    } else if (state == GameState.PAUSED) {
        // Pause logic
    } else {
        // Menu or game over logic
    }
}

function countDown(start: Int): Void {
    for (i = start; i > 0; i = i - 1) {
        trace("Countdown: " + i);
    }
    trace("Blast off!");
}
```

### Haxe Integration
```yscript
haxe {
    // Native Haxe code can be embedded here
    import flixel.FlxSprite;
    
    var sprite = new FlxSprite(0, 0);
    sprite.makeGraphic(64, 64, 0xFFFFFFFF);
}
```

## Usage

### Basic Usage
```haxe
// Create a YScript instance
var script = new YScript();

// Execute YScript code
var result = script.execute('
    var message: String = "Hello from YScript!";
    
    function getMessage(): String {
        return message;
    }
');

// Call functions from the script
var functionResult = script.callFunction("getMessage", []);

// Get/set variables
var messageValue = script.getVariable("message");
script.setVariable("newVar", "New value", String);
```

### Advanced Usage
```haxe
// Create parser directly for more control
var parser = new YScriptParser();
var program = parser.parse(sourceCode);

// Create runtime with custom scope
var runtime = new YScriptRuntime();
var result = runtime.evaluateAST(program.ast, program.scope);
```

## Architecture

### AST Nodes
YScript uses a comprehensive AST (Abstract Syntax Tree) system:

- **Program**: Root node containing all statements
- **Declarations**: Classes, functions, variables, enums
- **Statements**: Control flow, blocks, expressions
- **Expressions**: Literals, identifiers, operations, function calls
- **Special**: Haxe blocks, Lua blocks

### Type System
YScript supports:
- **Primitive Types**: Int, Float, String, Bool
- **Complex Types**: Classes, Enums, Arrays
- **Haxe Types**: Direct integration with Haxe's type system
- **Dynamic Types**: Runtime type resolution

### Scope Management
- **Hierarchical Scopes**: Child scopes inherit from parent scopes
- **Variable Resolution**: Proper variable lookup chain
- **Function Binding**: Local function scopes with parameter binding

## Integration with Haxe

YScript is designed to work seamlessly with Haxe:

1. **Type Compatibility**: YScript types map directly to Haxe types
2. **Function Calls**: Call Haxe functions from YScript and vice versa
3. **Class Extension**: YScript classes can extend Haxe classes
4. **Interface Implementation**: YScript classes can implement Haxe interfaces
5. **Embedded Code**: Direct Haxe code blocks in YScript

## Error Handling

YScript provides comprehensive error handling:

- **Parse Errors**: Syntax and semantic errors during parsing
- **Runtime Errors**: Type errors, undefined variables, etc.
- **Control Flow**: Proper exception handling for return/break/continue

## Performance

YScript is optimized for:
- **Fast Parsing**: Efficient tokenization and AST construction
- **Memory Efficiency**: Minimal memory overhead for scopes and variables
- **Execution Speed**: Optimized AST evaluation

## Examples

See `example_yscript.ys` for a comprehensive example demonstrating all features.

## Future Enhancements

- **Lua Integration**: Full Lua block support
- **C/C++ Integration**: Direct C/C++ code execution
- **Advanced Type System**: Generics, type inference
- **Module System**: Import/export functionality
- **Debugging Support**: Breakpoints, step-through debugging
- **JIT Compilation**: Just-in-time compilation for performance

## Contributing

YScript is part of the Mixtape Engine project. Contributions are welcome!
