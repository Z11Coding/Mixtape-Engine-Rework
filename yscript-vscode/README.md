# YScript VS Code Extension

A comprehensive VS Code extension providing syntax highlighting, language server features, and Haxe integration for the YScript programming language.

## Features

### ✨ Syntax Highlighting
- **Keywords**: Complete YScript keyword highlighting (`var`, `function`, `class`, etc.)
- **Types**: Built-in type highlighting (`Int`, `Float`, `String`, `Bool`, etc.)
- **Operators**: Arithmetic, comparison, and logical operators
- **Literals**: String, number, and boolean literal highlighting
- **Comments**: Line and block comment support
- **Embedded Code**: Special highlighting for `haxe {}` and `lua {}` blocks

### 🔍 Language Server Features
- **Syntax Validation**: Real-time error detection and reporting
- **Auto-completion**: Context-aware suggestions for keywords, types, and identifiers
- **Hover Information**: Detailed type information and documentation on hover
- **Code Templates**: Smart snippets for common YScript constructs
- **Error Recovery**: Continues parsing after syntax errors

### 🎯 YScript Language Support
- **Variable Declarations**: `var` and `const` with optional type annotations
- **Function Definitions**: Full parameter and return type support
- **Class Declarations**: Inheritance and interface implementation
- **Control Flow**: `if`, `while`, `for`, and other control structures
- **Embedded Code**: Native `haxe {}` and `lua {}` code blocks
- **Type System**: Complete built-in and custom type support

## Installation

### From VS Code Marketplace
1. Open VS Code
2. Go to Extensions (Ctrl+Shift+X)
3. Search for "YScript Language Support"
4. Click Install

### Manual Installation
1. Clone this repository
2. Run `npm run compile` in the extension directory
3. Copy the extension to your VS Code extensions folder

## Usage

### Basic YScript Example
```yscript
// Variable declarations
var message: String = "Hello, YScript!";
const PI: Float = 3.14159;

// Function with type annotations
function greet(name: String): String {
    return "Hello, " + name + "!";
}

// Class with inheritance
class Person {
    var name: String;
    var age: Int;

    function new(name: String, age: Int) {
        this.name = name;
        this.age = age;
    }

    function introduce(): String {
        return "I'm " + name + ", " + age + " years old.";
    }
}

// Embedded Haxe code
function optimizedCalculation(data: Array<Float>): Float haxe {
    // Native Haxe code for performance
    var sum = 0.0;
    for (value in data) {
        sum += Math.sqrt(value * value + 1);
    }
    return sum / data.length;
}
```

### Embedded Code Blocks
YScript supports embedding native Haxe and Lua code:

```yscript
// Embedded Haxe for performance-critical operations
function processData(input: Array<Int>): Array<Int> haxe {
    return input.map(x -> x * 2).filter(x -> x > 10);
}

// Embedded Lua for scripting
function configureSettings() lua {
    -- Lua configuration code
    settings.quality = "high"
    settings.vsync = true
end
```

## Configuration

The extension supports the following settings:

### `yscript.validate.enable`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable/disable YScript validation

### `yscript.completion.enable`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable/disable auto-completion

### `yscript.hover.enable`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable/disable hover information

### `yscript.haxe.integration`
- **Type**: `boolean`
- **Default**: `true`
- **Description**: Enable Haxe integration for embedded code blocks

### `yscript.trace.server`
- **Type**: `string`
- **Default**: `"off"`
- **Options**: `"off"`, `"messages"`, `"verbose"`
- **Description**: Control language server logging level

## Commands

### `YScript: Restart Language Server`
Restarts the YScript language server. Useful for troubleshooting or after configuration changes.

## File Associations

The extension automatically recognizes files with the following extensions:
- `.ys` (primary YScript extension)
- `.yscript` (alternative YScript extension)

## Language Features

### Type System
YScript provides a rich type system with built-in types:
- `Int` - 32-bit signed integers
- `Float` - 64-bit floating point numbers
- `String` - Unicode strings
- `Bool` - Boolean values (`true`/`false`)
- `Array<T>` - Generic arrays
- `Dynamic` - Dynamic typing
- `Void` - No return value

### Control Structures
- Conditional: `if`/`else`
- Loops: `while`, `for`
- Function control: `return`, `break`, `continue`

### Object-Oriented Features
- Classes with inheritance (`extends`)
- Interface implementation (`implements`)
- Access modifiers (`public`, `private`)
- Static members (`static`)
- Method overriding (`override`)

### Integration Features
- Seamless Haxe code embedding
- Variable synchronization between YScript and embedded code
- Performance optimization through native code
- Extensive standard library access

## Development

### Building from Source
```bash
# Clone the repository
git clone https://github.com/your-repo/yscript-vscode
cd yscript-vscode

# Install dependencies
npm install

# Compile the extension
npm run compile

# Watch for changes during development
npm run watch
```

### Project Structure
```
yscript-vscode/
├── client/                 # VS Code extension client
│   ├── src/extension.ts   # Main extension entry point
│   └── package.json       # Client dependencies
├── server/                 # Language server implementation
│   ├── src/
│   │   ├── server.ts      # Main server entry point
│   │   ├── tokenizer.ts   # YScript tokenizer
│   │   ├── parser.ts      # YScript parser
│   │   ├── validator.ts   # Syntax validation
│   │   ├── completion.ts  # Auto-completion provider
│   │   └── hover.ts       # Hover information provider
│   └── package.json       # Server dependencies
├── syntaxes/
│   └── yscript.tmLanguage.json  # TextMate grammar
├── language-configuration.json   # Language configuration
└── package.json           # Extension manifest
```

## Contributing

We welcome contributions to improve YScript language support! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

### Areas for Contribution
- Enhanced syntax highlighting patterns
- Additional language server features
- Improved error messages
- Performance optimizations
- Documentation improvements

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

- **Issues**: Report bugs and request features on GitHub
- **Documentation**: Check the YScript language documentation
- **Community**: Join the Mixtape Engine development community

## Changelog

### Version 0.1.0
- Initial release
- Basic syntax highlighting
- Language server with validation, completion, and hover
- Embedded code block support
- Type system integration
