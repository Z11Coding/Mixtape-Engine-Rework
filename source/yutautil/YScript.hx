package yutautil;

import haxe.Constraints.Function;
import haxe.Json;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.crypto.Crc32;
import haxe.ds.StringMap;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Type;
#if !macro
import psychlua.LuaUtils;
#end

#if sys
import sys.io.File;
#end

#if (HSCRIPT_ALLOWED && !macro)
import crowplexus.hscript.Expr.Error as IrisError;
import crowplexus.iris.Iris;
import crowplexus.iris.IrisConfig;
#end

// ═══════════════════════════════════════════════════════════════════════════════════════
// YScript - A Haxe-integrated scripting language
// Goals:
//   - Haxe-like syntax with easier features from other languages
//   - Full Haxe type system integration (classes, abstracts, enums)
//   - Embedded Haxe code blocks for performance-critical sections
//   - Clean integration API for external systems
// ═══════════════════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════════════════
// CORE TYPE SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript variable representation with full Haxe type integration
 */
abstract YVar(YVarData) from YVarData to YVarData {
    public var name(get, never):String;
    public var type(get, never):YType;
    public var value(get, set):Dynamic;
    public var isHaxeType(get, never):Bool;

    public function new(name:String, type:YType, value:Dynamic = null) {
        this = {
            name: name,
            type: type,
            value: value,
            haxeType: YTypeHelper.isHaxeType(type) ? YTypeHelper.getHaxeType(type) : null
        };
    }

    inline function get_name():String return this.name;
    inline function get_type():YType return this.type;
    inline function get_value():Dynamic return this.value;
    inline function set_value(v:Dynamic):Dynamic return this.value = v;
    inline function get_isHaxeType():Bool return this.haxeType != null;

    @:to public function toString():String {
        return 'YVar(${this.name}:${YTypeHelper.toString(this.type)} = ${this.value})';
    }
}

typedef YVarData = {
    name:String,
    type:YType,
    value:Dynamic,
    ?haxeType:Dynamic // Direct reference to Haxe type when applicable
};

abstract YTypeable(YType) from YType to YType {
    public inline function new(type:YType) {
        this = type;
    }

    @:to public function toString():String {
        return YTypeHelper.toString(this);
    }

    @:from public static inline function fromClass<T>(cls:Class<T>):YTypeable {
        if (cls == null) return YType.Dynamic;
        // var typeG

        return switch (cast cls) {
            case Int: YType.YInt;
            case Float: YType.YFloat;
            case Bool: YType.YBool;
            case (String): YType.YString;
            case (Array): YType.YArray(YType.Dynamic); // Cannot determine element type at runtime
            default: YType.HaxeClass(cast cls);
        };
    }

    @:from public static inline function fromEnum<T>(e:Enum<T>):YTypeable {
        if (e == null) return YType.Dynamic;
        return YType.HaxeEnum(cast e);
    }
    // @:from public static function fromEnumVal()
}

/**
 * Unified type system supporting both YScript and Haxe types
 */
enum YType {
    // YScript native types
    YInt;
    YFloat;
    YString;
    YBool;
    YArray(elementType:YType);
    YFunction(params:Array<YType>, returnType:YType);
    YClass(className:String);
    YEnum(enumName:String);
    YStruct(structName:String);

    // Haxe type integration
    HaxeType(type:Dynamic); // Direct Haxe type reference
    HaxeClass(classType:Class<Dynamic>);
    HaxeAbstract(abstractType:Dynamic);
    HaxeEnum(enumType:Enum<Dynamic>);

    // Special types
    Dynamic;
    Void;
    Unknown;
}

// Add helper extensions for YType
class YTypeHelper {
    public static function isHaxeType(type:YType):Bool {
        return switch (type) {
            case HaxeType(_) | HaxeClass(_) | HaxeAbstract(_) | HaxeEnum(_): true;
            default: false;
        };
    }

    public static function getHaxeType(type:YType):Dynamic {
        return switch (type) {
            case HaxeType(t): t;
            case HaxeClass(c): c;
            case HaxeAbstract(a): a;
            case HaxeEnum(e): e;
            default: null;
        };
    }

    public static function toString(type:YType):String {
        return switch (type) {
            case YInt: "Int";
            case YFloat: "Float";
            case YString: "String";
            case YBool: "Bool";
            case YArray(el): 'Array<${toString(el)}>';
            case YFunction(params, ret): '(${params.map(toString).join(", ")}) -> ${toString(ret)}';
            case YClass(name): name;
            case YEnum(name): name;
            case YStruct(name): name;
            case HaxeType(t): Std.string(t);
            case HaxeClass(c): Type.getClassName(c);
            case HaxeAbstract(a): {
                if (Std.isOfType(a, yutautil.typeregistry.AbstractInterpreter)) {
                    (cast(a, yutautil.typeregistry.AbstractInterpreter)).abstractPath;
                } else {
                    Std.string(a);
                }
            };
            case HaxeEnum(e): Type.getEnumName(e);
            case Dynamic: "Dynamic";
            case Void: "Void";
            case Unknown: "Unknown";
        };
    }
}

/**
 * YScript function with embedded code support
 */
class YFunction {
    public var name:String;
    public var parameters:Array<YVar>;
    public var returnType:YType;
    public var body:YFunctionBody;
    public var isNative:Bool = false;
    public var nativeFunction:Dynamic;

    public function new(name:String, params:Array<YVar>, returnType:YType, body:YFunctionBody) {
        this.name = name;
        this.parameters = params;
        this.returnType = returnType;
        this.body = body;
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YFunction created: ${this.name} with return type ${YTypeHelper.toString(this.returnType)}');
        }
        #end
    }

    public function callNative(args:Array<Dynamic>):Dynamic {
        if (!isNative || nativeFunction == null)
            throw new YScriptError('Cannot call non-native function as native');
        return Reflect.callMethod(null, nativeFunction, args);
    }
}

/**
 * Function body types supporting embedded code
 */
enum YFunctionBody {
    YScript(statements:Array<YStatement>); // Native YScript code
    HaxeCode(code:String); // Embedded Haxe code block
    LuaCode(code:String); // Embedded Lua code block (future)
    Native(func:Function); // Direct Haxe function reference
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// AST SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript Abstract Syntax Tree with location tracking
 */
enum YStatement {
    // Imports and declarations
    Import(path:String, alias:Null<String>, location:YLocation); // import path.to.Class or import path.to.Class as Alias
    VarDecl(name:String, type:YType, init:Null<YExpression>, location:YLocation);
    FuncDecl(name:String, params:Array<YVar>, returnType:YType, body:YFunctionBody, location:YLocation);
    ClassDecl(name:String, extend:Null<String>, implement:Array<String>, body:Array<YStatement>, location:YLocation);

    // Control flow
    If(condition:YExpression, thenStmt:YStatement, elseStmt:Null<YStatement>, location:YLocation);
    While(condition:YExpression, body:YStatement, location:YLocation);
    For(init:Null<YStatement>, condition:Null<YExpression>, increment:Null<YExpression>, body:YStatement, location:YLocation);
    ForIn(varName:String, varType:YType, iterable:YExpression, body:YStatement, location:YLocation);
    Return(value:Null<YExpression>, location:YLocation);
    Break(location:YLocation);
    Continue(location:YLocation);

    // Blocks and expressions
    Block(statements:Array<YStatement>, location:YLocation);
    Expression(expr:YExpression, location:YLocation);

    // Embedded code
    HaxeBlock(code:String, location:YLocation);
    LuaBlock(code:String, location:YLocation);
}

enum YExpression {
    // Literals
    IntLiteral(value:Int, location:YLocation);
    FloatLiteral(value:Float, location:YLocation);
    StringLiteral(value:String, location:YLocation);
    BoolLiteral(value:Bool, location:YLocation);
    NullLiteral(location:YLocation);
    ArrayLiteral(elements:Array<YExpression>, location:YLocation);
    ObjectLiteral(fields:Array<{name:String, value:YExpression}>, location:YLocation);

    // Identifiers and access
    Identifier(name:String, location:YLocation);
    MemberAccess(object:YExpression, member:String, location:YLocation);
    ArrayAccess(array:YExpression, index:YExpression, location:YLocation);

    // Super calls and access
    SuperCall(args:Array<YExpression>, location:YLocation); // super(args) in constructor
    SuperMemberAccess(member:String, location:YLocation); // super.method or super.field
    SuperMethodCall(method:String, args:Array<YExpression>, location:YLocation); // super.method(args)

    // Operations
    BinaryOp(left:YExpression, op:String, right:YExpression, location:YLocation);
    UnaryOp(op:String, operand:YExpression, location:YLocation);
    Assignment(left:YExpression, right:YExpression, location:YLocation);
    CompoundAssignment(left:YExpression, op:String, right:YExpression, location:YLocation);

    // Function and constructor calls
    FunctionCall(func:YExpression, args:Array<YExpression>, location:YLocation);
    New(type:YType, args:Array<YExpression>, location:YLocation);

    // Type operations
    Cast(expr:YExpression, type:YType, location:YLocation);
    Is(expr:YExpression, type:YType, location:YLocation);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// COMPILED SCRIPT FORMAT
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * Compiled YScript format for faster loading and execution
 */
typedef YCompiledScript = {
    // Script metadata
    version:String, // YScript compiler version
    originalPath:String, // Original source file path
    compiledAt:String, // Compilation timestamp
    sourceHash:String, // Hash of original source for validation

    // Compiled data
    statements:Array<YStatementData>, // Serialized AST
    types:Array<YTypeData>, // Type definitions
    functions:Array<YFunctionData>, // Function definitions
    classes:Array<YClassData>, // Class definitions
    imports:Array<YImportData>, // Import statements

    // Optimization data
    optimized:Bool, // Whether optimizations were applied
    staticAnalysis:Dynamic // Static analysis results
};

/**
 * Serializable statement data
 */
typedef YStatementData = {
    type:String, // Statement type name
    data:Dynamic // Statement-specific data
};

/**
 * Serializable expression data
 */
typedef YExpressionData = {
    type:String, // Expression type name
    data:Dynamic // Expression-specific data
};

/**
 * Serializable type data
 */
typedef YTypeData = {
    type:String, // Type name
    data:Dynamic // Type-specific data
};

/**
 * Serializable function data
 */
typedef YFunctionData = {
    name:String,
    parameters:Array<Dynamic>,
    returnType:YTypeData,
    bodyType:String,
    bodyData:Dynamic
};

/**
 * Serializable class data
 */
typedef YClassData = {
    name:String,
    superClass:Null<String>,
    interfaces:Array<String>,
    fields:Array<{name:String, type:YTypeData, defaultValue:Dynamic}>,
    methods:Array<YFunctionData>,
    constructors:Array<YFunctionData>
};

/**
 * Serializable import data
 */
typedef YImportData = {
    path:String,
    alias:Null<String>
};

// ═══════════════════════════════════════════════════════════════════════════════════════
// ERROR SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

class YScriptError extends haxe.Exception {
    public var location:Null<YLocation>;
    public var scriptPath:Null<String>;

    public function new(message:String, ?location:YLocation, ?scriptPath:String) {
        this.location = location;
        this.scriptPath = scriptPath;

        // Add YScript location to native CallStack if available
        if (location != null) {
            super(addYScriptStackFrame(location, scriptPath, message));
        }
				else {
						super(message);
				}
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScriptError created: $message at ${location != null ? '${location.file}:${location.line}:${location.column}' : 'unknown location'}');
        }
        #end
    }

    private function addYScriptStackFrame(location:YLocation, ?scriptPath:String, message:String):String {
        try {
            // Create a synthetic stack frame for YScript location
            var scriptInfo = scriptPath != null ? scriptPath : location.file;
            var frameInfo = 'YScript:${location.file}:${location.line}';

            // Add to current CallStack context - this will appear in stack traces
            var currentStack:Dynamic = haxe.CallStack.exceptionStack();
            if (currentStack.length == 0) {
                currentStack = this.stack;
            }
						if (currentStack == null || currentStack.length == 0) {
							currentStack = haxe.CallStack.callStack();
						}

            // Add YScript context information to the error message
            var yscriptInfo = "YScript Error at " + location.file + ":" + location.line + ":" + location.column;
            return message + "\n" + yscriptInfo;



            // The frame will be included in subsequent stack traces automatically
        } catch (e:Dynamic) {
            // Fallback if CallStack manipulation fails
						return message;
        }
    }
}

class YScriptParseError extends YScriptError {
    public function new(message:String, ?location:YLocation, ?scriptPath:String) {
        super('Parse Error: $message', location, scriptPath);
    }
}

class YScriptRuntimeError extends YScriptError {
    public function new(message:String, ?location:YLocation, ?scriptPath:String) {
        super('Runtime Error: $message', location, scriptPath);
    }
}

class YScriptTypeError extends YScriptError {
    public function new(message:String, ?location:YLocation, ?scriptPath:String) {
        super('Type Error: $message', location, scriptPath);
    }
}

typedef YLocation = {
    file:String,
    line:Int,
    column:Int
};

/**
 * Error severity levels for YScript errors
 */
enum YScriptErrorSeverity {
    Warning;
    Error;
    Fatal;
}

/**
 * Collected error information
 */
typedef YScriptCollectedError = {
    error:YScriptError,
    severity:YScriptErrorSeverity,
    phase:String, // "parse", "runtime", "typecheck"
    contextInfo:String
};

/**
 * Enhanced error collection and reporting system
 */
class YScriptErrorCollector {
    private var errors:Array<YScriptCollectedError> = [];
    private var maxErrors:Int = 10;
    private var stopOnFatal:Bool = true;
    private var scriptPath:String;

    public function new(scriptPath:String) {
        this.scriptPath = scriptPath;
    }

    public function addError(error:YScriptError, severity:YScriptErrorSeverity, phase:String, ?contextInfo:String):Void {
        var collected:YScriptCollectedError = {
            error: error,
            severity: severity,
            phase: phase,
            contextInfo: contextInfo ?? ""
        };

        errors.push(collected);

        // Stop immediately on fatal errors
        if (severity == Fatal && stopOnFatal) {
            throw new YScriptRuntimeError('Fatal error: ${error.message}', error.location, error.scriptPath);
        }

        // Stop if too many errors accumulated
        if (errors.length >= maxErrors) {
            throw new YScriptRuntimeError('Too many errors (${errors.length}), stopping compilation', error.location, error.scriptPath);
        }
    }

    public function hasErrors():Bool {
        return errors.length > 0;
    }

    public function hasFatalErrors():Bool {
        for (error in errors) {
            if (error.severity == Fatal) return true;
        }
        return false;
    }

    public function getErrors():Array<YScriptCollectedError> {
        return errors.copy();
    }

    public function getErrorCount():Int {
        return errors.length;
    }

    public function clear():Void {
        errors = [];
    }

    /**
     * Generate comprehensive error report with context
     */
    public function generateReport():String {
        if (errors.length == 0) return "No errors";

        var report = '\n=== YScript Error Report for ${scriptPath} ===\n';
        report += 'Total errors: ${errors.length}\n\n';

        var errorsByPhase = new Map<String, Array<YScriptCollectedError>>();
        for (error in errors) {
            if (!errorsByPhase.exists(error.phase)) {
                errorsByPhase.set(error.phase, []);
            }
            errorsByPhase.get(error.phase).push(error);
        }

        for (phase in errorsByPhase.keys()) {
            var phaseErrors = errorsByPhase.get(phase);
            report += '--- ${phase.toUpperCase()} ERRORS ---\n';

            for (i in 0...phaseErrors.length) {
                var err = phaseErrors[i];
                var severityStr = switch (err.severity) {
                    case Warning: "WARNING";
                    case Error: "ERROR";
                    case Fatal: "FATAL";
                };

                report += '${i + 1}. ${severityStr}\n';
                report += '   Location: ${err.error.location != null ? '${err.error.location.file}:${err.error.location.line}:${err.error.location.column}' : 'unknown'}\n';
                report += '   Message: ${err.error.message}\n';
                if (err.contextInfo.length > 0) {
                    report += '   Context: ${err.contextInfo}\n';
                }
                report += '\n';
            }
        }

        return report;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// MAIN YSCRIPT CLASS
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * Main YScript interpreter and runtime
 * Provides clean integration API for external systems
 */
class YScript {

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTEGRATION API
    // ═══════════════════════════════════════════════════════════════════════════════════════

    private var parser:YScriptParser;
    private var runtime:YScriptRuntime;
    private var scope:YScope;
    private var haxeCompilerDefines:Map<String, String> = haxe.Resource.getBytes("haxe_compiler_defines") != null ? haxe.Json.parse(haxe.Resource.getBytes("haxe_compiler_defines").toString()) : null;
    private var YScript_Defines:Map<String, String> = null;

    public var scriptPath:String;
    public var isReady:Bool = false;
    public var hasErrors:Bool = false;
    public var lastError:String;

    // Enhanced error collection system
    private var errorCollector:YScriptErrorCollector;
    #if !macro
    private var attachedToPlayState:Bool = false;
    private var playStateInstance:states.PlayState = null; // Reference to PlayState instance
    #end

    public function new() {
        parser = new YScriptParser();
        runtime = new YScriptRuntime();
        scope = new YScope();
        errorCollector = new YScriptErrorCollector("<unknown>");
        setupBuiltins();
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Debug mode enabled - detailed execution tracing active');
            trace('Haxe Compiler Defines detected: ' + Std.string(haxeCompilerDefines));
            trace('YScript Compiler Defines: ' + Std.string(YScript_Defines));
            trace('What Haxe Defines are supposed to be: ' + Std.string(haxe.Resource.getBytes("haxe_compiler_defines").toString()));
        }
        #end
    }

    /**
     * Helper function to create a default location when location info isn't available
     */
    private function createDefaultLocation(file:String = "<unknown>"):YLocation {
        return {
            file: file,
            line: 0,
            column: 0
        };
    }

    #if !macro
    /**
     * ✅ PLAYSTATE INTEGRATION: Attach to PlayState for error reporting
     */
    public function attachToPlayState(?playState:states.PlayState):Bool {
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        try {
            // If no specific instance provided, try to get current PlayState
            if (playState == null) {
                // Try to get PlayState from FlxG.state
                var currentState = flixel.FlxG.state;
                if (Std.isOfType(currentState, states.PlayState)) {
                    playState = cast(currentState, states.PlayState);
                } else {
                    trace('YScript: Cannot attach to PlayState - current state is not PlayState');
                    return false;
                }
            }

            if (playState != null) {
                playStateInstance = playState;
                attachedToPlayState = true;
            } else {
                trace('YScript: Cannot attach to PlayState - instance is null');
                return false;
            }

            trace('YScript: Successfully attached to PlayState for error reporting');
            return true;

        } catch (e:Dynamic) {
            trace('YScript: Failed to attach to PlayState: $e');
            return false;
        }
        #else
        trace('YScript: PlayState integration not available - LUA_ALLOWED or HSCRIPT_ALLOWED required');
        return false;
        #end
    }
    #end

    #if !macro
    /**
     * Forward error to PlayState debug system
     */
    private function forwardErrorToPlayState(message:String, ?isError:Bool = true):Void {
        #if (LUA_ALLOWED || HSCRIPT_ALLOWED)
        if (attachedToPlayState && playStateInstance != null) {
            try {
                var color = isError ? flixel.util.FlxColor.RED : flixel.util.FlxColor.YELLOW;
                playStateInstance.addTextToDebug(message, color);
            } catch (e:Dynamic) {
                trace('YScript: Failed to forward error to PlayState: $e');
            }
        }
        #end
    }
    #end

    /**
     * Show error window for critical parse errors
     */
    private function showErrorWindow(title:String, message:String):Void {
        #if macro
        // In macro context, always use trace as window dialogs are not available
        trace('YScript Error: $title - $message');
        #else
        try {
            // Fallback to native alert
            #if desktop
            lime.app.Application.current.window.alert(message, title);
            #end
        } catch (e:Dynamic) {
            trace('YScript: Failed to show error window: $e');
            // Last resort - trace the error
            trace('YScript Error: $title - $message');
        }
        #end
    }

    /**
     * ✅ INTEGRATION: Load script from source code with enhanced error handling
     */
    public function loadFromSource(source:String, ?path:String):Bool {
        try {
            this.scriptPath = path ?? "<inline>";
            errorCollector = new YScriptErrorCollector(this.scriptPath);
            scope.setExecutionContext(this.scriptPath);

            // Enhanced parsing with error collection
            parser.setErrorCollector(errorCollector);
            var program = parser.parse(source, this.scriptPath);

            // Check for parse errors - fail on ANY errors
            if (errorCollector.hasErrors()) {
                hasErrors = true;
                lastError = "Parse errors occurred";

                var errorReport = errorCollector.generateReport();
                trace('YScript Parse Errors:\n$errorReport');

                // Forward errors to PlayState if attached
                #if !macro
                forwardErrorToPlayState('YScript Parse Error in ${this.scriptPath}', true);
                #end

                showErrorWindow("YScript Parse Error", 'Parse errors in ${this.scriptPath}:\n\n${errorReport}');
                return false;
            }

            runtime.initialize(program, scope);
            isReady = true;
            hasErrors = false;
            trace('[YScript] Loaded script!');
            if (path != null && path.length > 0) {
                trace('[YScript] Script path: ' + path);
            }
            return true;
        } catch (e:YScriptError) {
            hasErrors = true;
            lastError = e.message;
            trace('YScript: Failed to load script: ${e.message}');

            // Forward to PlayState and show error window
            #if !macro
            forwardErrorToPlayState('YScript Error: ${e.message}', true);
            #end
            showErrorWindow("YScript Critical Error", 'Failed to load ${this.scriptPath}:\n\n${e.message}');

            return false;
        }
    }

    /**
     * ✅ INTEGRATION: Load script from file
     */
    public function loadFromFile(filePath:String):Bool {
        #if sys
        try {
            var content = sys.io.File.getContent(filePath);
            return loadFromSource(content, filePath);
        } catch (e:Dynamic) {
            hasErrors = true;
            lastError = 'Failed to read file: $filePath';
            return false;
        }
        #else
        hasErrors = true;
        lastError = 'File system not available on this platform';
        return false;
        #end
    }

    /**
     * ✅ COMPILATION: Compile YScript source to compiled format
     */
    public function compile(source:String, ?path:String):YCompiledScript {
        try {
            this.scriptPath = path ?? "<inline>";
            scope.setExecutionContext(this.scriptPath);

            // Parse the source
            var statements = parser.parse(source, this.scriptPath);

            // Serialize the AST and metadata
            var compiled:YCompiledScript = {
                version: "1.0.0",
                originalPath: this.scriptPath,
                compiledAt: Date.now().toString(),
                sourceHash: generateSourceHash(source),
                statements: serializeStatements(statements),
                types: serializeTypes(),
                functions: serializeFunctions(),
                classes: serializeClasses(),
                imports: serializeImports(),
                optimized: false,
                staticAnalysis: {}
            };

            return compiled;
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Compilation failed: $e');
        }
    }

    /**
     * ✅ COMPILATION: Load and execute compiled YScript
     */
    public function loadFromCompiled(compiled:YCompiledScript):Bool {
        try {
            this.scriptPath = compiled.originalPath;
            scope.setExecutionContext(this.scriptPath);

            // Deserialize and load the compiled data
            var statements = deserializeStatements(compiled.statements);
            deserializeTypes(compiled.types);
            deserializeFunctions(compiled.functions);
            deserializeClasses(compiled.classes);
            deserializeImports(compiled.imports);

            // Initialize runtime with deserialized statements
            runtime.initialize(statements, scope);

            isReady = true;
            hasErrors = false;
            return true;
        } catch (e:YScriptError) {
            hasErrors = true;
            lastError = e.message;
            trace('YScript: Failed to load compiled script: ${e.message}');
            return false;
        }
    }

    /**
     * ✅ COMPILATION: Save compiled script to file
     */
    public function saveCompiled(compiled:YCompiledScript, filePath:String):Bool {
        #if sys
        try {
            var json = Json.stringify(compiled);
            sys.io.File.saveContent(filePath, json);
            return true;
        } catch (e:Dynamic) {
            hasErrors = true;
            lastError = 'Failed to save compiled script: $e';
            return false;
        }
        #else
        hasErrors = true;
        lastError = 'File system not available on this platform';
        return false;
        #end
    }

    /**
     * ✅ COMPILATION: Load compiled script from file
     */
    public function loadCompiledFromFile(filePath:String):Bool {
        #if sys
        try {
            var json = sys.io.File.getContent(filePath);
            var compiled:YCompiledScript = Json.parse(json);
            return loadFromCompiled(compiled);
        } catch (e:Dynamic) {
            hasErrors = true;
            lastError = 'Failed to load compiled script: $e';
            return false;
        }
        #else
        hasErrors = true;
        lastError = 'File system not available on this platform';
        return false;
        #end
    }

    /**
     * ✅ INTEGRATION: Call function from external system
     */
    public function callFunction(name:String, ?args:Array<Dynamic>):Dynamic {
        if (!isReady) {
            throw new YScriptRuntimeError('Script not loaded');
        }

        if (args == null) args = [];

        try {
            return runtime.callFunction(name, args, scope);
        } catch (e:YScriptError) {
            hasErrors = true;
            lastError = e.message;
            // forwardErrorToPlayState('YScript Error: Failed to call function $name: ${e.message}', true);

            trace('YScript: Failed to call function $name: ${e.message}');
            return null;
        }
    }

    /**
     * ✅ INTEGRATION: Check if function exists
     */
    public function hasFunction(name:String):Bool {
        return isReady && scope.hasFunction(name);
    }

    public function attemptFunction(name:String, ?args:Array<Dynamic>):Dynamic {
        return hasFunction(name) ? callFunction(name, args) : null;
    }

    /**
     * ✅ INTEGRATION: Set variable from external system
     */
    public function setVariable(name:String, value:Dynamic, ?type:YTypeable):Void {
        if (!isReady) {
            throw new YScriptRuntimeError('Script not loaded');
        }

        var inferredType = type ?? inferTypeFromValue(value);
        var yvar = new YVar(name, inferredType, value);
        scope.setVariable(name, yvar);
    }

    /**
     * ✅ ARRAY TYPE INFERENCE: Intelligently infer array element type by scanning contents
     */
    private function inferArrayElementType(array:Dynamic):YType {
        var arr:Array<Dynamic> = cast array;

        // Empty array defaults to Dynamic
        if (arr.length == 0) {
            return YType.YArray(YType.Dynamic);
        }

        // Scan first few elements to determine type pattern
        var sampleSize = Std.int(Math.min(arr.length, 10)); // Sample first 10 elements for performance
        var elementTypes:Array<YType> = [];

        for (i in 0...sampleSize) {
            elementTypes.push(inferTypeFromValue(arr[i]));
        }

        // Find common type among elements
        var commonType = findCommonType(elementTypes);
        return YType.YArray(commonType);
    }

    /**
     * Find the most specific common type from a list of types
     */
    private function findCommonType(types:Array<YType>):YType {
        if (types.length == 0) return YType.Dynamic;
        if (types.length == 1) return types[0];

        var firstType = types[0];
        var allSameType = true;
        var hasInt = false;
        var hasFloat = false;
        var hasNumeric = true;

        for (type in types) {
            if (!Type.enumEq(type, firstType)) {
                allSameType = false;
            }

            switch (type) {
                case YType.YInt: hasInt = true;
                case YType.YFloat: hasFloat = true;
                default: hasNumeric = false;
            }
        }

        // If all elements are exactly the same type
        if (allSameType) {
            return firstType;
        }

        // If mixed Int/Float, use Float as common numeric type
        if (hasNumeric && (hasInt || hasFloat)) {
            return hasFloat ? YType.YFloat : YType.YInt;
        }

        // If all are Haxe classes, try to find common superclass
        var allHaxeClasses = true;
        var haxeClasses:Array<Class<Dynamic>> = [];

        for (type in types) {
            switch (type) {
                case YType.HaxeClass(c):
                    haxeClasses.push(c);
                default:
                    allHaxeClasses = false;
                    break;
            }
        }

        if (allHaxeClasses && haxeClasses.length > 0) {
            // For now, return the first class type - could be enhanced with inheritance checking
            return YType.HaxeClass(haxeClasses[0]);
        }

        // Fallback to Dynamic for mixed types
        return YType.Dynamic;
    }

    /**
     * ✅ INTEGRATION: Get variable from external system
     */
    public function getVariable(name:String):Dynamic {
        if (!isReady) {
            throw new YScriptRuntimeError('Script not loaded');
        }

        var yvar = scope.getVariable(name);
        return yvar != null ? yvar.value : null;
    }

    /**
     * ✅ INTEGRATION: Execute script (run main or entry point)
     */
    public function execute():Dynamic {
        if (!isReady) {
            throw new YScriptRuntimeError('Script not loaded');
        }

        try {
            return runtime.execute(scope);
        } catch (e:YScriptError) {
            hasErrors = true;
            lastError = e.message;
            return null;
        }
    }

    /**
     * ✅ INTEGRATION: Cleanup resources
     */
    public function destroy():Void {
        isReady = false;
        hasErrors = false;
        if (scope != null) scope.destroy();
        if (runtime != null) runtime.destroy();
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // HAXE TYPE INTEGRATION
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * ✅ HAXE INTEGRATION: Register Haxe class for use in YScript
     */
    public function registerHaxeClass(className:String, classType:Class<Dynamic>):Void {
        var ytype = YType.HaxeClass(classType);
        scope.setType(className, ytype);
    }

    /**
     * ✅ HAXE INTEGRATION: Register Haxe function for use in YScript
     */
    public function registerHaxeFunction(name:String, func:haxe.Constraints.Function):Void {
        var yfunc = new YFunction(name, [], YType.Dynamic, YFunctionBody.Native(func));
        yfunc.isNative = true;
        yfunc.nativeFunction = func;
        scope.setFunction(name, yfunc);
    }

    /**
     * ✅ HAXE INTEGRATION: Infer YScript type from Haxe value
     */
    private function inferTypeFromValue(value:Dynamic):YType {
        if (value == null) return YType.Dynamic;

        return switch (Type.typeof(value)) {
            case TInt: YType.YInt;
            case TFloat: YType.YFloat;
            case TBool: YType.YBool;
            case TClass(String): YType.YString;
            case TClass(Array): inferArrayElementType(value);
            case TClass(c): YType.HaxeClass(c);
            case TEnum(e): YType.HaxeEnum(e);
            case TFunction: YType.YFunction([], YType.Dynamic);
            case TObject: YType.Dynamic;
            case TNull: YType.Dynamic;
            case TUnknown: YType.Unknown;
        };
    }

    /**
     * Setup built-in functions and types
     */
    private function setupBuiltins():Void {
        // Built-in functions
        // Trace adds location info.
        #if !macro
        registerHaxeFunction("trace", function(msg:Dynamic) { backend.modules.TraceManager.println('${this.scriptPath}:${this.runtime.scope.currentLocation.line ?? this.scope.currentLocation.line}: ${msg}'); });
        registerHaxeFunction("print", function(msg:Dynamic) { backend.modules.TraceManager.println(Std.string(msg)); });
        #else
        registerHaxeFunction("trace", function(msg:Dynamic) { Sys.println('${this.scriptPath}:${this.runtime.scope.currentLocation.line ?? this.scope.currentLocation.line}: ${msg}'); });
        registerHaxeFunction("print", function(msg:Dynamic) { Sys.println(Std.string(msg)); });
        #end
        // Built-in types
        scope.setType("Int", YType.YInt);
        scope.setType("Float", YType.YFloat);
        scope.setType("String", YType.YString);
        scope.setType("Bool", YType.YBool);
        scope.setType("Dynamic", YType.Dynamic);
        scope.setType("Void", YType.Void);
        #if !macro
        scope.createVariable("Function_StopYScript", LuaUtils.Function_StopYScript);
        scope.createVariable("Function_StopAll", LuaUtils.Function_StopAll);
        scope.createVariable("Function_Continue", LuaUtils.Function_Continue);
        #end
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTROSPECTION API
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * ✅ API: Get all variable names in the current scope
     */
    public function getVariableNames():Array<String> {
        return isReady ? scope.getAllVariableNames() : [];
    }

    /**
     * ✅ API: Get all function names in the current scope
     */
    public function getFunctionNames():Array<String> {
        return isReady ? scope.getAllFunctionNames() : [];
    }

    /**
     * ✅ API: Get detailed information about all variables
     */
    public function getVariables():Array<{name:String, type:String, value:Dynamic}> {
        return isReady ? scope.getAllVariables() : [];
    }

    /**
     * ✅ API: Get detailed information about all functions
     */
    public function getFunctions():Array<{name:String, parameters:Array<String>, returnType:String}> {
        return isReady ? scope.getAllFunctions() : [];
    }

    /**
     * ✅ API: Get information about a specific variable
     */
    public function getVariableInfo(name:String):{name:String, type:String, value:Dynamic} {
        return isReady ? scope.getVariableInfo(name) : null;
    }

    /**
     * ✅ API: Get information about a specific function
     */
    public function getFunctionInfo(name:String):{name:String, parameters:Array<String>, returnType:String} {
        return isReady ? scope.getFunctionInfo(name) : null;
    }

    /**
     * ✅ API: Check if a variable exists
     */
    public function hasVariable(name:String):Bool {
        return isReady ? scope.hasVariable(name) : false;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // COMPILATION SERIALIZATION SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * Generate hash of source code for validation
     */
    private function generateSourceHash(source:String):String {
        var bytes = Bytes.ofString(source);
        return Std.string(Crc32.make(bytes));
    }

    /**
     * Serialize statements to data format
     */
    private function serializeStatements(statements:Array<YStatement>):Array<YStatementData> {
        var result:Array<YStatementData> = [];
        for (stmt in statements) {
            result.push(serializeStatement(stmt));
        }
        return result;
    }

    /**
     * Serialize individual statement
     */
    private function serializeStatement(stmt:YStatement):YStatementData {
        return switch (stmt) {
            case Import(path, alias, location):
                {type: "Import", data: {path: path, alias: alias}};
            case VarDecl(name, type, init, location):
                {type: "VarDecl", data: {name: name, type: serializeType(type), init: init != null ? serializeExpression(init) : null}};
            case FuncDecl(name, params, returnType, body, location):
                {type: "FuncDecl", data: {name: name, params: [for (p in params) serializeVar(p)], returnType: serializeType(returnType), body: serializeFunctionBody(body)}};
            case ClassDecl(name, extend, implement, body, location):
                {type: "ClassDecl", data: {name: name, extend: extend, implement: implement, body: [for (s in body) serializeStatement(s)]}};
            case If(condition, thenStmt, elseStmt, location):
                {type: "If", data: {condition: serializeExpression(condition), thenStmt: serializeStatement(thenStmt), elseStmt: elseStmt != null ? serializeStatement(elseStmt) : null}};
            case While(condition, body, location):
                {type: "While", data: {condition: serializeExpression(condition), body: serializeStatement(body)}};
            case For(init, condition, increment, body, location):
                {type: "For", data: {init: init != null ? serializeStatement(init) : null, condition: condition != null ? serializeExpression(condition) : null, increment: increment != null ? serializeExpression(increment) : null, body: serializeStatement(body)}};
            case ForIn(varName, varType, iterable, body, location):
                {type: "ForIn", data: {varName: varName, varType: serializeType(varType), iterable: serializeExpression(iterable), body: serializeStatement(body)}};
            case Return(value, location):
                {type: "Return", data: {value: value != null ? serializeExpression(value) : null}};
            case Break(location):
                {type: "Break", data: {}};
            case Continue(location):
                {type: "Continue", data: {}};
            case Block(statements, location):
                {type: "Block", data: {statements: [for (s in statements) serializeStatement(s)]}};
            case Expression(expr, location):
                {type: "Expression", data: {expr: serializeExpression(expr)}};
            case HaxeBlock(code, location):
                {type: "HaxeBlock", data: {code: code}};
            case LuaBlock(code, location):
                {type: "LuaBlock", data: {code: code}};
        };
    }

    /**
     * Serialize expression to data format
     */
    private function serializeExpression(expr:YExpression):YExpressionData {
        return switch (expr) {
            case IntLiteral(value, location):
                {type: "IntLiteral", data: {value: value}};
            case FloatLiteral(value, location):
                {type: "FloatLiteral", data: {value: value}};
            case StringLiteral(value, location):
                {type: "StringLiteral", data: {value: value}};
            case BoolLiteral(value, location):
                {type: "BoolLiteral", data: {value: value}};
            case NullLiteral(location):
                {type: "NullLiteral", data: {}};
            case ArrayLiteral(elements, location):
                {type: "ArrayLiteral", data: {elements: [for (e in elements) serializeExpression(e)]}};
            case ObjectLiteral(fields, location):
                {type: "ObjectLiteral", data: {fields: [for (f in fields) {name: f.name, value: serializeExpression(f.value)}]}};
            case Identifier(name, location):
                {type: "Identifier", data: {name: name}};
            case MemberAccess(object, member, location):
                {type: "MemberAccess", data: {object: serializeExpression(object), member: member}};
            case ArrayAccess(array, index, location):
                {type: "ArrayAccess", data: {array: serializeExpression(array), index: serializeExpression(index)}};
            case SuperCall(args, location):
                {type: "SuperCall", data: {args: [for (a in args) serializeExpression(a)]}};
            case SuperMemberAccess(member, location):
                {type: "SuperMemberAccess", data: {member: member}};
            case SuperMethodCall(method, args, location):
                {type: "SuperMethodCall", data: {method: method, args: [for (a in args) serializeExpression(a)]}};
            case BinaryOp(left, op, right, location):
                {type: "BinaryOp", data: {left: serializeExpression(left), op: op, right: serializeExpression(right)}};
            case UnaryOp(op, operand, location):
                {type: "UnaryOp", data: {op: op, operand: serializeExpression(operand)}};
            case Assignment(left, right, location):
                {type: "Assignment", data: {left: serializeExpression(left), right: serializeExpression(right)}};
            case CompoundAssignment(left, op, right, location):
                {type: "CompoundAssignment", data: {left: serializeExpression(left), op: op, right: serializeExpression(right)}};
            case FunctionCall(func, args, location):
                {type: "FunctionCall", data: {func: serializeExpression(func), args: [for (a in args) serializeExpression(a)]}};
            case New(type, args, location):
                {type: "New", data: {type: serializeType(type), args: [for (a in args) serializeExpression(a)]}};
            case Cast(expr, type, location):
                {type: "Cast", data: {expr: serializeExpression(expr), type: serializeType(type)}};
            case Is(expr, type, location):
                {type: "Is", data: {expr: serializeExpression(expr), type: serializeType(type)}};
        };
    }

    /**
     * Serialize type to data format
     */
    private function serializeType(type:YType):YTypeData {
        return switch (type) {
            case YInt: {type: "YInt", data: {}};
            case YFloat: {type: "YFloat", data: {}};
            case YString: {type: "YString", data: {}};
            case YBool: {type: "YBool", data: {}};
            case YArray(elementType): {type: "YArray", data: {elementType: serializeType(elementType)}};
            case YFunction(params, returnType): {type: "YFunction", data: {params: [for (p in params) serializeType(p)], returnType: serializeType(returnType)}};
            case YClass(className): {type: "YClass", data: {className: className}};
            case YEnum(enumName): {type: "YEnum", data: {enumName: enumName}};
            case YStruct(structName): {type: "YStruct", data: {structName: structName}};
            case HaxeType(type): {type: "HaxeType", data: {typeName: Type.getClassName(cast type)}};
            case HaxeClass(classType): {type: "HaxeClass", data: {className: Type.getClassName(classType)}};
            case HaxeAbstract(abstractType): {type: "HaxeAbstract", data: {abstractName: Std.string(abstractType)}};
            case HaxeEnum(enumType): {type: "HaxeEnum", data: {enumName: Type.getEnumName(enumType)}};
            case Dynamic: {type: "Dynamic", data: {}};
            case Void: {type: "Void", data: {}};
            case Unknown: {type: "Unknown", data: {}};
        };
    }

    /**
     * Serialize variable to data format
     */
    private function serializeVar(yvar:YVar):Dynamic {
        return {
            name: yvar.name,
            type: serializeType(yvar.type),
            value: yvar.value
        };
    }

    /**
     * Serialize function body to data format
     */
    private function serializeFunctionBody(body:YFunctionBody):Dynamic {
        return switch (body) {
            case YScript(statements): {type: "YScript", statements: [for (s in statements) serializeStatement(s)]};
            case HaxeCode(code): {type: "HaxeCode", code: code};
            case LuaCode(code): {type: "LuaCode", code: code};
            case Native(func): {type: "Native", func: null}; // Cannot serialize native functions
        };
    }

    /**
     * Serialize current scope types
     */
    private function serializeTypes():Array<YTypeData> {
        // For now, return empty array - could be enhanced to serialize custom types
        return [];
    }

    /**
     * Serialize current scope functions
     */
    private function serializeFunctions():Array<YFunctionData> {
        // For now, return empty array - could be enhanced to serialize functions
        return [];
    }

    /**
     * Serialize current scope classes
     */
    private function serializeClasses():Array<YClassData> {
        // For now, return empty array - could be enhanced to serialize classes
        return [];
    }

    /**
     * Serialize current scope imports
     */
    private function serializeImports():Array<YImportData> {
        // For now, return empty array - could be enhanced to serialize imports
        return [];
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // DESERIALIZATION SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════════════

    /**
     * Deserialize statements from data format
     */
    private function deserializeStatements(data:Array<YStatementData>):Array<YStatement> {
        var result:Array<YStatement> = [];
        for (stmtData in data) {
            result.push(deserializeStatement(stmtData));
        }
        return result;
    }

    /**
     * Deserialize individual statement
     */
    private function deserializeStatement(data:YStatementData):YStatement {
        return switch (data.type) {
            case "Import": Import(data.data.path, data.data.alias, createDefaultLocation());
            case "VarDecl": VarDecl(data.data.name, deserializeType(data.data.type), data.data.init != null ? deserializeExpression(data.data.init) : null, createDefaultLocation());
            case "FuncDecl": {
                var params = [for (p in cast(data.data.params, Array<Dynamic>)) deserializeVar(p)];
                var body = deserializeFunctionBody(data.data.body);
                FuncDecl(data.data.name, params, deserializeType(data.data.returnType), body, createDefaultLocation());
            };
            case "ClassDecl": ClassDecl(data.data.name, data.data.extend, data.data.implement, [for (s in cast(data.data.body, Array<Dynamic>)) deserializeStatement(s)], createDefaultLocation());
            case "If": If(deserializeExpression(data.data.condition), deserializeStatement(data.data.thenStmt), data.data.elseStmt != null ? deserializeStatement(data.data.elseStmt) : null, createDefaultLocation());
            case "While": While(deserializeExpression(data.data.condition), deserializeStatement(data.data.body), createDefaultLocation());
            case "For": For(data.data.init != null ? deserializeStatement(data.data.init) : null, data.data.condition != null ? deserializeExpression(data.data.condition) : null, data.data.increment != null ? deserializeExpression(data.data.increment) : null, deserializeStatement(data.data.body), createDefaultLocation());
            case "ForIn": ForIn(data.data.varName, deserializeType(data.data.varType), deserializeExpression(data.data.iterable), deserializeStatement(data.data.body), createDefaultLocation());
            case "Return": Return(data.data.value != null ? deserializeExpression(data.data.value) : null, createDefaultLocation());
            case "Break": Break(createDefaultLocation());
            case "Continue": Continue(createDefaultLocation());
            case "Block": Block([for (s in cast(data.data.statements, Array<Dynamic>)) deserializeStatement(s)], createDefaultLocation());
            case "Expression": Expression(deserializeExpression(data.data.expr), createDefaultLocation());
            case "HaxeBlock": HaxeBlock(data.data.code, createDefaultLocation());
            case "LuaBlock": LuaBlock(data.data.code, createDefaultLocation());
            default: throw new YScriptRuntimeError('Unknown statement type: ${data.type}');
        };
    }

    /**
     * Deserialize expression from data format
     */
    private function deserializeExpression(data:YExpressionData):YExpression {
        return switch (data.type) {
            case "IntLiteral": IntLiteral(data.data.value, createDefaultLocation());
            case "FloatLiteral": FloatLiteral(data.data.value, createDefaultLocation());
            case "StringLiteral": StringLiteral(data.data.value, createDefaultLocation());
            case "BoolLiteral": BoolLiteral(data.data.value, createDefaultLocation());
            case "NullLiteral": NullLiteral(createDefaultLocation());
            case "ArrayLiteral": ArrayLiteral([for (e in cast(data.data.elements, Array<Dynamic>)) deserializeExpression(e)], createDefaultLocation());
            case "ObjectLiteral": ObjectLiteral([for (f in cast(data.data.fields, Array<Dynamic>)) {name: f.name, value: deserializeExpression(f.value)}], createDefaultLocation());
            case "Identifier": Identifier(data.data.name, createDefaultLocation());
            case "MemberAccess": MemberAccess(deserializeExpression(data.data.object), data.data.member, createDefaultLocation());
            case "ArrayAccess": ArrayAccess(deserializeExpression(data.data.array), deserializeExpression(data.data.index), createDefaultLocation());
            case "SuperCall": SuperCall([for (a in cast(data.data.args, Array<Dynamic>)) deserializeExpression(a)], createDefaultLocation());
            case "SuperMemberAccess": SuperMemberAccess(data.data.member, createDefaultLocation());
            case "SuperMethodCall": SuperMethodCall(data.data.method, [for (a in cast(data.data.args, Array<Dynamic>)) deserializeExpression(a)], createDefaultLocation());
            case "BinaryOp": BinaryOp(deserializeExpression(data.data.left), data.data.op, deserializeExpression(data.data.right), createDefaultLocation());
            case "UnaryOp": UnaryOp(data.data.op, deserializeExpression(data.data.operand), createDefaultLocation());
            case "Assignment": Assignment(deserializeExpression(data.data.left), deserializeExpression(data.data.right), createDefaultLocation());
            case "CompoundAssignment": CompoundAssignment(deserializeExpression(data.data.left), data.data.op, deserializeExpression(data.data.right), createDefaultLocation());
            case "FunctionCall": FunctionCall(deserializeExpression(data.data.func), [for (a in cast(data.data.args, Array<Dynamic>)) deserializeExpression(a)], createDefaultLocation());
            case "New": New(deserializeType(data.data.type), [for (a in cast(data.data.args, Array<Dynamic>)) deserializeExpression(a)], createDefaultLocation());
            case "Cast": Cast(deserializeExpression(data.data.expr), deserializeType(data.data.type), createDefaultLocation());
            case "Is": Is(deserializeExpression(data.data.expr), deserializeType(data.data.type), createDefaultLocation());
            default: throw new YScriptRuntimeError('Unknown expression type: ${data.type}');
        };
    }

    /**
     * Deserialize type from data format
     */
    private function deserializeType(data:YTypeData):YType {
        return switch (data.type) {
            case "YInt": YType.YInt;
            case "YFloat": YType.YFloat;
            case "YString": YType.YString;
            case "YBool": YType.YBool;
            case "YArray": YType.YArray(deserializeType(data.data.elementType));
            case "YFunction": YType.YFunction([for (p in cast(data.data.params, Array<Dynamic>)) deserializeType(p)], deserializeType(data.data.returnType));
            case "YClass": YType.YClass(data.data.className);
            case "YEnum": YType.YEnum(data.data.enumName);
            case "YStruct": YType.YStruct(data.data.structName);
            case "HaxeType": {
                var haxeClass = Type.resolveClass(data.data.typeName);
                haxeClass != null ? YType.HaxeClass(haxeClass) : YType.Dynamic;
            };
            case "HaxeClass": {
                var haxeClass = Type.resolveClass(data.data.className);
                haxeClass != null ? YType.HaxeClass(haxeClass) : YType.Dynamic;
            };
            case "HaxeAbstract": {
                // Try to resolve via AbstractInterpreter using the stored abstract name
                var abstractName = data.data.abstractName;
                if (abstractName != null) {
                    var interp = yutautil.typeregistry.AbstractInterpreter.forAbstract(abstractName);
                    if (interp != null) {
                        YType.HaxeAbstract(interp);
                    } else {
                        YType.Dynamic;
                    }
                } else {
                    YType.Dynamic;
                }
            };
            case "HaxeEnum": {
                var haxeEnum = Type.resolveEnum(data.data.enumName);
                haxeEnum != null ? YType.HaxeEnum(haxeEnum) : YType.Dynamic;
            };
            case "Dynamic": YType.Dynamic;
            case "Void": YType.Void;
            case "Unknown": YType.Unknown;
            default: throw new YScriptRuntimeError('Unknown type: ${data.type}');
        };
    }

    /**
     * Deserialize variable from data format
     */
    private function deserializeVar(data:Dynamic):YVar {
        return new YVar(data.name, deserializeType(data.type), data.value);
    }

    /**
     * Deserialize function body from data format
     */
    private function deserializeFunctionBody(data:Dynamic):YFunctionBody {
        return switch (data.type) {
            case "YScript": YFunctionBody.YScript([for (s in cast(data.statements, Array<Dynamic>)) deserializeStatement(s)]);
            case "HaxeCode": YFunctionBody.HaxeCode(data.code);
            case "LuaCode": YFunctionBody.LuaCode(data.code);
            case "Native": YFunctionBody.Native(null); // Cannot deserialize native functions
            default: throw new YScriptRuntimeError('Unknown function body type: ${data.type}');
        };
    }

    /**
     * Deserialize types (placeholder)
     */
    private function deserializeTypes(data:Array<YTypeData>):Void {
        // Placeholder for type deserialization
    }

    /**
     * Deserialize functions (placeholder)
     */
    private function deserializeFunctions(data:Array<YFunctionData>):Void {
        // Placeholder for function deserialization
    }

    /**
     * Deserialize classes (placeholder)
     */
    private function deserializeClasses(data:Array<YClassData>):Void {
        // Placeholder for class deserialization
    }

    /**
     * Deserialize imports (placeholder)
     */
    private function deserializeImports(data:Array<YImportData>):Void {
        // Placeholder for import deserialization
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// CLASS SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * Internal YScript class definition
 */
class YClassDefinition {
    public var name:String;
    public var superClass:Null<String>;
    public var interfaces:Array<String>;
    public var fields:StringMap<YVar>;
    public var methods:StringMap<Array<YFunction>>;
    public var constructors:Array<YFunction>;
    public var isHaxeClass:Bool; // True if extending a Haxe class
    public var haxeClassName:Null<String>; // Haxe class name if extending one
    public var haxeClassType:Null<Class<Dynamic>>; // Actual Haxe class reference
    public var superClassDef:Null<YClassDefinition>; // Reference to superclass definition if YScript class

    public function new(name:String, superClass:Null<String>, interfaces:Array<String>) {
        this.name = name;
        this.superClass = superClass;
        this.interfaces = interfaces;
        this.fields = new StringMap();
        this.methods = new StringMap();
        this.constructors = [];
        this.isHaxeClass = false;
        this.haxeClassName = null;
        this.superClassDef = null;
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Created class definition for $name');
        }
        #end
    }

    public function addField(field:YVar):Void {
        fields.set(field.name, field);
    }

    public function addMethod(method:YFunction):Void {
        if (!methods.exists(method.name)) {
            methods.set(method.name, []);
        }
        methods.get(method.name).push(method);
    }

    public function addConstructor(constructor:YFunction):Void {
        constructors.push(constructor);
    }

    /**
     * Check if this class extends another class (directly or indirectly)
     */
    public function extendsClass(className:String):Bool {
        if (superClass == className) return true;
        if (superClassDef != null) {
            return superClassDef.extendsClass(className);
        }
        return false;
    }

    /**
     * Check if this class extends a Haxe class (directly or indirectly)
     */
    public function extendsHaxeClass(haxeClass:Class<Dynamic>):Bool {
        if (isHaxeClass && haxeClassType == haxeClass) return true;
        if (superClassDef != null) {
            return superClassDef.extendsHaxeClass(haxeClass);
        }
        return false;
    }

    /**
     * Get field from this class or superclasses
     */
    public function getField(name:String):Null<YVar> {
        if (fields.exists(name)) {
            return fields.get(name);
        }
        if (superClassDef != null) {
            return superClassDef.getField(name);
        }
        return null;
    }

    /**
     * Get method from this class or superclasses
     */
    public function getMethod(name:String):Null<Array<YFunction>> {
        if (methods.exists(name)) {
            return methods.get(name);
        }
        if (superClassDef != null) {
            return superClassDef.getMethod(name);
        }
        return null;
    }


}

/**
 * YScript class instance
 */
class YClassInstance {
    public var className:String;
    public var fields:StringMap<Dynamic>;
    public var classDef:YClassDefinition;
    public var haxeInstance:Null<Dynamic>; // Haxe instance if extending Haxe class
    public var superCalled:Bool = false; // Track if super() was called in constructor
    public var isInConstructor:Bool = false; // Track if currently executing constructor

    public function new(className:String, classDef:YClassDefinition) {
        this.className = className;
        this.classDef = classDef;
        this.fields = new StringMap();
        this.haxeInstance = null;

        // Initialize fields with default values
        for (fieldName in classDef.fields.keys()) {
            var field = classDef.fields.get(fieldName);
            fields.set(fieldName, getDefaultValueForType(field.type));
        }
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Created instance of class $className');
            trace('YScript: Initialized fields: ${fields.keys()}');
        }
        #end
    }

    public function getField(name:String):Dynamic {
        if (fields.exists(name)) {
            return fields.get(name);
        }

        // Check superclass fields through class definition
        var field = classDef.getField(name);
        if (field != null) {
            return field.value;
        }

        // Check Haxe instance if extending Haxe class
        if (haxeInstance != null) {
            return Reflect.field(haxeInstance, name);
        }

        return null;
    }

    public function setField(name:String, value:Dynamic):Void {
        // Check if field exists in this class or superclasses
        var field = classDef.getField(name);
        if (field != null) {
            if (classDef.fields.exists(name)) {
                // Field is in this class
                fields.set(name, value);
            } else {
                // Field is in superclass - we need to handle this properly
                // For now, create a field in this instance
                fields.set(name, value);
            }
        } else if (haxeInstance != null) {
            Reflect.setField(haxeInstance, name, value);
        } else {
            throw new YScriptRuntimeError('Unknown field: $name', null);
        }
    }

    private function getDefaultValueForType(type:YType):Dynamic {
        return switch (type) {
            case YInt: 0;
            case YFloat: 0.0;
            case YString: "";
            case YBool: false;
            case YArray(_): [];
            case Dynamic: null;
            case Void: null;
            case YClass(_): null;
            case YEnum(_): null;
            case YStruct(_): null;
            case HaxeClass(_): null;
            case HaxeAbstract(_): null;
            case HaxeType(_): null;
            case HaxeEnum(_): null;
            case YFunction(_, _): null;
            case Unknown: null;
        };
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// SCOPE MANAGEMENT
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript scope for variable and function management
 */
class YScope {
    private var variables:StringMap<YVar>;
    private var functions:StringMap<YFunction>;
    private var types:StringMap<YType>;
    private var classes:StringMap<YClassDefinition>; // Internal YClass definitions
    private var imports:StringMap<String>; // Import mappings: alias -> full.path.ClassName
    private var parent:Null<YScope>;

    // Script execution context tracking
    public var currentScriptPath:Null<String>;
    public var currentFunction:Null<String>;
    public var currentLocation:Null<YLocation>;

    public function new(?parent:YScope) {
        this.parent = parent;
        variables = new StringMap();
        functions = new StringMap();
        types = new StringMap();
        classes = new StringMap();
        imports = new StringMap();

        // Inherit script context from parent if available
        if (parent != null) {
            this.currentScriptPath = parent.currentScriptPath;
            this.currentFunction = parent.currentFunction;
            this.currentLocation = parent.currentLocation;
        }
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Created new scope. Parent scope: ${parent != null}');
        }
        #end
    }

    public function setVariable(name:String, variable:YVar):Void {
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode && !variables.exists(name)) {
            trace('YVar created: ${variable.name} of type ${YTypeHelper.toString(variable.type)} with initial value: ${variable.value}');
        }
        #end
        variables.set(name, variable);
    }

    public function createVariable(name:String, value:Dynamic, ?type:YTypeable):YVar {
        var variable = new YVar(name, type != null ? type : inferTypeFromValue(value), value);
        setVariable(name, variable);
        return variable;
    }

    public function getVariable(name:String):Null<YVar> {
        if (variables.exists(name)) {
            return variables.get(name);
        }
        return parent != null ? parent.getVariable(name) : null;
    }

    public function hasVariable(name:String):Bool {
        return variables.exists(name) || (parent != null && parent.hasVariable(name));
    }

    public function setFunction(name:String, func:YFunction):Void {
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode && !functions.exists(name)) {
            trace('YFunction created: ${name} with parameters: [${func.parameters.map(p -> YTypeHelper.toString(p.type)).join(", ")}] and return type: ${YTypeHelper.toString(func.returnType)}');
        }
        #end
        functions.set(name, func);
    }

    public function createFunction(name:String, parameters:Array<YTypeable>, returnType:YTypeable, func:haxe.Constraints.Function):YFunction {
        var func = new YFunction(name, parameters.map(p -> makeVarFromTypeable(p, "")), returnType, YFunctionBody.Native(func));
        setFunction(name, func);
        return func;
    }

    private function makeVarFromTypeable(typeable:YTypeable, name:String):YVar {
    function getDefaultValueForType(type:YType):Dynamic { // For internal use.
        return switch (type) {
            case YInt: 0;
            case YFloat: 0.0;
            case YString: "";
            case YBool: false;
            case YArray(_): [];
            case Dynamic: null;
            case Void: null;
            case YClass(_): null;
            case YEnum(_): null;
            case YStruct(_): null;
            case HaxeClass(_): null;
            case HaxeAbstract(_): null;
            case HaxeType(_): null;
            case HaxeEnum(_): null;
            case YFunction(_, _): null;
            case Unknown: null;
        };
    }

        var type = typeable;
        var defaultValue = getDefaultValueForType(type);
        return new YVar(name, type, defaultValue);
    }


    public function getFunction(name:String):Null<YFunction> {
        if (functions.exists(name)) {
            return functions.get(name);
        }
        return parent != null ? parent.getFunction(name) : null;
    }

    public function hasFunction(name:String):Bool {
        return functions.exists(name) || (parent != null ? parent.hasFunction(name) : false);
    }

    public function setType(name:String, type:YTypeable):Void {
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode && !types.exists(name)) {
            trace('YType created: ${name}  (${YTypeHelper.toString(type)})');
        }
        #end
        types.set(name, type);
    }

    public function getType(name:String):Null<YTypeable> {
        if (types.exists(name)) {
            return types.get(name);
        }
        return parent != null ? parent.getType(name) : null;
    }

    public function setClass(name:String, classDef:YClassDefinition):Void {
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode && !classes.exists(name)) {
            trace('YClass created: ${name} - extends: ${classDef.superClass} implements: [${classDef.interfaces.join(", ")}] - fields: [${classDef.fields.keys().toArray().join(", ")}] methods: [${classDef.methods.keys().toArray().join(", ")}]');
        }
        #end
        classes.set(name, classDef);
    }

    public function getClass(name:String):Null<YClassDefinition> {
        if (classes.exists(name)) {
            return classes.get(name);
        }
        return parent != null ? parent.getClass(name) : null;
    }

    public function addImport(fullPath:String, ?alias:String):Void {
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode && !imports.exists(alias ?? fullPath.split(".").pop())) {
            trace('YImport added: ${alias ?? fullPath.split(".").pop()} -> ${fullPath}');
        }
        #end
        var className = alias ?? fullPath.split(".").pop();
        imports.set(className, fullPath);
    }

    public function resolveImport(name:String):Null<String> {
        if (imports.exists(name)) {
            return imports.get(name);
        }
        return parent != null ? parent.resolveImport(name) : null;
    }

    public function setExecutionContext(scriptPath:String, ?functionName:String, ?location:YLocation):Void {
        this.currentScriptPath = scriptPath;
        this.currentFunction = functionName;
        this.currentLocation = location;
    }

    public function getExecutionContext():{scriptPath:String, functionName:String, location:YLocation} {
        return {
            scriptPath: currentScriptPath ?? "<unknown>",
            functionName: currentFunction ?? "<global>",
            location: currentLocation ?? {file: "<unknown>", line: 0, column: 0}
        };
    }



    public function createChild():YScope {
        return new YScope(this);
    }

    public function createChildScope():YScope {
        return createChild();
    }

    /**
     * Get a flattened view of all variables accessible from this scope
     * Handles variable shadowing properly (local variables override parent variables)
     */
    public function getFlattenedVariables():StringMap<Dynamic> {
        var flattened = new StringMap<Dynamic>();

        // Traverse up the scope hierarchy and collect variables
        var currentScope:YScope = this;
        var scopeChain:Array<YScope> = [];

        while (currentScope != null) {
            scopeChain.push(currentScope);
            currentScope = currentScope.parent;
        }

        // Process scopes from root to current (so current scope variables override parent ones)
        scopeChain.reverse();

        for (scope in scopeChain) {
            for (varName in scope.variables.keys()) {
                var yvar = scope.variables.get(varName);
                flattened.set(varName, yvar.value);
            }
        }

        return flattened;
    }

    /**
     * Get a flattened view of all functions accessible from this scope
     * Handles function shadowing properly (local functions override parent functions)
     */
    public function getFlattenedFunctions():StringMap<YFunction> {
        var flattened = new StringMap<YFunction>();

        // Traverse up the scope hierarchy and collect functions
        var currentScope:YScope = this;
        var scopeChain:Array<YScope> = [];

        while (currentScope != null) {
            scopeChain.push(currentScope);
            currentScope = currentScope.parent;
        }

        // Process scopes from root to current (so current scope functions override parent ones)
        scopeChain.reverse();

        for (scope in scopeChain) {
            for (funcName in scope.functions.keys()) {
                var func = scope.functions.get(funcName);
                flattened.set(funcName, func);
            }
        }

        return flattened;
    }

    /**
     * Apply flattened variables back to this scope
     * Used to sync variables back from HScript environment
     */
    public function applyFlattenedVariables(flattened:StringMap<Dynamic>):Void {
        for (varName in flattened.keys()) {
            var value = flattened.get(varName);

            // Find the scope that owns this variable and update it there
            var currentScope:YScope = this;
            var foundScope:YScope = null;

            while (currentScope != null) {
                if (currentScope.variables.exists(varName)) {
                    foundScope = currentScope;
                    break;
                }
                currentScope = currentScope.parent;
            }

            // If we found the owning scope, update it there
            // Otherwise, create it in the current scope
            if (foundScope != null) {
                var yvar = foundScope.variables.get(varName);
                yvar.value = value;
            } else {
                // Variable doesn't exist in hierarchy, create it in current scope
                var inferredType = YScope.inferTypeFromValue(value);
                var yvar = new YVar(varName, inferredType, value);
                this.setVariable(varName, yvar);
            }
        }
    }

		public static function fromStructure(structure:StringMap<Dynamic>):YScope {
				var scope = new YScope();
				for (key in structure.keys()) {
						var value = structure.get(key);
						var inferredType = YScope.inferTypeFromValue(value);
						var yvar = new YVar(key, inferredType, value);
						scope.setVariable(key, yvar);
				}
				return scope;
		}

		public static function fromObject(obj:Dynamic):YScope {
				var scope = new YScope();
				var fields = Reflect.fields(obj);
				for (field in fields) {
						var value = Reflect.field(obj, field);
						var inferredType = YScope.inferTypeFromValue(value);
						var yvar = new YVar(field, inferredType, value);
						scope.setVariable(field, yvar);
				}
				return scope;
		}

    public function destroy():Void {
        variables.clear();
        functions.clear();
        types.clear();
        classes.clear();
        imports.clear();
    }

    /**
     * Infer YScript type from Haxe value
     */
    public static function inferTypeFromValue(value:Dynamic):YType {
        if (value == null) return YType.Dynamic;

        return switch (Type.typeof(value)) {
            case TInt: YType.YInt;
            case TFloat: YType.YFloat;
            case TBool: YType.YBool;
            case TClass(String): YType.YString;
            case TClass(Array): YScope.inferArrayElementType(value);
            case TClass(c): YType.HaxeClass(c);
            case TEnum(e): YType.HaxeEnum(e);
            case TFunction: YType.YFunction([], YType.Dynamic);
            case TObject: YType.Dynamic;
            case TNull: YType.Dynamic;
            case TUnknown: YType.Unknown;
        };
    }

    /**
     * ✅ ARRAY TYPE INFERENCE: Static version for use across the codebase
     */
    public static function inferArrayElementType(array:Dynamic):YType {
        var arr:Array<Dynamic> = cast array;

        // Empty array defaults to Dynamic
        if (arr.length == 0) {
            return YType.YArray(YType.Dynamic);
        }

        // Scan first few elements to determine type pattern
        var sampleSize = Std.int(Math.min(arr.length, 10)); // Sample first 10 elements for performance
        var elementTypes:Array<YType> = [];

        for (i in 0...sampleSize) {
            elementTypes.push(YScope.inferTypeFromValue(arr[i]));
        }

        // Find common type among elements
        var commonType = YScope.findCommonType(elementTypes);
        return YType.YArray(commonType);
    }

    /**
     * Find the most specific common type from a list of types
     */
    public static function findCommonType(types:Array<YType>):YType {
        if (types.length == 0) return YType.Dynamic;
        if (types.length == 1) return types[0];

        var firstType = types[0];
        var allSameType = true;
        var hasInt = false;
        var hasFloat = false;
        var hasNumeric = true;

        for (type in types) {
            if (!Type.enumEq(type, firstType)) {
                allSameType = false;
            }

            switch (type) {
                case YType.YInt: hasInt = true;
                case YType.YFloat: hasFloat = true;
                default: hasNumeric = false;
            }
        }

        // If all elements are exactly the same type
        if (allSameType) {
            return firstType;
        }

        // If mixed Int/Float, use Float as common numeric type
        if (hasNumeric && (hasInt || hasFloat)) {
            return hasFloat ? YType.YFloat : YType.YInt;
        }

        // If all are Haxe classes, try to find common superclass
        var allHaxeClasses = true;
        var haxeClasses:Array<Class<Dynamic>> = [];

        for (type in types) {
            switch (type) {
                case YType.HaxeClass(c):
                    haxeClasses.push(c);
                default:
                    allHaxeClasses = false;
                    break;
            }
        }

        if (allHaxeClasses && haxeClasses.length > 0) {
            // For now, return the first class type - could be enhanced with inheritance checking
            return YType.HaxeClass(haxeClasses[0]);
        }

        // Fallback to Dynamic for mixed types
        return YType.Dynamic;
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // INTROSPECTION API
    // ═══════════════════════════════════════════════════════════════════════════════════════

    public function getAllVariableNames():Array<String> {
        var names = [];
        for (name in variables.keys()) {
            names.push(name);
        }
        if (parent != null) {
            var parentNames = parent.getAllVariableNames();
            for (name in parentNames) {
                if (names.indexOf(name) == -1) {
                    names.push(name);
                }
            }
        }
        return names;
    }

    public function getAllFunctionNames():Array<String> {
        var names = [];
        for (name in functions.keys()) {
            names.push(name);
        }
        if (parent != null) {
            var parentNames = parent.getAllFunctionNames();
            for (name in parentNames) {
                if (names.indexOf(name) == -1) {
                    names.push(name);
                }
            }
        }
        return names;
    }

    public function getVariableInfo(name:String):{name:String, type:String, value:Dynamic} {
        var variable = getVariable(name);
        if (variable == null) return null;
        return {
            name: variable.name,
            type: YTypeHelper.toString(variable.type),
            value: variable.value
        };
    }

    public function getFunctionInfo(name:String):{name:String, parameters:Array<String>, returnType:String} {
        var func = getFunction(name);
        if (func == null) return null;
        var paramNames = [];
        for (param in func.parameters) {
            paramNames.push(param.name + ":" + YTypeHelper.toString(param.type));
        }
        return {
            name: func.name,
            parameters: paramNames,
            returnType: YTypeHelper.toString(func.returnType)
        };
    }

    public function getAllVariables():Array<{name:String, type:String, value:Dynamic}> {
        var result = [];
        for (name in getAllVariableNames()) {
            var info = getVariableInfo(name);
            if (info != null) result.push(info);
        }
        return result;
    }

    public function getAllFunctions():Array<{name:String, parameters:Array<String>, returnType:String}> {
        var result = [];
        for (name in getAllFunctionNames()) {
            var info = getFunctionInfo(name);
            if (info != null) result.push(info);
        }
        return result;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// TOKENIZER
// ═══════════════════════════════════════════════════════════════════════════════════════

enum TokenType {
    // Literals
    TInt(value:Int);
    TFloat(value:Float);
    TString(value:String);
    TBool(value:Bool);

    // Identifiers and keywords
    TIdentifier(name:String);
    TKeyword(keyword:String);

    // Operators
    TOperator(op:String);
    TAssign;

    // Punctuation
    TLeftParen;
    TRightParen;
    TLeftBrace;
    TRightBrace;
    TLeftBracket;
    TRightBracket;
    TComma;
    TSemicolon;
    TColon;
    TDot;

    // Special
    TEOF;
    TNewline;

    // Embedded code blocks
    THaxeBlock(code:String);
    TLuaBlock(code:String);
}

typedef Token = {
    type:TokenType,
    line:Int,
    column:Int
};

/**
 * YScript tokenizer with Haxe-like syntax support
 */
class YScriptTokenizer {
    private var source:String;
    private var pos:Int = 0;
    private var line:Int = 1;
    private var column:Int = 1;

    private var keywords:StringMap<Bool>;

    public function new() {
        setupKeywords();
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Tokenizer initialized');
        }
        #end
    }

    public function tokenize(source:String):Array<Token> {
        this.source = source;
        pos = 0;
        line = 1;
        column = 1;

        var tokens:Array<Token> = [];

        while (pos < source.length) {
            skipWhitespace();

            if (pos >= source.length) break;

            var token = nextToken();
            if (token != null) {
                tokens.push(token);
            }
        }

        tokens.push({type: TEOF, line: line, column: column});
        return tokens;
    }

    private function nextToken():Null<Token> {
        var ch = source.charAt(pos);
        var startLine = line;
        var startColumn = column;

        // Comments
        if (ch == '/' && peek() == '/') {
            skipLineComment();
            return null;
        }

        if (ch == '/' && peek() == '*') {
            skipBlockComment();
            return null;
        }

        // String literals
        if (ch == '"' || ch == "'") {
            return makeToken(TString(readString(ch)), startLine, startColumn);
        }

        // Numbers
        if (isDigit(ch)) {
            return readNumber(startLine, startColumn);
        }

        // Embedded code blocks
        if (ch == 'h' && peekWord() == "haxe") {
            return readHaxeBlock(startLine, startColumn);
        }

        if (ch == 'l' && peekWord() == "lua") {
            return readLuaBlock(startLine, startColumn);
        }

        // Identifiers and keywords
        if (isAlpha(ch) || ch == '_') {
            return readIdentifier(startLine, startColumn);
        }

        // Three-character operators
        var threeChar = source.substr(pos, 3);
        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode && threeChar.charAt(0) == '.') {
            trace('[YScript Tokenizer] Checking three-char: "$threeChar" at pos $pos');
        }
        #end
        if (threeChar == "...") {
            #if !macro
            if (backend.ClientPrefs.data.yscriptDebugMode) {
                trace('[YScript Tokenizer] Found ... range operator at pos $pos');
            }
            #end
            advance(3);
            return makeToken(TOperator(threeChar), startLine, startColumn);
        }

        // Two-character operators
        var twoChar = source.substr(pos, 2);
        switch (twoChar) {
            case "==", "!=", "<=", ">=", "&&", "||", "++", "--", "+=", "-=", "*=", "/=", "%=":
                advance(2);
                return makeToken(TOperator(twoChar), startLine, startColumn);
        }

        // Single-character tokens
        switch (ch) {
            case '(': advance(); return makeToken(TLeftParen, startLine, startColumn);
            case ')': advance(); return makeToken(TRightParen, startLine, startColumn);
            case '{': advance(); return makeToken(TLeftBrace, startLine, startColumn);
            case '}': advance(); return makeToken(TRightBrace, startLine, startColumn);
            case '[': advance(); return makeToken(TLeftBracket, startLine, startColumn);
            case ']': advance(); return makeToken(TRightBracket, startLine, startColumn);
            case ',': advance(); return makeToken(TComma, startLine, startColumn);
            case ';': advance(); return makeToken(TSemicolon, startLine, startColumn);
            case ':': advance(); return makeToken(TColon, startLine, startColumn);
            case '.':
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Tokenizer] Processing single dot at pos $pos, next chars: "${source.substr(pos+1, 2)}"');
                }
                #end
                advance(); return makeToken(TDot, startLine, startColumn);
            case '=': advance(); return makeToken(TAssign, startLine, startColumn);
            case '+', '-', '*', '/', '%', '<', '>', '!':
                advance(); return makeToken(TOperator(ch), startLine, startColumn);
            case '\n':
                advance();
                return makeToken(TNewline, startLine, startColumn);
        }

        throw new YScriptParseError('Unexpected character: $ch', {file: "unknown", line: line, column: column});
    }

    private function readHaxeBlock(startLine:Int, startColumn:Int):Token {
        // Skip "haxe"
        advance(4);
        skipWhitespace();

        if (source.charAt(pos) != '{') {
            throw new YScriptParseError('Expected { after haxe keyword', {file: "unknown", line: line, column: column});
        }

        advance(); // skip {
        var code = readBlockContent();
        return makeToken(THaxeBlock(code), startLine, startColumn);
    }

    private function readLuaBlock(startLine:Int, startColumn:Int):Token {
        // Skip "lua"
        advance(3);
        skipWhitespace();

        if (source.charAt(pos) != '{') {
            throw new YScriptParseError('Expected { after lua keyword', {file: "unknown", line: line, column: column});
        }

        advance(); // skip {
        var code = readBlockContent();
        return makeToken(TLuaBlock(code), startLine, startColumn);
    }

    private function readBlockContent():String {
        var braceCount = 1;
        var start = pos;

        while (pos < source.length && braceCount > 0) {
            var ch = source.charAt(pos);
            if (ch == '{') braceCount++;
            else if (ch == '}') braceCount--;
            advance();
        }

        if (braceCount > 0) {
            throw new YScriptParseError('Unclosed code block', {file: "unknown", line: line, column: column});
        }

        return source.substring(start, pos - 1);
    }

    private function readString(quote:String):String {
        advance(); // Skip opening quote
        var start = pos;

        while (pos < source.length && source.charAt(pos) != quote) {
            if (source.charAt(pos) == '\\') {
                advance(); // Skip escape character
            }
            advance();
        }

        if (pos >= source.length) {
            throw new YScriptParseError('Unterminated string literal', {file: "unknown", line: line, column: column});
        }

        var result = source.substring(start, pos);
        advance(); // Skip closing quote
        return result;
    }

    private function readNumber(startLine:Int, startColumn:Int):Token {
        var start = pos;
        var hasDecimal = false;

        while (pos < source.length && (isDigit(source.charAt(pos)) || source.charAt(pos) == '.')) {
            if (source.charAt(pos) == '.') {
                // Check if this dot is part of a range operator (...)
                // If so, don't consume it as part of the number
                if (pos + 2 < source.length && source.substr(pos, 3) == "...") {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Tokenizer] Found ... range operator while parsing number, stopping number at pos $pos');
                    }
                    #end
                    break; // Stop number parsing, let the ... be handled as a separate operator
                }

                if (hasDecimal) break;
                hasDecimal = true;
            }
            advance();
        }

        var numberStr = source.substring(start, pos);

        if (hasDecimal) {
            return makeToken(TFloat(Std.parseFloat(numberStr)), startLine, startColumn);
        } else {
            return makeToken(TInt(Std.parseInt(numberStr)), startLine, startColumn);
        }
    }

    private function readIdentifier(startLine:Int, startColumn:Int):Token {
        var start = pos;

        while (pos < source.length && (isAlphaNumeric(source.charAt(pos)) || source.charAt(pos) == '_')) {
            advance();
        }

        var identifier = source.substring(start, pos);

        // Check for keywords
        if (keywords.exists(identifier)) {
            return makeToken(TKeyword(identifier), startLine, startColumn);
        }

        // Check for boolean literals
        if (identifier == "true") return makeToken(TBool(true), startLine, startColumn);
        if (identifier == "false") return makeToken(TBool(false), startLine, startColumn);

        return makeToken(TIdentifier(identifier), startLine, startColumn);
    }

    private function setupKeywords():Void {
        keywords = new StringMap();
        var keywordList = [
            "var", "const", "function", "class", "interface", "enum", "struct",
            "extends", "implements", "public", "private", "static", "override",
            "if", "else", "while", "for", "do", "return", "break", "continue",
            "new", "this", "super", "null", "void", "cast", "is", "as", "in",
            "import", "using", "package", "haxe", "lua"
        ];

        for (keyword in keywordList) {
            keywords.set(keyword, true);
        }
    }

    private function makeToken(type:TokenType, line:Int, column:Int):Token {
        return {type: type, line: line, column: column};
    }

    private function advance(?count:Int = 1):Void {
        for (i in 0...count) {
            if (pos < source.length) {
                if (source.charAt(pos) == '\n') {
                    line++;
                    column = 1;
                } else {
                    column++;
                }
                pos++;
            }
        }
    }

    private function peek(?offset:Int = 1):String {
        var peekPos = pos + offset;
        return peekPos < source.length ? source.charAt(peekPos) : String.fromCharCode(0);
    }

    private function peekWord():String {
        var wordPos = pos;
        var word = "";

        while (wordPos < source.length && isAlpha(source.charAt(wordPos))) {
            word += source.charAt(wordPos);
            wordPos++;
        }

        return word;
    }

    private function skipWhitespace():Void {
        while (pos < source.length) {
            var ch = source.charAt(pos);
            if (ch == ' ' || ch == '\t' || ch == '\r') {
                advance();
            } else {
                break;
            }
        }
    }

    private function skipLineComment():Void {
        while (pos < source.length && source.charAt(pos) != '\n') {
            advance();
        }
    }

    private function skipBlockComment():Void {
        advance(2); // Skip /*

        while (pos < source.length - 1) {
            if (source.charAt(pos) == '*' && source.charAt(pos + 1) == '/') {
                advance(2);
                return;
            }
            advance();
        }

        throw new YScriptParseError('Unterminated block comment', {file: "unknown", line: line, column: column});
    }

    private function isDigit(ch:String):Bool {
        return ch >= '0' && ch <= '9';
    }

    private function isAlpha(ch:String):Bool {
        return (ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z');
    }

    private function isAlphaNumeric(ch:String):Bool {
        return isAlpha(ch) || isDigit(ch);
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// PARSER
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript recursive descent parser
 */
class YScriptParser {
    private var tokens:Array<Token>;
    private var current:Int = 0;
    private var currentFile:String = "<unknown>";
    private var errorCollector:YScriptErrorCollector = null;

    public function new() {}

    /**
     * Set error collector for enhanced error handling
     */
    public function setErrorCollector(collector:YScriptErrorCollector):Void {
        this.errorCollector = collector;
    }

    public function parse(source:String, ?filePath:String):Array<YStatement> {
        this.currentFile = filePath ?? "<unknown>";
        var tokenizer = new YScriptTokenizer();
        tokens = tokenizer.tokenize(source);
        current = 0;

        var statements:Array<YStatement> = [];

        while (!isAtEnd()) {
            if (match([TNewline])) continue; // Skip newlines

            var stmt = parseStatement();
            if (stmt != null) {
                statements.push(stmt);
            }
        }
    trace('[YScript Parser] parse() completed with ' + statements.length + ' statements.');

        return statements;
    }

    private function parseStatement():Null<YStatement> {
        try {
            var result = switch (peek().type) {
                case TKeyword("import"): parseImportStatement();
                case TKeyword("var"): parseVarDeclaration();
                case TKeyword("function"):
                    trace('[YScript Parser] parseStatement calling parseFunctionDeclaration()');
                    parseFunctionDeclaration();
                case TKeyword("class"): parseClassDeclaration();
                case TKeyword("if"): parseIfStatement();
                case TKeyword("while"): parseWhileStatement();
                case TKeyword("for"): parseForStatement();
                case TKeyword("return"): parseReturnStatement();
                case TKeyword("break"):
                    var startLocation = getCurrentLocation();
                    advance();
                    YStatement.Break(startLocation);
                case TKeyword("continue"):
                    var startLocation = getCurrentLocation();
                    advance();
                    YStatement.Continue(startLocation);
                case TLeftBrace: parseBlockStatement();
                case THaxeBlock(code):
                    var startLocation = getCurrentLocation();
                    advance();
                    YStatement.HaxeBlock(code, startLocation);
                case TLuaBlock(code):
                    var startLocation = getCurrentLocation();
                    advance();
                    YStatement.LuaBlock(code, startLocation);
                default: parseExpressionStatement();
            };
            trace('[YScript Parser] parseStatement returning: ' + (result != null ? Std.string(result).substring(0, 50) : 'null'));
            return result;
        } catch (e:YScriptError) {
            // Error recovery - skip to next statement
            synchronize();
            trace('[YScript Parser] Caught error: ${e.message}, synchronizing parser.');
            // showErrorWindow("Parsing Error", e.message + " at " + e.location.file + ":" + e.location.line);
            return null;
        }
    }

    private function parseImportStatement():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'import'

        // Parse dotted path like package.subpackage.ClassName
        var pathParts:Array<String> = [];
        pathParts.push(consumeIdentifier("Expected package or class name"));

        while (match([TDot])) {
            pathParts.push(consumeIdentifier("Expected package or class name after '.'"));
        }

        var fullPath = pathParts.join(".");
        var alias:Null<String> = null;

        // Check for "as Alias" syntax
        if (match([TKeyword("as")])) {
            alias = consumeIdentifier("Expected alias name after 'as'");
        }

        consume(TSemicolon, "Expected ';' after import statement");
        return YStatement.Import(fullPath, alias, startLocation);
    }

    private function parseVarDeclaration():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'var'

        var name = consumeIdentifier("Expected variable name");
        trace('YScript Debug: Parsing variable: $name');
        consume(TColon, "Expected ':' after variable name");
        var type = parseType();
        trace('YScript Debug: Variable $name has type: ${YTypeHelper.toString(type)}');

        var init:Null<YExpression> = null;
        if (match([TAssign])) {
            try {
                trace('YScript Debug: Parsing initialization for $name');
                init = parseExpression();
                trace('YScript Debug: Successfully parsed init expression for $name');
                // Add basic type checking for variable initialization
                if (init != null) {
                    var initType = inferExpressionType(init);
                    if (!isTypeCompatible(type, initType)) {
                        // forwardErrorToPlayState('YScript Error: Type mismatch: cannot assign ${YTypeHelper.toString(initType)} to ${YTypeHelper.toString(type)}', true);
                        throw new YScriptTypeError('Type mismatch: cannot assign ${YTypeHelper.toString(initType)} to ${YTypeHelper.toString(type)}', startLocation, currentFile);
                    }
                }
            } catch (e:YScriptError) {
                trace('YScript Debug: Error parsing init for $name: ${e.message}');
                // Re-throw with better location info if not already set
                if (e.location == null) {
                    e.location = startLocation;
                    e.scriptPath = currentFile;
                }
                throw e;
            }
        }

        consume(TSemicolon, "Expected ';' after variable declaration");
        trace('YScript Debug: Successfully parsed variable declaration: $name');
        return YStatement.VarDecl(name, type, init, startLocation);
    }

    private function parseFunctionDeclaration():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'function'

        var name:String;
        // Handle constructor case
        if (match([TKeyword("new")])) {
            name = "new";
        } else {
            name = consumeIdentifier("Expected function name");
        }
        consume(TLeftParen, "Expected '(' after function name");

        var params:Array<YVar> = [];
        if (!check(TRightParen)) {
            do {
                var paramName = consumeIdentifier("Expected parameter name");
                consume(TColon, "Expected ':' after parameter name");
                var paramType = parseType();
                params.push(new YVar(paramName, paramType));
            } while (match([TComma]));
        }

        consume(TRightParen, "Expected ')' after parameters");

        // For constructors, the return type is optional and defaults to Void
        var returnType:YType;
        if (name == "new" && !check(TColon)) {
            // Constructor without explicit return type - default to Void
            returnType = YType.Void;
        } else {
            // Regular function or constructor with explicit return type
            consume(TColon, "Expected ':' before return type");
            returnType = parseType();
        }

        var body:YFunctionBody = null;

        if (check(THaxeBlock(""))) {
            var token = advance();
            body = switch (token.type) {
                case THaxeBlock(code): YFunctionBody.HaxeCode(code);
                default: throw new YScriptParseError("Expected haxe block", getCurrentLocation());
            }
        } else if (check(TLuaBlock(""))) {
            var token = advance();
            body = switch (token.type) {
                case TLuaBlock(code): YFunctionBody.LuaCode(code);
                default: throw new YScriptParseError("Expected lua block", getCurrentLocation());
            }
        } else {

            // Skip any newlines before the opening brace to allow for formatting flexibility
            while (match([TNewline])) {}

            consume(TLeftBrace, "Expected '{' or haxe/lua block before function body");
            var statements:Array<YStatement> = [];

            while (!check(TRightBrace) && !isAtEnd()) {
                if (match([TNewline])) continue;
                var stmt = parseStatement();
                if (stmt != null) statements.push(stmt);
            }

            consume(TRightBrace, "Expected '}' after function body");
            body = YFunctionBody.YScript(statements);
            trace('[YScript Parser] Function body parsed for: ' + name + ' with ' + statements.length + ' statements');
        }

        var result = YStatement.FuncDecl(name, params, returnType, body, startLocation);
        trace('[YScript Parser] Successfully created FuncDecl for: ' + name);
        return result;
    }

    private function parseClassDeclaration():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'class'

        var name = consumeIdentifier("Expected class name");
        trace('[YScript Parser] Parsing class: ' + name);

        var extend:Null<String> = null;
        if (match([TKeyword("extends")])) {
            extend = consumeIdentifier("Expected superclass name");
        }

        var implement:Array<String> = [];
        if (match([TKeyword("implements")])) {
            do {
                implement.push(consumeIdentifier("Expected interface name"));
            } while (match([TComma]));
        }

        consume(TLeftBrace, "Expected '{' before class body");
        trace('[YScript Parser] Starting to parse class body for: ' + name);

        var body:Array<YStatement> = [];
        var bodyIndex = 0;
        while (!check(TRightBrace) && !isAtEnd()) {
            if (match([TNewline])) continue;
            trace('[YScript Parser] Class body statement ' + bodyIndex + ' - current token: ' + Std.string(peek().type));
            try {
                var stmt = parseStatement();
                if (stmt != null) {
                    trace('[YScript Parser] Parsed class body statement ' + bodyIndex + ': ' + Std.string(stmt).substring(0, 80));
                    body.push(stmt);
                    bodyIndex++;
                } else {
                    trace('[YScript Parser] parseStatement returned null for token: ' + Std.string(peek().type));
                }
            } catch (e:Dynamic) {
                trace('[YScript Parser] ERROR parsing class body statement ' + bodyIndex + ': ' + e);
                trace('[YScript Parser] Current token: ' + Std.string(peek().type));
                trace('[YScript Parser] Breaking from class body parsing due to error');
                break;
            }
        }

        trace('[YScript Parser] Finished parsing class body for ' + name + ' with ' + body.length + ' statements');
        consume(TRightBrace, "Expected '}' after class body");

        return YStatement.ClassDecl(name, extend, implement, body, startLocation);
    }

    private function parseIfStatement():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'if'

        consume(TLeftParen, "Expected '(' after 'if'");
        var condition = parseExpression();
        consume(TRightParen, "Expected ')' after if condition");

        var thenStmt = parseStatement();
        var elseStmt:Null<YStatement> = null;

        if (match([TKeyword("else")])) {
            elseStmt = parseStatement();
        }

        return YStatement.If(condition, thenStmt, elseStmt, startLocation);
    }

    private function parseWhileStatement():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'while'

        consume(TLeftParen, "Expected '(' after 'while'");
        var condition = parseExpression();
        consume(TRightParen, "Expected ')' after while condition");

        var body = parseStatement();
        return YStatement.While(condition, body, startLocation);
    }

    private function parseForStatement():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'for'

        consume(TLeftParen, "Expected '(' after 'for'");

        // Look ahead to determine if this is a for-in loop or C-style for loop
        // We need to peek ahead to see if there's an 'in' keyword
        var currentPos = current;
        var isForInLoop = false;

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] parseForStatement: Looking ahead to determine for loop type, starting at position $currentPos');
        }
        #end

        // Look ahead to find 'in' keyword before semicolon or closing paren
        while (currentPos < tokens.length && !isAtEndAt(currentPos)) {
            var token = tokens[currentPos];
            #if !macro
            if (backend.ClientPrefs.data.yscriptDebugMode) {
                trace('[YScript Debug] parseForStatement: Looking at token ${Std.string(token.type)} at position $currentPos');
            }
            #end
            switch (token.type) {
                case TKeyword("in"):
                    isForInLoop = true;
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] parseForStatement: Found "in" keyword! Using for-in parsing');
                    }
                    #end
                    break;
                case TSemicolon | TRightParen:
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] parseForStatement: Found ${Std.string(token.type)} before "in", using traditional for loop');
                    }
                    #end
                    break; // Stop looking
                default:
            }
            currentPos++;
        }

        if (isForInLoop) {
            #if !macro
            if (backend.ClientPrefs.data.yscriptDebugMode) {
                trace('[YScript Debug] parseForStatement: Using for-in parsing path');
            }
            #end
            // Parse for-in style: for (variable in iterable)
            return parseForInStatement(startLocation);
        } else {
            #if !macro
            if (backend.ClientPrefs.data.yscriptDebugMode) {
                trace('[YScript Debug] parseForStatement: Using traditional for loop parsing path');
            }
            #end
            // Parse C-style: for (init; condition; increment)
            return parseTraditionalForStatement(startLocation);
        }
    }

    private function parseForInStatement(startLocation:YLocation):YStatement {
        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] parseForInStatement: Starting to parse for-in loop');
        }
        #end

        // Parse variable declaration or identifier
        var varName:String;
        var varType:YType = YType.Dynamic;

        if (match([TKeyword("var")])) {
            varName = consumeIdentifier("Expected variable name");
            if (match([TColon])) {
                varType = parseType();
            }
        } else {
            varName = consumeIdentifier("Expected variable name");
        }

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] parseForInStatement: Parsed variable $varName, trying to consume "in" keyword');
        }
        #end

        consume(TKeyword("in"), "Expected 'in' keyword");

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] parseForInStatement: Consumed "in" keyword, parsing iterable expression');
        }
        #end

        var iterable = parseExpression();

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] parseForInStatement: Parsed iterable expression: ${Std.string(iterable)}');
        }
        #end
        consume(TRightParen, "Expected ')' after for-in clauses");

        var body = parseStatement();

        // All for-in loops (both ranges and generic iterables) use ForIn statement.
        // Range expressions (0...100) are detected and handled at runtime in the ForIn handler.
        return YStatement.ForIn(varName, varType, iterable, body, startLocation);
    }

    private function parseTraditionalForStatement(startLocation:YLocation):YStatement {
        // Original C-style parsing logic
        var init:Null<YStatement> = null;
        if (!check(TSemicolon)) {
            init = match([TKeyword("var")]) ? parseVarDeclaration() : parseExpressionStatement();
        } else {
            advance(); // consume semicolon
        }

        var condition:Null<YExpression> = null;
        if (!check(TSemicolon)) {
            condition = parseExpression();
        }
        consume(TSemicolon, "Expected ';' after for loop condition");

        var increment:Null<YExpression> = null;
        if (!check(TRightParen)) {
            increment = parseExpression();
        }
        consume(TRightParen, "Expected ')' after for clauses");

        var body = parseStatement();
        return YStatement.For(init, condition, increment, body, startLocation);
    }

    private function isAtEndAt(pos:Int):Bool {
        return pos >= tokens.length;
    }

    private function parseReturnStatement():YStatement {
        var startLocation = getCurrentLocation();
        advance(); // consume 'return'

        var value:Null<YExpression> = null;
        if (!check(TSemicolon)) {
            value = parseExpression();
        }

        consume(TSemicolon, "Expected ';' after return value");
        return YStatement.Return(value, startLocation);
    }

    private function parseBlockStatement():YStatement {
        var startLocation = getCurrentLocation();
        consume(TLeftBrace, "Expected '{'");

        var statements:Array<YStatement> = [];
        while (!check(TRightBrace) && !isAtEnd()) {
            if (match([TNewline])) continue;
            var stmt = parseStatement();
            if (stmt != null) statements.push(stmt);
        }

        consume(TRightBrace, "Expected '}'");
        return YStatement.Block(statements, startLocation);
    }

    private function parseExpressionStatement():YStatement {
        var startLocation = getCurrentLocation();
        var expr = parseExpression();
        consume(TSemicolon, "Expected ';' after expression");
        return YStatement.Expression(expr, startLocation);
    }

    private function parseExpression():YExpression {
        return parseAssignment();
    }

    private function parseAssignment():YExpression {
        var expr = parseLogicalOr();

        // Check compound assignments first (they are longer and more specific)
        if (matchOperator("+=") || matchOperator("-=") || matchOperator("*=") || matchOperator("/=") || matchOperator("%=")) {
            var startLocation = getCurrentLocation();
            var op = getOperatorString(previous().type);
            var right = parseAssignment();
            return YExpression.CompoundAssignment(expr, op, right, startLocation);
        }

        // Check regular assignment after compound assignments
        if (match([TAssign])) {
            var startLocation = getCurrentLocation();
            var right = parseAssignment();
            return YExpression.Assignment(expr, right, startLocation);
        }

        return expr;
    }

    private function parseLogicalOr():YExpression {
        var expr = parseLogicalAnd();

        while (matchOperator("||")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseLogicalAnd();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseLogicalAnd():YExpression {
        var expr = parseEquality();

        while (matchOperator("&&")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseEquality();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseEquality():YExpression {
        var expr = parseComparison();

        while (matchOperator("==") || matchOperator("!=")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseComparison();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseComparison():YExpression {
        var expr = parseRange();

        while (matchOperator(">") || matchOperator(">=") || matchOperator("<") || matchOperator("<=")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseRange();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseRange():YExpression {
        var expr = parseAddition();

        while (matchOperator("...")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseAddition();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseAddition():YExpression {
        var expr = parseMultiplication();

        while (matchOperator("+") || matchOperator("-")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseMultiplication();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseMultiplication():YExpression {
        var expr = parseUnary();

        while (matchOperator("*") || matchOperator("/") || matchOperator("%")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseUnary();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right, startLocation);
        }

        return expr;
    }

    private function parseUnary():YExpression {
        if (matchOperator("!") || matchOperator("-") || matchOperator("+")) {
            var startLocation = getCurrentLocation();
            var op = previous().type;
            var right = parseUnary();
            return YExpression.UnaryOp(getOperatorString(op), right, startLocation);
        }

        return parseCall();
    }

    private function parseCall():YExpression {
        var expr = parsePrimary();

        while (true) {
            if (match([TLeftParen])) {
                expr = finishCall(expr);
            } else if (match([TDot])) {
                var startLocation = getCurrentLocation();
                var name = consumeIdentifier("Expected property name after '.'");
                expr = YExpression.MemberAccess(expr, name, startLocation);
            } else if (match([TLeftBracket])) {
                var startLocation = getCurrentLocation();
                var index = parseExpression();
                consume(TRightBracket, "Expected ']' after array index");
                expr = YExpression.ArrayAccess(expr, index, startLocation);
            } else {
                break;
            }
        }

        return expr;
    }

    private function finishCall(callee:YExpression):YExpression {
        var startLocation = getCurrentLocation();
        var args:Array<YExpression> = [];

        if (!check(TRightParen)) {
            do {
                args.push(parseExpression());
            } while (match([TComma]));
        }

        consume(TRightParen, "Expected ')' after arguments");
        return YExpression.FunctionCall(callee, args, startLocation);
    }

    private function parsePrimary():YExpression {
        return switch (peek().type) {
            case TBool(value):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.BoolLiteral(value, startLocation);
            case TInt(value):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.IntLiteral(value, startLocation);
            case TFloat(value):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.FloatLiteral(value, startLocation);
            case TString(value):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.StringLiteral(value, startLocation);
            case TIdentifier(name):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.Identifier(name, startLocation);
            case TKeyword("null"):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.NullLiteral(startLocation);
            case TKeyword("this"):
                var startLocation = getCurrentLocation();
                advance();
                YExpression.Identifier("this", startLocation);
            case TKeyword("super"): parseSuperExpression();
            case TKeyword("new"): parseNewExpression();
            case TLeftParen: parseGrouping();
            case TLeftBracket: parseArrayLiteral();
            case TLeftBrace: parseObjectLiteral();
            default: throw new YScriptParseError('Unexpected token: ${peek().type}', getCurrentLocation());
        }
    }

    private function parseSuperExpression():YExpression {
        var startLocation = getCurrentLocation();
        advance(); // consume 'super'

        if (match([TLeftParen])) {
            // super(args) - constructor call
            var args:Array<YExpression> = [];
            if (!check(TRightParen)) {
                do {
                    args.push(parseExpression());
                } while (match([TComma]));
            }
            consume(TRightParen, "Expected ')' after super constructor arguments");
            return YExpression.SuperCall(args, startLocation);
        } else if (match([TDot])) {
            // super.member or super.method(args)
            var memberName = consumeIdentifier("Expected method or field name after 'super.'");

            if (match([TLeftParen])) {
                // super.method(args)
                var args:Array<YExpression> = [];
                if (!check(TRightParen)) {
                    do {
                        args.push(parseExpression());
                    } while (match([TComma]));
                }
                consume(TRightParen, "Expected ')' after super method arguments");
                return YExpression.SuperMethodCall(memberName, args, startLocation);
            } else {
                // super.field
                return YExpression.SuperMemberAccess(memberName, startLocation);
            }
        } else {
            throw new YScriptParseError("Expected '(' or '.' after 'super'", getCurrentLocation());
        }
    }

    private function parseNewExpression():YExpression {
        var startLocation = getCurrentLocation();
        advance(); // consume 'new'
        var type = parseType();
        consume(TLeftParen, "Expected '(' after type in new expression");

        var args:Array<YExpression> = [];
        if (!check(TRightParen)) {
            do {
                args.push(parseExpression());
            } while (match([TComma]));
        }

        consume(TRightParen, "Expected ')' after constructor arguments");
        return YExpression.New(type, args, startLocation);
    }

    private function parseGrouping():YExpression {
        consume(TLeftParen, "Expected '('");
        var expr = parseExpression();
        consume(TRightParen, "Expected ')' after expression");
        return expr;
    }

    private function parseArrayLiteral():YExpression {
        var startLocation = getCurrentLocation();
        consume(TLeftBracket, "Expected '['");
        var elements:Array<YExpression> = [];

        // Skip any newlines after opening bracket
        while (match([TNewline])) {}

        if (!check(TRightBracket)) {
            do {
                // Skip newlines before each element
                while (match([TNewline])) {}
                elements.push(parseExpression());
                // Skip newlines after each element
                while (match([TNewline])) {}
            } while (match([TComma]));
        }

        // Skip any newlines before closing bracket
        while (match([TNewline])) {}
        consume(TRightBracket, "Expected ']' after array elements");
        return YExpression.ArrayLiteral(elements, startLocation);
    }

    private function parseObjectLiteral():YExpression {
        var startLocation = getCurrentLocation();
        consume(TLeftBrace, "Expected '{'");
        trace('YScript Debug: parseObjectLiteral() started');
        var fields:Array<{name:String, value:YExpression}> = [];

        // Skip any newlines after opening brace
        while (match([TNewline])) {}

        if (!check(TRightBrace)) {
            do {
                // Skip newlines before each field
                while (match([TNewline])) {}
                trace('YScript Debug: parseObjectLiteral() parsing field, current token: ${peek().type}');
                var name = consumeIdentifier("Expected field name");
                trace('YScript Debug: parseObjectLiteral() field name: $name');
                consume(TColon, "Expected ':' after field name");
                var value = parseExpression();
                trace('YScript Debug: parseObjectLiteral() field value parsed');
                fields.push({name: name, value: value});
                // Skip newlines after each field
                while (match([TNewline])) {}
            } while (match([TComma]));
        }

        // Skip any newlines before closing brace
        while (match([TNewline])) {}
        consume(TRightBrace, "Expected '}' after object fields");
        trace('YScript Debug: parseObjectLiteral() completed with ${fields.length} fields');
        return YExpression.ObjectLiteral(fields, startLocation);
    }

    private function parseType():YType {
        trace('YScript Debug: parseType() called, current token: ${peek().type}');

        if (match([TIdentifier("Int")])) {
            trace('YScript Debug: Matched Int type');
            return YType.YInt;
        }
        if (match([TIdentifier("Float")])) {
            trace('YScript Debug: Matched Float type');
            return YType.YFloat;
        }
        if (match([TIdentifier("String")])) {
            trace('YScript Debug: Matched String type');
            return YType.YString;
        }
        if (match([TIdentifier("Bool")])) {
            trace('YScript Debug: Matched Bool type');
            return YType.YBool;
        }
        if (match([TIdentifier("Dynamic")])) {
            trace('YScript Debug: Matched Dynamic type');
            return YType.Dynamic;
        }
        if (match([TIdentifier("Void")])) {
            trace('YScript Debug: Matched Void type');
            return YType.Void;
        }

        // Array type
        if (match([TIdentifier("Array")])) {
            trace('YScript Debug: Matched Array type');
            consume(TOperator("<"), "Expected '<' after Array");
            var elementType = parseType();
            consume(TOperator(">"), "Expected '>' after Array element type");
            return YType.YArray(elementType);
        }

        // Custom or Haxe type - handle dotted paths like states.PlayState
        var typeParts:Array<String> = [];
        typeParts.push(consumeIdentifier("Expected type name"));

        // Parse dotted path like package.subpackage.ClassName
        while (match([TDot])) {
            typeParts.push(consumeIdentifier("Expected type name after '.'"));
        }

        var fullTypeName = typeParts.join(".");
        trace('YScript Debug: Using custom/Haxe type: $fullTypeName');

        // Check if this is an abstract type first
        try {
            var abstractInterpreter = yutautil.typeregistry.AbstractInterpreter.forAbstract(fullTypeName);
            if (abstractInterpreter != null) {
                trace('YScript Debug: Resolved $fullTypeName as abstract type');
                return YType.HaxeAbstract(abstractInterpreter);
            }
        } catch (e:Dynamic) {
            // Not an abstract type, continue with class check
            trace('YScript Debug: $fullTypeName is not an abstract type: $e');
        }

        // Fall back to class type
        return YType.YClass(fullTypeName); // Will be resolved later
    }

    // Helper methods
    private function match(types:Array<TokenType>):Bool {
        for (type in types) {
            if (check(type)) {
                advance();
                return true;
            }
        }
        return false;
    }

    private function matchOperator(op:String):Bool {
        return check(TOperator(op)) ? (advance() != null) : false;
    }

    private function check(type:TokenType):Bool {
        if (isAtEnd()) return false;

        return switch (type) {
            case THaxeBlock(_):
                switch (peek().type) {
                    case THaxeBlock(_): true;
                    default: false;
                }
            case TLuaBlock(_):
                switch (peek().type) {
                    case TLuaBlock(_): true;
                    default: false;
                }
            default: Type.enumEq(peek().type, type);
        }
    }

    private function advance():Token {
        if (!isAtEnd()) current++;
        return previous();
    }

    private function isAtEnd():Bool {
        return peek().type == TEOF;
    }

    private function peek():Token {
        return tokens[current];
    }

    private function previous():Token {
        return tokens[current - 1];
    }

    private function consume(type:TokenType, message:String):Token {
        if (check(type)) return advance();

        throw new YScriptParseError(message, getCurrentLocation());
    }

    private function consumeIdentifier(message:String):String {
        return switch (peek().type) {
            case TIdentifier(name): advance(); name;
            default: throw new YScriptParseError(message, getCurrentLocation());
        }
    }

    private function getOperatorString(type:TokenType):String {
        return switch (type) {
            case TOperator(op): op;
            default: "unknown";
        }
    }

    private function getCurrentLocation():YLocation {
        var token = peek();
        return {
            file: currentFile,
            line: token.line,
            column: token.column
        };
    }

    private function synchronize():Void {
        advance();

        while (!isAtEnd()) {
            if (previous().type == TSemicolon) return;

            switch (peek().type) {
                case TKeyword("class"), TKeyword("function"), TKeyword("var"),
                     TKeyword("for"), TKeyword("if"), TKeyword("while"),
                     TKeyword("return"): return;
                default: advance();
            }
        }
    }

    /**
     * Parse-time type compatibility checking
     */
    private function isTypeCompatible(targetType:YType, valueType:YType):Bool {
        // Exact match
        if (Type.enumEq(targetType, valueType)) return true;

        // Dynamic accepts anything
        if (targetType == YType.Dynamic || valueType == YType.Dynamic) return true;

        // Null literal can be assigned to most non-primitive types
        if (valueType == YType.Dynamic) {
            switch (targetType) {
                case YType.YInt | YType.YFloat | YType.YBool: return false;
                default: return true; // Allow null assignment to objects, arrays, etc.
            }
        }

        // Numeric compatibility
        switch [targetType, valueType] {
            case [YType.YFloat, YType.YInt]: return true; // Int -> Float is safe
            case [YType.YInt, YType.YFloat]: return false; // Float -> Int requires explicit cast
            default:
        }

        // String concatenation compatibility
        if (targetType == YType.YString) {
            switch (valueType) {
                case YType.YInt | YType.YFloat | YType.YBool: return true; // Auto-conversion
                default:
            }
        }

        // Array element compatibility
        switch [targetType, valueType] {
            case [YType.YArray(targetElement), YType.YArray(valueElement)]:
                return isTypeCompatible(targetElement, valueElement);
            default:
        }

        // Class inheritance compatibility
        switch [targetType, valueType] {
            case [YType.HaxeClass(targetClass), YType.HaxeClass(valueClass)]:
                return isHaxeClassCompatible(targetClass, valueClass);
            case [YType.YClass(targetName), YType.YClass(valueName)]:
                return isYScriptClassCompatible(targetName, valueName);
            case [YType.HaxeClass(targetClass), YType.YClass(valueName)]:
                // YScript class extending Haxe class - need to check if YScript class extends the Haxe class
                return checkYScriptExtendsHaxe(valueName, targetClass);
            case [YType.YClass(targetName), _]:
                // Check if the YClass target is actually an abstract type
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] isTypeCompatible: Checking if YClass($targetName) is actually an abstract type');
                }
                #end
                var abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(targetName);
                if (abstractInterp != null) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: $targetName is an abstract type, checking compatibility with ${YTypeHelper.toString(valueType)}');
                    }
                    #end

                    // Convert valueType to string for TypeHandler
                    var valueTypeStr = parserYTypeToString(valueType);
                    if (valueTypeStr != null) {
                        var canAssign = yutautil.TypeHandler.canAssignToAbstract(valueTypeStr, abstractInterp.abstractPath);
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] isTypeCompatible: TypeHandler.canAssignToAbstract($valueTypeStr, ${abstractInterp.abstractPath}) = $canAssign');
                        }
                        #end
                        if (canAssign) return true;
                    }

                    // Direct primitive type checks
                    switch (valueType) {
                        case YInt:
                            var matches = abstractInterp.matchesUnderlyingType(0) || abstractInterp.canConvertFrom(0);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YInt -> ${abstractInterp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YFloat:
                            var matches = abstractInterp.matchesUnderlyingType(0.0) || abstractInterp.canConvertFrom(0.0);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YFloat -> ${abstractInterp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YString:
                            var matches = abstractInterp.matchesUnderlyingType("") || abstractInterp.canConvertFrom("");
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YString -> ${abstractInterp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YBool:
                            var matches = abstractInterp.matchesUnderlyingType(true) || abstractInterp.canConvertFrom(true);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YBool -> ${abstractInterp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        default:

                    }
                }
            default:
        }

        // Function compatibility
        switch [targetType, valueType] {
            case [YType.YFunction(targetParams, targetReturn), YType.YFunction(valueParams, valueReturn)]:
                if (targetParams.length != valueParams.length) return false;
                for (i in 0...targetParams.length) {
                    if (!isTypeCompatible(targetParams[i], valueParams[i])) return false;
                }
                return isTypeCompatible(targetReturn, valueReturn);
            default:
        }

        // Abstract type compatibility via @:from / @:to implicit conversions
        // Target is an abstract: check if value type can be accepted via @:from conversions
        switch (targetType) {
            case HaxeAbstract(abstractType):
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] isTypeCompatible: Checking abstract target type, abstractType: ${Std.string(abstractType)}');
                }
                #end
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: AbstractInterpreter found for: ${interp.abstractPath}');
                    }
                    #end

                    // Convert valueType to a type string for TypeHandler
                    var valueTypeStr = parserYTypeToString(valueType);
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: valueTypeStr = $valueTypeStr');
                    }
                    #end
                    if (valueTypeStr != null) {
                        var canAssign = yutautil.TypeHandler.canAssignToAbstract(valueTypeStr, interp.abstractPath);
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] isTypeCompatible: TypeHandler.canAssignToAbstract($valueTypeStr, ${interp.abstractPath}) = $canAssign');
                        }
                        #end
                        if (canAssign) return true;
                    }

                    // Direct checks for primitives
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: Checking primitive compatibility for valueType: ${YTypeHelper.toString(valueType)}');
                    }
                    #end
                    switch (valueType) {
                        case YInt:
                            var matches = interp.matchesUnderlyingType(0) || interp.canConvertFrom(0);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YInt -> ${interp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YFloat:
                            var matches = interp.matchesUnderlyingType(0.0) || interp.canConvertFrom(0.0);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YFloat -> ${interp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YString:
                            var matches = interp.matchesUnderlyingType("") || interp.canConvertFrom("");
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YString -> ${interp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case YBool:
                            var matches = interp.matchesUnderlyingType(true) || interp.canConvertFrom(true);
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] isTypeCompatible: YBool -> ${interp.abstractPath} = $matches');
                            }
                            #end
                            if (matches) return true;
                        case HaxeAbstract(otherAbstract):
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                if (interp.abstractPath == otherInterp.abstractPath) return true;
                                // Check if the other abstract's @:to outputs can feed into this abstract's @:from
                                var otherToTypes = otherInterp.getToTypes();
                                for (toEntry in otherToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, interp.abstractPath)) return true;
                                }
                                if (otherInterp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(otherInterp.underlyingType, interp.abstractPath)) return true;
                                }
                            }
                        case HaxeClass(cls):
                            var className = Type.getClassName(cls);
                            if (className != null && yutautil.TypeHandler.canAssignToAbstract(className, interp.abstractPath)) return true;
                        case _:
                    }

                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: Abstract type check failed, no conversion found for ${YTypeHelper.toString(valueType)} -> ${interp.abstractPath}');
                    }
                    #end
                } else {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] isTypeCompatible: Abstract type is not an AbstractInterpreter: ${Std.string(abstractType)}');
                    }
                    #end
                }
            default:
        }

        // If the value is an abstract type, check if it can be converted TO the target
        switch (valueType) {
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;

                    var targetTypeStr = parserYTypeToString(targetType);
                    if (targetTypeStr != null) {
                        if (yutautil.TypeHandler.canAbstractOutputType(interp.abstractPath, targetTypeStr)) return true;
                    }

                    switch (targetType) {
                        case YInt:
                            if (interp.canConvertTo("Int")) return true;
                        case YFloat:
                            if (interp.canConvertTo("Float")) return true;
                        case YString:
                            if (interp.canConvertTo("String")) return true;
                        case YBool:
                            if (interp.canConvertTo("Bool")) return true;
                        case HaxeClass(cls):
                            var className = Type.getClassName(cls);
                            if (className != null && interp.canConvertTo(className)) return true;
                        case HaxeAbstract(otherAbstract):
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                var myToTypes = interp.getToTypes();
                                for (toEntry in myToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, otherInterp.abstractPath)) return true;
                                }
                                if (interp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(interp.underlyingType, otherInterp.abstractPath)) return true;
                                }
                            }
                        case _:
                    }
                }
            default:
        }

        // Typedef compatibility
        switch [targetType, valueType] {
            case [YType.YStruct(targetStructName), YType.YStruct(valueStructName)]:
                var resolvedTarget = yutautil.TypeHandler.resolveTypedef(targetStructName);
                var resolvedValue = yutautil.TypeHandler.resolveTypedef(valueStructName);
                if (resolvedTarget != null && resolvedValue != null) {
                    return yutautil.TypeHandler.isCompatible(resolvedValue, resolvedTarget);
                }
                return targetStructName == valueStructName;
            default:
        }

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] isTypeCompatible: No compatibility found, returning false for ${YTypeHelper.toString(valueType)} -> ${YTypeHelper.toString(targetType)}');
        }
        #end
        return false;
    }

    /**
     * Convert a YType to a type string for use with TypeHandler (parser-side).
     * Returns null if the YType cannot be meaningfully converted.
     */
    private function parserYTypeToString(ytype:YType):Null<String> {
        return switch (ytype) {
            case YInt: "Int";
            case YFloat: "Float";
            case YString: "String";
            case YBool: "Bool";
            case Dynamic: "Dynamic";
            case Void: "Void";
            case YArray(elementType): "Array";
            case YFunction(_, _): "Function";
            case YClass(name): name;
            case YEnum(name): name;
            case YStruct(name): name;
            case HaxeClass(c): Type.getClassName(c);
            case HaxeEnum(e): Type.getEnumName(e);
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                    interp.abstractPath;
                } else null;
            case HaxeType(t): Std.string(t);
            case Unknown: null;
        };
    }

    /**
     * Enhanced parse-time type inference from expressions
     */
    private function inferExpressionType(expr:YExpression):YType {
        return switch (expr) {
            case IntLiteral(_): YType.YInt;
            case FloatLiteral(_): YType.YFloat;
            case StringLiteral(_, location): YType.YString;
            case BoolLiteral(_, location): YType.YBool;
            case NullLiteral(location): YType.Dynamic; // Null can be assigned to most types

            case ArrayLiteral(elements, location):
                if (elements.length == 0) {
                    YType.YArray(YType.Dynamic); // Empty array
                } else {
                    // Infer element type from first element
                    var elementType = inferExpressionType(elements[0]);
                    YType.YArray(elementType);
                }

            case ObjectLiteral(_, location):
                YType.Dynamic; // Object literals are Dynamic

            case Identifier(name, location):
                // For parse-time, return Dynamic - runtime will do proper checking
                YType.Dynamic;

            case MemberAccess(object, member, location):
                // Object member access
                YType.Dynamic;

            case ArrayAccess(array, index, location):
                // Array element access
                var arrayType = inferExpressionType(array);
                switch (arrayType) {
                    case YType.YArray(elementType): elementType;
                    default: YType.Dynamic;
                }

            case BinaryOp(left, op, right, location):
                var leftType = inferExpressionType(left);
                var rightType = inferExpressionType(right);

                switch (op) {
                    case "+":
                        // String concatenation has priority
                        if (leftType == YType.YString || rightType == YType.YString) {
                            YType.YString;
                        }
                        // Numeric addition with type promotion
                        else if (leftType == YType.YFloat || rightType == YType.YFloat) {
                            YType.YFloat;
                        }
                        else if (leftType == YType.YInt && rightType == YType.YInt) {
                            YType.YInt;
                        }
                        else {
                            YType.Dynamic;
                        }
                    case "-" | "*" | "/" | "%":
                        // Arithmetic operations with type promotion
                        if (leftType == YType.YFloat || rightType == YType.YFloat) {
                            YType.YFloat;
                        }
                        else if (leftType == YType.YInt && rightType == YType.YInt) {
                            YType.YInt;
                        }
                        else {
                            YType.Dynamic;
                        }
                    case "==" | "!=" | "<" | ">" | "<=" | ">=" | "&&" | "||":
                        // Comparison and logical operations
                        YType.YBool;
                    default:
                        YType.Dynamic;
                }

            case UnaryOp(op, operand, location):
                switch (op) {
                    case "!" | "not": YType.YBool;
                    case "-" | "+":
                        var operandType = inferExpressionType(operand);
                        switch (operandType) {
                            case YType.YInt: YType.YInt;
                            case YType.YFloat: YType.YFloat;
                            default: YType.Dynamic;
                        }
                    default: YType.Dynamic;
                }

            case FunctionCall(func, args, location):
                // Function calls need signature analysis for proper typing
                YType.Dynamic;

            case New(type, args, location):
                // Constructor calls return the specified type
                type;

            case Cast(expr, type, location):
                // Cast expressions return the target type
                type;

            case Is(expr, type, location):
                // Type checks return Bool
                YType.YBool;

            case Assignment(left, right, location):
                // Assignment expressions return the type of the right-hand side
                inferExpressionType(right);

            case CompoundAssignment(left, op, right, location):
                // Compound assignment expressions return the type of the left-hand side (which should be compatible with the operation result)
                inferExpressionType(left);

            case SuperCall(args, location):
                // Super call expressions return Dynamic for now
                YType.Dynamic;

            case SuperMemberAccess(_) | SuperMethodCall(_, _):
                // Super expressions return Dynamic for now
                YType.Dynamic;
        }
    }

    /**
     * Check if Haxe class inheritance is compatible
     */
    private function isHaxeClassCompatible(targetClass:Class<Dynamic>, valueClass:Class<Dynamic>):Bool {
        if (targetClass == valueClass) return true;

        try {
            // Check if valueClass is a subclass of targetClass
            var currentClass = valueClass;
            while (currentClass != null) {
                if (currentClass == targetClass) return true;
                currentClass = Type.getSuperClass(currentClass);
            }
            return false;
        } catch (e:Dynamic) {
            // If reflection fails, allow assignment (conservative approach)
            return true;
        }
    }

    /**
     * Check if YScript class inheritance is compatible
     */
    private function isYScriptClassCompatible(targetName:String, valueName:String):Bool {
        if (targetName == valueName) return true;

        // For parse-time checking, we'd need access to class definitions
        // For now, return false for different class names - runtime will handle proper checking
        return false;
    }

    /**
     * Check if YScript class extends a Haxe class
     */
    private function checkYScriptExtendsHaxe(yscriptClassName:String, haxeClass:Class<Dynamic>):Bool {
        // Parse-time checking is limited - runtime will validate properly
        // For now, allow the assignment and let runtime handle validation
        return true;
    }
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// RUNTIME
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript runtime execution engine with Haxe integration
 */
@:privateAccess
class YScriptRuntime {
    public var scope:YScope;
    private var returnValue:Dynamic = null;
    private var shouldReturn:Bool = false;
    private var shouldBreak:Bool = false;
    private var shouldContinue:Bool = false;

    #if (LUA_ALLOWED && !macro)
    private var luaState:State = null;
    #end

    public function new(?scope:YScope) {
        this.scope = scope ?? new YScope();

        #if (LUA_ALLOWED && !macro)
        luaState = LuaL.newstate();
        LuaL.openlibs(luaState);
        #end
    }

    public function initialize(statements:Array<YStatement>, scope:YScope):Void {
        this.scope = scope;
        for (stmt in statements) {
            executeStatement(stmt);
        }
    }

    public function execute(?scope:YScope):Dynamic {
        if (scope != null) this.scope = scope;
        return returnValue;
    }


    public function callFunction(name:String, args:Array<Dynamic>, scope:YScope):Dynamic {
        this.scope = scope;
        var func = scope.getFunction(name);
        if (func != null) {
            return callYFunction(func, args);
        }
        var context = scope.getExecutionContext();
        trace('YScript: Failed to call function $name at ${context.location.file}:${context.location.line}:${context.location.column} - function not found');
        throw new YScriptRuntimeError('Function not found: $name', context.location, context.scriptPath);
    }

    /**
     * Enhanced runtime type compatibility checking
     */
    private function isRuntimeTypeCompatible(expectedType:YType, actualType:YType, actualValue:Dynamic):Bool {
        // Exact type match
        if (Type.enumEq(expectedType, actualType)) return true;

        // Dynamic accepts anything
        if (expectedType == YType.Dynamic || actualType == YType.Dynamic) return true;

        // Null handling
        if (actualValue == null) {
            switch (expectedType) {
                case YType.YInt | YType.YFloat | YType.YBool: return false; // Primitives don't accept null
                default: return true; // Objects, arrays, etc. can be null
            }
        }

        // Numeric type promotion and conversion
        switch [expectedType, actualType] {
            case [YType.YFloat, YType.YInt]: return true; // Int can be promoted to Float
            case [YType.YString, _]: return true; // Most types can convert to String
            default:
        }

        // Array type checking
        switch [expectedType, actualType] {
            case [YType.YArray(expectedElement), YType.YArray(actualElement)]:
                return isRuntimeTypeCompatible(expectedElement, actualElement, null);
            default:
        }

        // Class inheritance checking
        switch [expectedType, actualType] {
            case [YType.HaxeClass(expectedClass), YType.HaxeClass(actualClass)]:
                return isHaxeClassInheritable(expectedClass, actualClass);
            case [YType.YClass(expectedName), YType.YClass(actualName)]:
                return isYScriptClassInheritable(expectedName, actualName, scope);
            default:
        }

        // Abstract type compatibility via @:from / @:to implicit conversions
        // Target is an abstract: check if actual type can be accepted via @:from
        switch (expectedType) {
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;

                    var actualTypeStr = yTypeToString(actualType);
                    if (actualTypeStr != null) {
                        if (yutautil.TypeHandler.canAssignToAbstract(actualTypeStr, interp.abstractPath)) return true;
                    }

                    // Runtime value-based checks for primitives
                    if (actualValue != null) {
                        if (interp.matchesUnderlyingType(actualValue) || interp.canConvertFrom(actualValue)) return true;
                    } else {
                        switch (actualType) {
                            case YInt:
                                if (interp.matchesUnderlyingType(0) || interp.canConvertFrom(0)) return true;
                            case YFloat:
                                if (interp.matchesUnderlyingType(0.0) || interp.canConvertFrom(0.0)) return true;
                            case YString:
                                if (interp.matchesUnderlyingType("") || interp.canConvertFrom("")) return true;
                            case YBool:
                                if (interp.matchesUnderlyingType(true) || interp.canConvertFrom(true)) return true;
                            case _:
                        }
                    }

                    // Cross-abstract checks
                    switch (actualType) {
                        case HaxeAbstract(otherAbstract):
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                if (interp.abstractPath == otherInterp.abstractPath) return true;
                                var otherToTypes = otherInterp.getToTypes();
                                for (toEntry in otherToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, interp.abstractPath)) return true;
                                }
                                if (otherInterp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(otherInterp.underlyingType, interp.abstractPath)) return true;
                                }
                            }
                        case HaxeClass(cls):
                            var className = Type.getClassName(cls);
                            if (className != null && yutautil.TypeHandler.canAssignToAbstract(className, interp.abstractPath)) return true;
                        case _:
                    }
                }
            default:
        }

        // Source is an abstract: check if it can be converted TO the target
        switch (actualType) {
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;

                    var expectedTypeStr = yTypeToString(expectedType);
                    if (expectedTypeStr != null) {
                        if (yutautil.TypeHandler.canAbstractOutputType(interp.abstractPath, expectedTypeStr)) return true;
                    }

                    switch (expectedType) {
                        case YInt:
                            if (interp.canConvertTo("Int")) return true;
                        case YFloat:
                            if (interp.canConvertTo("Float")) return true;
                        case YString:
                            if (interp.canConvertTo("String")) return true;
                        case YBool:
                            if (interp.canConvertTo("Bool")) return true;
                        case HaxeClass(cls):
                            var className = Type.getClassName(cls);
                            if (className != null && interp.canConvertTo(className)) return true;
                        case HaxeAbstract(otherAbstract):
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                var myToTypes = interp.getToTypes();
                                for (toEntry in myToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, otherInterp.abstractPath)) return true;
                                }
                                if (interp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(interp.underlyingType, otherInterp.abstractPath)) return true;
                                }
                            }
                        case _:
                    }
                }
            default:
        }

        return false;
    }

    /**
     * Enhanced array element type inference from runtime array
     */
    private function inferArrayElementTypeFromRuntime(array:Array<Dynamic>):YType {
        if (array.length == 0) return YType.Dynamic;

        // Sample up to 10 elements for performance
        var sampleSize = Std.int(Math.min(array.length, 10));
        var elementTypes:Array<YType> = [];

        for (i in 0...sampleSize) {
            elementTypes.push(inferTypeFromValue(array[i]));
        }

        // Find common type
        return findCommonRuntimeType(elementTypes);
    }

    /**
     * Find common type from runtime analysis
     */
    private function findCommonRuntimeType(types:Array<YType>):YType {
        if (types.length == 0) return YType.Dynamic;
        if (types.length == 1) return types[0];

        var firstType = types[0];
        var allSameType = true;

        for (type in types) {
            if (!Type.enumEq(type, firstType)) {
                allSameType = false;
                break;
            }
        }

        if (allSameType) return firstType;

        // Check for numeric compatibility
        var hasInt = false;
        var hasFloat = false;
        var allNumeric = true;

        for (type in types) {
            switch (type) {
                case YType.YInt: hasInt = true;
                case YType.YFloat: hasFloat = true;
                default: allNumeric = false;
            }
        }

        if (allNumeric && (hasInt || hasFloat)) {
            return hasFloat ? YType.YFloat : YType.YInt;
        }

        // Fallback to Dynamic for mixed types
        return YType.Dynamic;
    }

    /**
     * Check Haxe class inheritance for compatibility
     */
    private function isHaxeClassInheritable(expectedClass:Class<Dynamic>, actualClass:Class<Dynamic>):Bool {
        if (expectedClass == actualClass) return true;

        try {
            var currentClass = actualClass;
            while (currentClass != null) {
                if (currentClass == expectedClass) return true;
                currentClass = Type.getSuperClass(currentClass);
            }
            return false;
        } catch (e:Dynamic) {
            return true; // Conservative approach if reflection fails
        }
    }

    /**
     * Check YScript class inheritance for compatibility
     */
    private function isYScriptClassInheritable(expectedName:String, actualName:String, scope:YScope):Bool {
        if (expectedName == actualName) return true;

        var actualClass = scope.getClass(actualName);
        if (actualClass != null) {
            return actualClass.extendsClass(expectedName);
        }

        return false;
    }

    public function destroy():Void {
        #if (LUA_ALLOWED && !macro)
        if (luaState != null) {
            Lua.close(luaState);
            luaState = null;
        }
        #end
    }

    public function executeStatements(statements:Array<YStatement>):Dynamic {
        shouldReturn = false;
        shouldBreak = false;
        shouldContinue = false;

        for (stmt in statements) {
            executeStatement(stmt);

            if (shouldReturn || shouldBreak || shouldContinue) {
                break;
            }
        }

        return returnValue;
    }

    public function executeStatement(stmt:YStatement):Void {
        // Set execution context with statement location for error reporting
        var location = switch (stmt) {
            case Import(_, _, loc): loc;
            case VarDecl(_, _, _, loc): loc;
            case FuncDecl(_, _, _, _, loc): loc;
            case ClassDecl(_, _, _, _, loc): loc;
            case If(_, _, _, loc): loc;
            case While(_, _, loc): loc;
            case For(_, _, _, _, loc): loc;
            case ForIn(_, _, _, _, loc): loc;
            case Return(_, loc): loc;
            case Break(loc): loc;
            case Continue(loc): loc;
            case Block(_, loc): loc;
            case Expression(_, loc): loc;
            case HaxeBlock(_, loc): loc;
            case LuaBlock(_, loc): loc;
        };
        scope.setExecutionContext(scope.currentScriptPath ?? "<unknown>", scope.currentFunction, location);

		// Debug tracing for YScript execution
		#if !macro
		if (backend.ClientPrefs.data.yscriptDebugMode) {
			var shortStmt = Std.string(stmt).substring(0, 80);
			trace('[YScript Debug] Executing statement: $shortStmt at ${location.file}:${location.line}');
		}
		#end

        try {
            switch (stmt) {
                case Import(path, alias, location):
                    scope.addImport(path, alias);
                    // Try to resolve and register Haxe class
                    var className = alias ?? path.split(".").pop();
                    try {
                        var haxeClass = Type.resolveClass(path);
                        if (haxeClass != null) {
                            scope.setType(className, YType.HaxeClass(haxeClass));
                        } else {
                            // Class not found - try resolving as an abstract type via BuildDataLoader
                            var abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(path);
                            if (abstractInterp != null) {
                                // Store the AbstractInterpreter as the abstract type reference
                                scope.setType(className, YType.HaxeAbstract(abstractInterp));
                                #if !macro
                                if (backend.ClientPrefs.data.yscriptDebugMode) {
                                    trace('[YScript Debug] Import resolved as abstract type: $path -> $className');
                                    if (abstractInterp.isGeneric) {
                                        trace('[YScript Debug]   (generic: <${abstractInterp.typeParams.join(", ")}>)');
                                    }
                                }
                                #end
                            } else {
                                // Try resolving as an enum
                                var haxeEnum = Type.resolveEnum(path);
                                if (haxeEnum != null) {
                                    scope.setType(className, YType.HaxeEnum(haxeEnum));
                                }
                            }
                        }

                    } catch (e:Dynamic) {
                        // Import failed - could be YScript module or non-existent
                        trace('Warning: Could not resolve import: $path');
                    }

                case VarDecl(name, type, init, location):
                    var value:Dynamic = null;
                    if (init != null) {
                        value = evaluateExpression(init);
                        // Type checking for initialization
                        validateAssignment(type, value);
                    } else {
                        value = getDefaultValue(type);
                    }

                    scope.setVariable(name, new YVar(name, type, value));

                case FuncDecl(name, params, returnType, body, location):
                    var func = new YFunction(name, params, returnType, body);
                    scope.setFunction(name, func);

                case ClassDecl(name, extend, implement, body, location):
                    var classDef = new YClassDefinition(name, extend, implement);

                    // Resolve superclass
                    if (extend != null) {
                        // First try to resolve as YScript class
                        var superClassDef = scope.getClass(extend);
                        if (superClassDef != null) {
                            classDef.superClassDef = superClassDef;
                        } else {
                            // Try to resolve from imports as Haxe class
                            var fullPath = scope.resolveImport(extend) ?? extend;
                            var haxeClass = Type.resolveClass(fullPath);
                            if (haxeClass != null) {
                                classDef.isHaxeClass = true;
                                classDef.haxeClassName = fullPath;
                                classDef.haxeClassType = haxeClass;
                            } else {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Cannot resolve superclass: $extend', context.location, context.scriptPath);
                            }
                        }
                    }

                    // Process class body
                    var classScope = scope.createChild();
                    var oldScope = this.scope;
                    this.scope = classScope;

                    for (statement in body) {
                        switch (statement) {
                            case VarDecl(fieldName, fieldType, fieldInit, location):
                                var field = new YVar(fieldName, fieldType);
                                if (fieldInit != null) {
                                    field.value = evaluateExpression(fieldInit);
                                }
                                classDef.addField(field);

                            case FuncDecl(methodName, params, returnType, methodBody, location):
                                var method = new YFunction(methodName, params, returnType, methodBody);
                                if (methodName == name || methodName == "new") {
                                    classDef.addConstructor(method);
                                } else {
                                    classDef.addMethod(method);
                                }

                            default:
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Invalid statement in class body', context.location, context.scriptPath);
                        }
                    }

                    this.scope = oldScope;
                    scope.setClass(name, classDef);

                case If(condition, thenStmt, elseStmt, location):
                    var condValue = evaluateExpression(condition);
                    if (isTruthy(condValue)) {
                        executeStatement(thenStmt);
                    } else if (elseStmt != null) {
                        executeStatement(elseStmt);
                    }

                case While(condition, body, location):
                    while (isTruthy(evaluateExpression(condition))) {
                        executeStatement(body);

                        if (shouldReturn || shouldBreak) break;
                        if (shouldContinue) {
                            shouldContinue = false;
                            continue;
                        }
                    }

                case For(init, condition, increment, body, location):
                    // Create a child scope for the loop variable (prevents scope leakage)
                    var forScope = scope.createChild();
                    var oldForScope = this.scope;
                    this.scope = forScope;

                    if (init != null) executeStatement(init);

                    while (condition == null || isTruthy(evaluateExpression(condition))) {
                        executeStatement(body);

                        if (shouldReturn || shouldBreak) break;
                        if (shouldContinue) {
                            shouldContinue = false;
                        }

                        if (increment != null) {
                            evaluateExpression(increment);
                        }
                    }

                    if (shouldBreak) shouldBreak = false;

                    // Restore parent scope
                    this.scope = oldForScope;

                case ForIn(varName, varType, iterableExpr, body, location):
                    // Create a child scope for the loop variable
                    var forInScope = scope.createChild();
                    var oldScope = this.scope;
                    this.scope = forInScope;

                    // Declare the loop variable
                    var loopVar = new YVar(varName, varType);
                    forInScope.setVariable(varName, loopVar);

                    // Detect range expression (start...end) before evaluating,
                    // since "..." is not a standard binary operator.
                    switch (iterableExpr) {
                        case BinaryOp(startExpr, "...", endExpr, _):
                            // Range iteration: from start (inclusive) to end (exclusive)
                            var startVal:Int = cast evaluateExpression(startExpr);
                            var endVal:Int = cast evaluateExpression(endExpr);
                            var i:Int = startVal;
                            while (i < endVal) {
                                loopVar.value = i;
                                forInScope.setVariable(varName, loopVar);
                                executeStatement(body);

                                if (shouldReturn || shouldBreak) break;
                                if (shouldContinue) {
                                    shouldContinue = false;
                                }
                                i++;
                            }

                        default:
                            // Evaluate the iterable expression for arrays/iterators
                            var iterableValue:Dynamic = evaluateExpression(iterableExpr);

                            if (iterableValue == null) {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Cannot iterate over null', context.location, context.scriptPath);
                            }

                            if (Std.isOfType(iterableValue, Array)) {
                                // Array iteration: iterate over elements
                                var arr:Array<Dynamic> = cast iterableValue;
                                for (element in arr) {
                                    loopVar.value = element;
                                    forInScope.setVariable(varName, loopVar);
                                    executeStatement(body);

                                    if (shouldReturn || shouldBreak) break;
                                    if (shouldContinue) {
                                        shouldContinue = false;
                                    }
                                }
                            } else {
                                // Try iterator protocol: check for iterator() method first, then hasNext/next
                                var iterator:Dynamic = null;

                                // Check if it has an iterator() method (Iterable)
                                try {
                                    var iteratorMethod:Dynamic = Reflect.field(iterableValue, "iterator");
                                    if (iteratorMethod != null && Reflect.isFunction(iteratorMethod)) {
                                        iterator = Reflect.callMethod(iterableValue, iteratorMethod, []);
                                    }
                                } catch (e:Dynamic) {}

                                // If no iterator() method, check if it IS an iterator (has hasNext/next directly)
                                if (iterator == null) {
                                    var hasNextMethod:Dynamic = Reflect.field(iterableValue, "hasNext");
                                    var nextMethod:Dynamic = Reflect.field(iterableValue, "next");
                                    if (hasNextMethod != null && Reflect.isFunction(hasNextMethod) && nextMethod != null && Reflect.isFunction(nextMethod)) {
                                        iterator = iterableValue;
                                    }
                                }

                                if (iterator != null) {
                                    // Use hasNext/next protocol
                                    var hasNextFn:Dynamic = Reflect.field(iterator, "hasNext");
                                    var nextFn:Dynamic = Reflect.field(iterator, "next");

                                    while (Reflect.callMethod(iterator, hasNextFn, [])) {
                                        var element:Dynamic = Reflect.callMethod(iterator, nextFn, []);
                                        loopVar.value = element;
                                        forInScope.setVariable(varName, loopVar);
                                        executeStatement(body);

                                        if (shouldReturn || shouldBreak) break;
                                        if (shouldContinue) {
                                            shouldContinue = false;
                                        }
                                    }
                                } else {
                                    var context = scope.getExecutionContext();
                                    throw new YScriptRuntimeError('Value is not iterable: ' + Std.string(iterableValue), context.location, context.scriptPath);
                                }
                            }
                    }

                    // Reset break flag (it was handled by this loop)
                    if (shouldBreak) shouldBreak = false;

                    // Restore parent scope
                    this.scope = oldScope;

                case Return(value, location):
                    returnValue = value != null ? evaluateExpression(value) : null;
                    shouldReturn = true;

                case Break(location):
                    shouldBreak = true;

                case Continue(location):
                    shouldContinue = true;

                case Block(statements, location):
                    var blockScope = scope.createChild();
                    var oldScope = this.scope;
                    this.scope = blockScope;

                    for (statement in statements) {
                        executeStatement(statement);
                        if (shouldReturn || shouldBreak || shouldContinue) break;
                    }

                    this.scope = oldScope;

                case Expression(expr, location):
                    evaluateExpression(expr);

                case HaxeBlock(code, location):
                    executeHaxeCode(code);

                case LuaBlock(code, location):
                    #if (LUA_ALLOWED && !macro)
                    executeLuaCode(code);
                    #else
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError("Lua support not enabled", context.location, context.scriptPath);
                    #end
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Runtime error: $e', context.location, context.scriptPath);
        }
    }

    public function evaluateExpression(expr:YExpression):Dynamic {
        // Set execution context with expression location for error reporting
        var location = switch (expr) {
            case IntLiteral(_, loc): loc;
            case FloatLiteral(_, loc): loc;
            case StringLiteral(_, loc): loc;
            case BoolLiteral(_, loc): loc;
            case NullLiteral(loc): loc;
            case ArrayLiteral(_, loc): loc;
            case ObjectLiteral(_, loc): loc;
            case Identifier(_, loc): loc;
            case SuperCall(_, loc): loc;
            case SuperMemberAccess(_, loc): loc;
            case SuperMethodCall(_, _, loc): loc;
            case BinaryOp(_, _, _, loc): loc;
            case UnaryOp(_, _, loc): loc;
            case Assignment(_, _, loc): loc;
            case CompoundAssignment(_, _, _, loc): loc;
            case FunctionCall(_, _, loc): loc;
            case MemberAccess(_, _, loc): loc;
            case ArrayAccess(_, _, loc): loc;
            case New(_, _, loc): loc;
            case Cast(_, _, loc): loc;
            case Is(_, _, loc): loc;
        };
        scope.setExecutionContext(scope.currentScriptPath ?? "<unknown>", scope.currentFunction, location);

		// Debug tracing for YScript expression evaluation
		#if !macro
		if (backend.ClientPrefs.data.yscriptDebugMode) {
			var shortExpr = Std.string(expr).substring(0, 60);
			trace('[YScript Debug] Evaluating expression: $shortExpr at ${location.file}:${location.line}');
		}
		#end

        return switch (expr) {
            case IntLiteral(value, location): value;
            case FloatLiteral(value, location): value;
            case StringLiteral(value, location): value;
            case BoolLiteral(value, location): value;
            case NullLiteral(location): null;

            case ArrayLiteral(elements, location):
                var array = [];
                for (element in elements) {
                    array.push(evaluateExpression(element));
                }
                array;

            case ObjectLiteral(fields, location):
                var obj = {};
                for (field in fields) {
                    Reflect.setField(obj, field.name, evaluateExpression(field.value));
                }
                obj;

            case Identifier(name, location):
                if (scope.hasVariable(name)) {
                    var variable = scope.getVariable(name);
                    var value = variable.value;

                    // If the variable is abstract-typed but the value isn't wrapped as AbstractValue,
                    // we need to ensure it's properly wrapped for operations
                    switch (variable.type) {
                        case HaxeAbstract(abstractType):
                            if (!Std.isOfType(value, yutautil.typeregistry.AbstractValue) && Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                                var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                                return interp.wrapValue(value);
                            }
                        default:
                    }
                    return value;
                } else {
                    // Try to resolve as Haxe type or global
                    resolveHaxeIdentifier(name);
                }

            case SuperCall(args, location):
                executeSuperConstructorCall(args);

            case SuperMemberAccess(member, location):
                executeSuperMemberAccess(member);

            case SuperMethodCall(method, args, location):
                executeSuperMethodCall(method, args);

            case BinaryOp(left, op, right, location):
                var leftValue = evaluateExpression(left);
                var rightValue = evaluateExpression(right);
                evaluateBinaryOperation(leftValue, op, rightValue);

            case UnaryOp(op, operand, location):
                var value = evaluateExpression(operand);
                evaluateUnaryOperation(op, value);

            case Assignment(target, value, location):
                var val = evaluateExpression(value);
                assignToTarget(target, val);
                val;

            case CompoundAssignment(target, op, value, location):
                // Evaluate the current value of the target
                var currentValue = evaluateExpression(target);
                // Evaluate the right-hand side value
                var rightValue = evaluateExpression(value);
                // Get the binary operator (remove '=' from compound operator)
                var binaryOp = op.substring(0, op.length - 1);
                // Perform the binary operation
                var newValue = evaluateBinaryOperation(currentValue, binaryOp, rightValue);
                // Assign the result back to the target
                assignToTarget(target, newValue);
                newValue;

            case FunctionCall(callee, args, location):
                var argValues = [for (arg in args) evaluateExpression(arg)];
                callFunctionExpression(callee, argValues);

            case MemberAccess(object, member, location):
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] Evaluating MemberAccess: object=' + Std.string(object).substring(0, 30) + ', member=' + member);
                }
                #end

                // Check if this is part of a dotted path that might resolve to a type
                try {
                    return resolveProgressiveMemberAccess(MemberAccess(object, member, location));
                } catch (e:YScriptRuntimeError) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] Progressive resolution failed, trying normal member access: ' + e.message);
                    }
                    #end

                    // Progressive resolution failed, try normal member access WITHOUT recursion
                    var objValue = evaluateExpression(object);
                    return accessMember(objValue, member);
                }

            case ArrayAccess(array, index, location):
                var arrayValue = evaluateExpression(array);
                var indexValue = evaluateExpression(index);
                accessArrayElement(arrayValue, indexValue);

            case New(type, args, location):
                var argValues = [for (arg in args) evaluateExpression(arg)];
                createInstance(type, argValues);

            case Cast(expr, type, location):
                var value = evaluateExpression(expr);
                // For now, just return the value as casting is complex
                value;

            case Is(expr, type, location):
                var value = evaluateExpression(expr);
                // For now, return false as type checking is complex
                false;
        }
    }

    private function getDefaultValue(type:YType):Dynamic {
        return switch (type) {
            case YInt: 0;
            case YFloat: 0.0;
            case YString: "";
            case YBool: false;
            case YArray(_): [];
            case Dynamic: null;
            case Void: null;
            case YClass(_): null;
            case YEnum(_): null;
            case YStruct(_): null;
            case HaxeClass(_): null;
            case HaxeAbstract(_): null;
            case HaxeType(_): null;
            case HaxeEnum(_): null;
            case YFunction(_, _): null;
            case Unknown: null;
        }
    }

    /**
     * Get a default value for a given underlying type name string (e.g. "Float", "Int", "String").
     * Used when constructing abstract types with no arguments.
     */
    private function getDefaultValueForUnderlyingType(typeName:String):Dynamic {
        if (typeName == null) return null;
        var normalized = typeName.toLowerCase();
        var lastDot = normalized.lastIndexOf(".");
        if (lastDot >= 0) normalized = normalized.substring(lastDot + 1);

        return switch (normalized) {
            case "int" | "integer": 0;
            case "float" | "number" | "double": 0.0;
            case "string": "";
            case "bool" | "boolean": false;
            case "array": [];
            case _: null;
        };
    }

    private function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.is(value, Bool)) return value;
        if (Std.is(value, Float) || Std.is(value, Int)) return value != 0;
        if (Std.is(value, String)) return StringTools.trim(cast(value, String)).length > 0;
        return true;
    }

    private function evaluateBinaryOperation(left:Dynamic, op:String, right:Dynamic):Dynamic {
        // Special case: String concatenation with +
        if (op == "+") {
            var leftIsString = Std.isOfType(left, String);
            var rightIsString = Std.isOfType(right, String);

            if (leftIsString || rightIsString) {
                return convertValueToString(left) + convertValueToString(right);
            }
        }

        // If either side is an AbstractValue, try operator dispatch through its interpreter
        if (Std.isOfType(left, yutautil.typeregistry.AbstractValue)) {
            var absVal:yutautil.typeregistry.AbstractValue = cast left;
            if (absVal.interpreter.hasOperator(op)) {
                var rawRight:Any = Std.isOfType(right, yutautil.typeregistry.AbstractValue)
                    ? (cast(right, yutautil.typeregistry.AbstractValue)).rawValue
                    : cast right.forceCast();
                var result:Any = absVal.op(op, rawRight);
                // Unwrap the result if it's an AbstractValue to return the direct underlying value
                var finalResult:Any = Std.isOfType(result, yutautil.typeregistry.AbstractValue)
                    ? (cast(result, yutautil.typeregistry.AbstractValue)).rawValue
                    : result;
                return finalResult;
            }
        } else if (Std.isOfType(right, yutautil.typeregistry.AbstractValue)) {
            var absVal:yutautil.typeregistry.AbstractValue = cast right;
            if (absVal.interpreter.hasOperator(op)) {
                return absVal.interpreter.applyOperator(op, left, absVal.rawValue);
            }
        }

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] Falling back to default binary operation: $left $op $right');
        }
        #end

        return switch (op) {
            case "+": left + right;
            case "-": left - right;
            case "*": left * right;
            case "/": left / right;
            case "%": left % right;
            case "==": left == right;
            case "!=": left != right;
            case "<": left < right;
            case "<=": left <= right;
            case ">": left > right;
            case ">=": left >= right;
            case "&&": isTruthy(left) && isTruthy(right);
            case "||": isTruthy(left) || isTruthy(right);
            default:
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Unknown binary operator: $op', context.location, context.scriptPath);
        }
    }

    private function evaluateUnaryOperation(op:String, operand:Dynamic):Dynamic {
        return switch (op) {
            case "-": -operand;
            case "+": operand < 0 ? -operand : operand;
            case "!": !isTruthy(operand);
            default:
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Unknown unary operator: $op', context.location, context.scriptPath);
        }
    }

    private function assignToTarget(target:YExpression, value:Dynamic):Void {
        switch (target) {
            case Identifier(name, location):
                if (scope.hasVariable(name)) {
                    var variable = scope.getVariable(name);
                    // Type checking for assignment
                    validateAssignment(variable.type, value);
                    // Auto-wrap values when assigning to abstract-typed variables
                    var assignValue = value;
                    switch (variable.type) {
                        case HaxeAbstract(abstractType):
                            // If the value isn't already an AbstractValue, wrap it via @:from
                            if (!Std.isOfType(value, yutautil.typeregistry.AbstractValue)) {
                                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                                    var converted = interp.applyFromConversion(value);
                                    if (converted != null) {
                                        assignValue = converted;
                                    } else {
                                        // Fallback: force-wrap if underlying type matches
                                        assignValue = interp.forceWrap(value);
                                    }
                                }
                            }
                        default:
                    }
                    variable.value = assignValue;
                } else {
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Undefined variable: $name', context.location, context.scriptPath);
                }

            case MemberAccess(object, member, location):
                var objValue = evaluateExpression(object);
                setMember(objValue, member, value);

            case ArrayAccess(array, index, location):
                var arrayValue = evaluateExpression(array);
                var indexValue = evaluateExpression(index);
                setArrayElement(arrayValue, indexValue, value);

            default:
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Invalid assignment target', context.location, context.scriptPath);
        }
    }

    private function callFunctionExpression(callee:YExpression, args:Array<Dynamic>):Dynamic {
        switch (callee) {
            case Identifier(name, location):
                // YScript function
                if (scope.hasFunction(name)) {
                    var func = scope.getFunction(name);
                    return callYFunction(func, args);
                }

                // Haxe function
                return callHaxeFunction(name, args);

            case MemberAccess(object, method, location):
                var objValue = evaluateExpression(object);
                return callMethod(objValue, method, args);

            default:
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Cannot call this expression as a function', context.location, context.scriptPath);
        }
    }

    private function callYFunction(func:YFunction, args:Array<Dynamic>):Dynamic {
        // Create new scope for function execution
        var functionScope = scope.createChild();

        // Set execution context for error tracking with function name
        functionScope.setExecutionContext(
            scope.currentScriptPath ?? "<unknown>",
            func.name,
            scope.currentLocation
        );

        var context = functionScope.getExecutionContext();
        var funcName = func.name;
        #if !macro
        if (ClientPrefs.data.yscriptDebugMode) {
            trace('YScript: Calling function "$funcName" with ${args.length} arguments at ${context.location.file}:${context.location.line}:${context.location.column}');
        }
        #end

        // Comprehensive type checking - only for non-native functions or when explicitly enabled
        if (!func.isNative) {
            // Check parameter count
            var expectedParams = func.parameters.length;
            var actualArgs = args.length;

            if (actualArgs != expectedParams) {
                var message = 'Function "$funcName" expects $expectedParams arguments but got $actualArgs';
                trace('YScript: ' + message);
                // forwardErrorToPlayState('YScript Error: ' + message, true);
                throw new YScriptTypeError(message, context.location, context.scriptPath);
            }

            // Check argument types against parameter types
            for (i in 0...func.parameters.length) {
                var param = func.parameters[i];
                var arg = args[i];
                var paramType = param.type;
                var argType = inferTypeFromValue(arg);

                if (!isTypeCompatible(paramType, argType)) {
                    var paramName = param.name;
                    var message = 'Function "$funcName" parameter "$paramName" expects ${YTypeHelper.toString(paramType)} but got ${YTypeHelper.toString(argType)}';
                    trace('YScript: ' + message);
                    // forwardErrorToPlayState('YScript Error: ' + message, true);
                    throw new YScriptTypeError(message, context.location, context.scriptPath);
                }
            }

            // For native functions, perform additional validation
            if (func.isNative && func.nativeFunction != null) {
                try {
                    // Test if the function can be called with these arguments
                    if (Reflect.isFunction(func.nativeFunction)) {
                        // For now, we rely on Haxe's runtime checking
                        // Could be enhanced with reflection-based parameter analysis
                    }
                } catch (e:Dynamic) {
                    trace('YScript: Native function "${func.name}" validation failed: $e');
                    throw new YScriptTypeError('Native function "${func.name}" validation failed: $e', context.location, context.scriptPath);
                }
            }
        }

        for (i in 0...func.parameters.length) {
            var param = func.parameters[i];
            param.value = args[i];
            functionScope.setVariable(param.name, param);
        }

        // Execute function body
        var oldScope = this.scope;
        this.scope = functionScope;

        var result:Dynamic = null;
        var oldReturn = shouldReturn;
        shouldReturn = false;

        try {
            switch (func.body) {
                case YScript(statements):
                    for (stmt in statements) {
                        executeStatement(stmt);
                        if (shouldReturn) break;
                    }
                    result = returnValue;

                case HaxeCode(code):
                    result = executeHaxeCode(code);

                case LuaCode(code):
                    #if (LUA_ALLOWED && !macro)
                    result = executeLuaCode(code);
                    #else
                    var context = functionScope.getExecutionContext();
                    throw new YScriptRuntimeError("Lua support not enabled", context.location, context.scriptPath);
                    #end

                case Native(nativeFunc):
                    result = Reflect.callMethod(null, nativeFunc, args);
            }
        } catch (e:YScriptError) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            trace('YScript: Runtime error in function ${func.name}: $e (YScriptError)');
            throw e;
        } catch (e:Dynamic) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            var context = functionScope.getExecutionContext();
            trace('YScript: Runtime error in function ${func.name}: $e (Native Error)');
            throw new YScriptRuntimeError('Runtime error in function ${func.name}: $e', context.location, context.scriptPath);
        }

        this.scope = oldScope;
        shouldReturn = oldReturn;

        // Debug tracing for function return
        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] Function "$funcName" returned: ${result != null ? Std.string(result).substring(0, 50) : "null"}');
        }
        #end

        return result;
    }

    private function resolveHaxeIdentifier(name:String):Dynamic {
        try {
            // First check if it's a registered type in scope
            var registeredType = scope.getType(name);
            if (registeredType != null) {
                switch (registeredType) {
                    case HaxeClass(classType):
                        return classType; // Return the actual class for static access
                    case HaxeEnum(enumType):
                        return enumType; // Return the actual enum for static access
                    case HaxeAbstract(abstractType):
                        // Return the AbstractInterpreter so callers can dispatch methods/operators
                        return abstractType;
                    default:
                        // Fall through to other resolution methods
                }
            }

            // Try to resolve as a Haxe type or global
            var type = Type.resolveClass(name);
            if (type != null) return type;

            var enumType = Type.resolveEnum(name);
            if (enumType != null) return enumType;

            // Try resolving as an abstract type via BuildDataLoader
            var abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(name);
            if (abstractInterp != null) {
                // Register it in scope for future lookups
                scope.setType(name, YType.HaxeAbstract(abstractInterp));
                return abstractInterp;
            }

            // Also try resolving via import aliases
            var resolvedImport = scope.resolveImport(name);
            if (resolvedImport != null) {
                var importedClass = Type.resolveClass(resolvedImport);
                if (importedClass != null) return importedClass;

                var importedEnum = Type.resolveEnum(resolvedImport);
                if (importedEnum != null) return importedEnum;

                // Try as abstract via the resolved import path
                var importedAbstract = yutautil.typeregistry.AbstractInterpreter.forAbstract(resolvedImport);
                if (importedAbstract != null) {
                    scope.setType(name, YType.HaxeAbstract(importedAbstract));
                    return importedAbstract;
                }
            }

            // Check for static fields
            return Reflect.field(Type.resolveClass("Std"), name);
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Unknown identifier: $name', context.location, context.scriptPath);
        }
    }

    private function callHaxeFunction(name:String, args:Array<Dynamic>):Dynamic {
        try {
            // Special built-in functions
            switch (name) {
                case "trace":
                    trace(args.join(" "));
                    return null;
                case "print":
                    trace(args.join(" "));
                    return null;
            }

            // Try Std functions first
            var stdMethod = Reflect.field(Std, name);
            if (stdMethod != null && Reflect.isFunction(stdMethod)) {
                return Reflect.callMethod(Std, stdMethod, args);
            }

            // Try Math functions
            var mathMethod = Reflect.field(Math, name);
            if (mathMethod != null && Reflect.isFunction(mathMethod)) {
                return Reflect.callMethod(Math, mathMethod, args);
            }

            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Unknown function: $name', context.location, context.scriptPath);
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error calling function $name: $e', context.location, context.scriptPath);
        }
    }

    private function callMethod(object:Dynamic, method:String, args:Array<Dynamic>):Dynamic {
        try {
            // If the object is an AbstractValue, dispatch through its interpreter
            if (Std.isOfType(object, yutautil.typeregistry.AbstractValue)) {
                var absVal:yutautil.typeregistry.AbstractValue = cast object;
                return absVal.call(method, args);
            }

            // If the object is an AbstractInterpreter, call a static method on the abstract
            if (Std.isOfType(object, yutautil.typeregistry.AbstractInterpreter)) {
                var interp:yutautil.typeregistry.AbstractInterpreter = cast object;
                return interp.callStaticMethod(method, args);
            }

            var methodFunction = Reflect.field(object, method);
            if (methodFunction != null && Reflect.isFunction(methodFunction)) {
                return Reflect.callMethod(object, methodFunction, args);
            } else {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Method $method not found', context.location, context.scriptPath);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error calling method $method: $e', context.location, context.scriptPath);
        }
    }

    private function accessMember(object:Dynamic, member:String):Dynamic {
        try {
            // If the object is an AbstractValue, dispatch field access through its interpreter
            if (Std.isOfType(object, yutautil.typeregistry.AbstractValue)) {
                var absVal:yutautil.typeregistry.AbstractValue = cast object;
                return absVal.field(member);
            }

            // If the object is an AbstractInterpreter, access static fields on the impl class
            if (Std.isOfType(object, yutautil.typeregistry.AbstractInterpreter)) {
                var interp:yutautil.typeregistry.AbstractInterpreter = cast object;
                if (interp.implClass != null) {
                    var field = Reflect.field(interp.implClass, member);
                    if (field != null) return field;
                }
                // Check for special abstract metadata fields
                if (member == "underlyingType") return interp.underlyingType;
                if (member == "abstractPath") return interp.abstractPath;
                if (member == "isGeneric") return interp.isGeneric;
                if (member == "typeParams") return interp.typeParams;
                return null;
            }

            return Reflect.field(object, member);
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error accessing member $member: $e', context.location, context.scriptPath);
        }
    }

    /**
     * Progressive member access resolution for dotted paths like this.is.a.Long.path.thing
     * This handles cases where we need to resolve longer type paths before accessing members
     */
    private function resolveProgressiveMemberAccess(expr:YExpression):Dynamic {
        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] resolveProgressiveMemberAccess called with: ' + Std.string(expr).substring(0, 100));
        }
        #end

        // Collect the full dotted path
        var pathParts:Array<String> = [];
        var currentExpr = expr;

        // Walk backwards through the member access chain to collect all parts
        while (true) {
            switch (currentExpr) {
                case MemberAccess(object, member, _):
                    pathParts.unshift(member);
                    currentExpr = object;
                case Identifier(name, _):
                    pathParts.unshift(name);
                    break;
                default:
                    // Not a simple dotted path, evaluate normally without recursion
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Not a simple dotted path, falling back to normal evaluation');
                    }
                    #end
                    throw new YScriptRuntimeError('Progressive resolution failed: not a simple dotted path');
            }
        }

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] resolveProgressiveMemberAccess: Collected path parts: [' + pathParts.join(', ') + ']');
        }
        #end

        // Try progressively longer paths to find a resolvable type
        for (i in 1...pathParts.length + 1) {
            var typePath = pathParts.slice(0, i).join('.');

            #if !macro
            if (backend.ClientPrefs.data.yscriptDebugMode) {
                trace('[YScript Debug] resolveProgressiveMemberAccess: Trying path "$typePath"');
            }
            #end

            // First check if it's an imported type that was registered in scope
            var registeredType = scope.getType(typePath);
            if (registeredType != null) {
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Found registered type "$typePath"');
                }
                #end

                switch (registeredType) {
                    case HaxeClass(classType):
                        var result:Dynamic = classType;
                        for (j in i...pathParts.length) {
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing member "${pathParts[j]}" on registered type');
                            }
                            #end
                            result = Reflect.field(result, pathParts[j]);
                            if (result == null && !Reflect.hasField(result, pathParts[j])) {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Member "${pathParts[j]}" not found on registered type "$typePath"', context.location, context.scriptPath);
                            }
                        }
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Successfully resolved registered type "$typePath" to: ' + Std.string(result).substring(0, 50));
                        }
                        #end
                        return result;
                    default:
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Registered type "$typePath" is not a class type');
                        }
                        #end
                }
            }

            // Try to resolve as Haxe type first
            try {
                var haxeType = Type.resolveClass(typePath);
                if (haxeType != null) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Found Haxe type "$typePath", accessing remaining ${pathParts.length - i} members');
                    }
                    #end

                    // Found a valid Haxe type, now access remaining members step by step
                    var result:Dynamic = haxeType;
                    for (j in i...pathParts.length) {
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing member "${pathParts[j]}" on ${j == i ? "type " + typePath : "object"}');
                        }
                        #end
                        result = Reflect.field(result, pathParts[j]);
                        if (result == null && !Reflect.hasField(result, pathParts[j])) {
                            var context = scope.getExecutionContext();
                            throw new YScriptRuntimeError('Member "${pathParts[j]}" not found on ${j == i ? "type " + typePath : "object"}', context.location, context.scriptPath);
                        }
                    }
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Successfully resolved to: ' + Std.string(result).substring(0, 50));
                    }
                    #end
                    return result;
                }
            } catch (e:Dynamic) {
                // Type resolution failed, continue trying longer paths
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Type resolution failed for "$typePath": $e');
                }
                #end
            }

            // Try to resolve as abstract type via BuildDataLoader
            try {
                var abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(typePath);
                if (abstractInterp != null) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Found abstract type "$typePath", accessing remaining ${pathParts.length - i} members');
                    }
                    #end

                    // Register the abstract type in scope for future lookups
                    scope.setType(typePath, YType.HaxeAbstract(abstractInterp));

                    // If there are remaining members, dispatch via the AbstractInterpreter
                    if (i >= pathParts.length) {
                        return abstractInterp;
                    }

                    // Access remaining members - these would be static methods on the abstract
                    var result:Dynamic = abstractInterp;
                    for (j in i...pathParts.length) {
                        var memberName = pathParts[j];
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing abstract member "$memberName"');
                        }
                        #end

                        // Try to get the static method from the impl class
                        if (abstractInterp.implClass != null) {
                            var implField = Reflect.field(abstractInterp.implClass, memberName);
                            if (implField != null) {
                                result = implField;
                                continue;
                            }
                        }

                        // Fall back to field access on current result
                        if (result != null && result != abstractInterp) {
                            result = Reflect.field(result, memberName);
                        } else {
                            var context = scope.getExecutionContext();
                            throw new YScriptRuntimeError('Member "$memberName" not found on abstract type "$typePath"', context.location, context.scriptPath);
                        }
                    }
                    return result;
                }
            } catch (e:Dynamic) {
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Abstract resolution failed for "$typePath": $e');
                }
                #end
            }

            // Check if it's an imported type that was registered in scope
            var registeredType = scope.getType(typePath);
            if (registeredType != null) {
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Found registered type "$typePath"');
                }
                #end

                switch (registeredType) {
                    case HaxeClass(classType):
                        var result:Dynamic = classType;
                        for (j in i...pathParts.length) {
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing member "${pathParts[j]}" on registered type');
                            }
                            #end
                            result = Reflect.field(result, pathParts[j]);
                            if (result == null && !Reflect.hasField(result, pathParts[j])) {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Member "${pathParts[j]}" not found on registered type "$typePath"', context.location, context.scriptPath);
                            }
                        }
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Successfully resolved registered type to: ' + Std.string(result).substring(0, 50));
                        }
                        #end
                        return result;
                    default:
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Registered type "$typePath" is not a class type');
                        }
                        #end
                }
            }

            // Check for import aliases
            var resolvedImport = scope.resolveImport(typePath);
            if (resolvedImport != null) {
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Found import alias "$typePath" -> "$resolvedImport"');
                }
                #end

                try {
                    var importedType = Type.resolveClass(resolvedImport);
                    if (importedType != null) {
                        var result:Dynamic = importedType;
                        for (j in i...pathParts.length) {
                            #if !macro
                            if (backend.ClientPrefs.data.yscriptDebugMode) {
                                trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing member "${pathParts[j]}" on imported type');
                            }
                            #end
                            result = Reflect.field(result, pathParts[j]);
                            if (result == null) {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Member "${pathParts[j]}" not found on imported type "$resolvedImport"', context.location, context.scriptPath);
                            }
                        }
                        #if !macro
                        if (backend.ClientPrefs.data.yscriptDebugMode) {
                            trace('[YScript Debug] resolveProgressiveMemberAccess: Successfully resolved imported type to: ' + Std.string(result).substring(0, 50));
                        }
                        #end
                        return result;
                    }
                } catch (e:Dynamic) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Failed to resolve import "$resolvedImport": $e');
                    }
                    #end
                }
            }

            // Try to resolve as variable in scope
            if (scope.hasVariable(typePath)) {
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Found variable "$typePath", accessing remaining ${pathParts.length - i} members');
                }
                #end

                var variable = scope.getVariable(typePath);
                var result = variable.value;

                // Access remaining members step by step on the resolved variable
                for (j in i...pathParts.length) {
                    #if !macro
                    if (backend.ClientPrefs.data.yscriptDebugMode) {
                        trace('[YScript Debug] resolveProgressiveMemberAccess: Accessing member "${pathParts[j]}" on ${j == i ? "variable " + typePath : "object"}');
                    }
                    #end
                    result = Reflect.field(result, pathParts[j]);
                    if (result == null) {
                        var context = scope.getExecutionContext();
                        throw new YScriptRuntimeError('Member "${pathParts[j]}" not found on ${j == i ? "variable " + typePath : "object"}', context.location, context.scriptPath);
                    }
                }
                #if !macro
                if (backend.ClientPrefs.data.yscriptDebugMode) {
                    trace('[YScript Debug] resolveProgressiveMemberAccess: Successfully resolved variable to: ' + Std.string(result).substring(0, 50));
                }
                #end
                return result;
            }
        }

        #if !macro
        if (backend.ClientPrefs.data.yscriptDebugMode) {
            trace('[YScript Debug] resolveProgressiveMemberAccess: No progressive resolution worked, throwing error');
        }
        #end

        // If no progressive resolution worked, throw error to indicate failure
        var context = scope.getExecutionContext();
        throw new YScriptRuntimeError('Could not resolve progressive member access: ' + pathParts.join('.'), context.location, context.scriptPath);
    }

    private function setMember(object:Dynamic, member:String, value:Dynamic):Void {
        try {
            Reflect.setField(object, member, value);
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error setting member $member: $e', context.location, context.scriptPath);
        }
    }

    private function accessArrayElement(array:Dynamic, index:Dynamic):Dynamic {
        try {
            if (Std.is(array, Array)) {
                var arr:Array<Dynamic> = cast array;
                var idx:Int = cast index;
                if (idx >= 0 && idx < arr.length) {
                    return arr[idx];
                }
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Array index out of bounds: $idx', context.location, context.scriptPath);
            } else {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Cannot index non-array type', context.location, context.scriptPath);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error accessing array element: $e', context.location, context.scriptPath);
        }
    }

    private function setArrayElement(array:Dynamic, index:Dynamic, value:Dynamic):Void {
        try {
            if (Std.is(array, Array)) {
                var arr:Array<Dynamic> = cast array;
                var idx:Int = cast index;
                if (idx >= 0 && idx < arr.length) {
                    arr[idx] = value;
                } else {
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Array index out of bounds: $idx', context.location, context.scriptPath);
                }
            } else {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Cannot index non-array type', context.location, context.scriptPath);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error setting array element: $e', context.location, context.scriptPath);
        }
    }

    private function createInstance(type:YType, args:Array<Dynamic>):Dynamic {
        try {
            switch (type) {
                case YClass(className):
                    // First check if it's an imported/registered Haxe type
                    var haxeType = scope.getType(className);
                    if (haxeType != null) {
                        switch (haxeType) {
                            case HaxeClass(classType):
                                return Type.createInstance(classType, args);
                            case HaxeAbstract(abstractType):
                                // Delegate to the HaxeAbstract case
                                return createInstance(YType.HaxeAbstract(abstractType), args);
                            default:
                                // Fall through to YScript class checking
                        }
                    }

                    // Then check for YScript class definition
                    var classDef = scope.getClass(className);
                    if (classDef != null) {
                        var instance = new YClassInstance(className, classDef);

                        // Call YScript constructor if available
                        if (classDef.constructors.length > 0) {
                            var constructor = findMatchingConstructor(classDef.constructors, args);
                            if (constructor != null) {
                                // Mark as in constructor for super call tracking
                                instance.isInConstructor = true;
                                callYFunctionOnInstance(constructor, args, instance);
                                instance.isInConstructor = false;

                                // Validate super call for Haxe-extending classes
                                if (classDef.isHaxeClass && !instance.superCalled) {
                                    var context = scope.getExecutionContext();
                                    throw new YScriptRuntimeError('Constructor must call super() when extending Haxe class ${classDef.haxeClassName}', context.location, context.scriptPath);
                                }
                            }
                        } else if (classDef.isHaxeClass && classDef.haxeClassType != null) {
                            // No YScript constructor, but extending Haxe class - create instance with args
                            instance.haxeInstance = Type.createInstance(classDef.haxeClassType, args);
                            instance.superCalled = true;
                        }

                        return instance;
                    } else {
                        // Try resolving as an abstract type before giving up
                        var abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(className);
                        if (abstractInterp == null) {
                            // Also try via import resolution
                            var resolvedImport = scope.resolveImport(className);
                            if (resolvedImport != null) {
                                abstractInterp = yutautil.typeregistry.AbstractInterpreter.forAbstract(resolvedImport);
                            }
                        }
                        if (abstractInterp != null) {
                            return createInstance(YType.HaxeAbstract(abstractInterp), args);
                        }
                        var context = scope.getExecutionContext();
                        throw new YScriptRuntimeError('Unknown class: $className (not found as Haxe import, abstract, or YScript class)', context.location, context.scriptPath);
                    }

                case HaxeClass(classType):
                    if (classType != null) {
                        return Type.createInstance(classType, args);
                    } else {
                        var context = scope.getExecutionContext();
                        throw new YScriptRuntimeError('Null Haxe class type', context.location, context.scriptPath);
                    }

                case HaxeAbstract(abstractType):
                    // Abstracts don't have constructors in the traditional sense.
                    // Use the @:from conversion from the first argument, or call _new on impl if available.
                    if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                        var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                        if (args.length == 1) {
                            // Try @:from conversion
                            var converted = interp.applyFromConversion(args[0]);
                            if (converted != null) return converted;
                            // Fallback: just wrap the value
                            return interp.forceWrap(args[0]);
                        } else if (args.length == 0) {
                            // No args - create with default value for underlying type
                            var defaultVal = getDefaultValueForUnderlyingType(interp.underlyingType);
                            return interp.forceWrap(defaultVal);
                        } else {
                            // Try calling _new on the impl class if it exists
                            try {
                                return interp.callStaticMethod("_new", args);
                            } catch (e:Dynamic) {
                                var context = scope.getExecutionContext();
                                throw new YScriptRuntimeError('Cannot construct abstract ${interp.abstractPath} with ${args.length} arguments', context.location, context.scriptPath);
                            }
                        }
                    } else {
                        var context = scope.getExecutionContext();
                        throw new YScriptRuntimeError('Cannot instantiate abstract type without interpreter', context.location, context.scriptPath);
                    }

                case YArray(elementType):
                    return [];

                case YEnum(_):
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Cannot instantiate enum type directly', context.location, context.scriptPath);

                case YStruct(_):
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Struct instantiation not implemented yet', context.location, context.scriptPath);

                case HaxeType(_):
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Cannot instantiate raw Haxe type', context.location, context.scriptPath);

                case HaxeEnum(_):
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Cannot instantiate Haxe enum directly', context.location, context.scriptPath);

                case Unknown:
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Cannot instantiate unknown type', context.location, context.scriptPath);

                default:
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Cannot instantiate type: $type', context.location, context.scriptPath);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error creating instance: $e', context.location, context.scriptPath);
        }
    }

    private function findMatchingConstructor(constructors:Array<YFunction>, args:Array<Dynamic>):Null<YFunction> {
        for (constructor in constructors) {
            if (constructor.parameters.length == args.length) {
                return constructor;
            }
        }
        return constructors.length > 0 ? constructors[0] : null;
    }

    private function findMatchingMethod(methods:Array<YFunction>, args:Array<Dynamic>):Null<YFunction> {
        for (method in methods) {
            if (method.parameters.length == args.length) {
                return method;
            }
        }
        return methods.length > 0 ? methods[0] : null;
    }

    private function callYFunctionOnInstance(func:YFunction, args:Array<Dynamic>, instance:YClassInstance):Dynamic {
        var functionScope = scope.createChild();

        // Add 'this' reference
        functionScope.setVariable("this", new YVar("this", YType.YClass(instance.className), instance));

        // Bind parameters - only validate argument count for non-native functions
        if (!func.isNative && args.length != func.parameters.length) {
            var context = functionScope.getExecutionContext();
            throw new YScriptRuntimeError('Method "${func.name}" expected ${func.parameters.length} arguments, got ${args.length}', context.location, context.scriptPath);
        }

        for (i in 0...func.parameters.length) {
            if (i < args.length) {
                var param = func.parameters[i];
                param.value = args[i];
                functionScope.setVariable(param.name, param);
            }
        }

        // Execute function body
        var oldScope = this.scope;
        this.scope = functionScope;

        var result:Dynamic = null;
        var oldReturn = shouldReturn;
        shouldReturn = false;

        try {
            switch (func.body) {
                case YScript(statements):
                    for (stmt in statements) {
                        executeStatement(stmt);
                        if (shouldReturn) break;
                    }
                    result = returnValue;

                case HaxeCode(code):
                    result = executeHaxeCodeWithHScript(code);

                case LuaCode(code):
                    #if (LUA_ALLOWED && !macro)
                    result = executeLuaCode(code);
                    #else
                    var context = functionScope.getExecutionContext();
                    throw new YScriptRuntimeError("Lua support not enabled", context.location, context.scriptPath);
                    #end

                case Native(nativeFunc):
                    result = Reflect.callMethod(instance, nativeFunc, args);
            }
        } catch (e:YScriptError) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            throw e;
        } catch (e:Dynamic) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            var context = functionScope.getExecutionContext();
            throw new YScriptRuntimeError('Runtime error in method ${func.name}: $e', context.location, context.scriptPath);
        }

        this.scope = oldScope;
        shouldReturn = oldReturn;
				return result;
    }

    private function executeHaxeCode(code:String):Dynamic {
        return executeHaxeCodeWithHScript(code);
    }

    #if (LUA_ALLOWED && !macro)
    private function executeLuaCode(code:String):Dynamic {
        try {
            if (luaState == null) {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError("Lua state not initialized", context.location, context.scriptPath);
            }

            // Execute Lua code
            var result = LuaL.dostring(luaState, code);

            if (result != 0) {
                var error = Lua.tostring(luaState, -1);
                Lua.pop(luaState, 1);
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Lua error: $error', context.location, context.scriptPath);
            }

            // Get result from Lua stack
            if (Lua.gettop(luaState) > 0) {
                var luaResult = Lua.tonumber(luaState, -1);
                Lua.pop(luaState, 1);
                return luaResult;
            }

            return null;
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('Error executing Lua code: $e', context.location, context.scriptPath);
        }
    }
    #end

    public function cleanup():Void {
        #if (LUA_ALLOWED && !macro)
        if (luaState != null) {
            Lua.close(luaState);
            luaState = null;
        }
        #end
    }

    /**
     * ✅ HSCRIPT INTEGRATION: Execute Haxe code using HScript (Iris)
     */
    private function executeHaxeCodeWithHScript(code:String):Dynamic {
        #if (HSCRIPT_ALLOWED && !macro)
        try {
            // Use Iris (enhanced HScript) like the rest of the project
            var iris = new Iris(code, new IrisConfig(scope.currentScriptPath, false, false));

            // Get flattened variables from entire scope hierarchy
            var flattenedVars = scope.getFlattenedVariables();

            // Sync YScript variables to Iris environment
            @:privateAccess
            for (varName in flattenedVars.keys()) {
                iris.interp.variables.set(varName, flattenedVars.get(varName));
            }

            // trace('Executing Iris HScript code: $code');

            // Parse and execute the code
            var result = iris.execute();

            // Create a StringMap for syncing back
            var updatedVars = new StringMap<Dynamic>();
            @:privateAccess
            for (varName in iris.interp.variables.keys()) {
                updatedVars.set(varName, iris.interp.variables.get(varName));
            }

            // Sync variables back to YScript scope hierarchy
            scope.applyFlattenedVariables(updatedVars);

            return result;
        } catch (e:Dynamic) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError('HScript execution error: $e', context.location, context.scriptPath);
        }
        #else
        var context = scope.getExecutionContext();
        throw new YScriptRuntimeError("HScript support not enabled", context.location, context.scriptPath);
        #end
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // SUPER CALL IMPLEMENTATION
    // ═══════════════════════════════════════════════════════════════════════════════════════

    private function executeSuperConstructorCall(args:Array<YExpression>):Dynamic {
        // Get current instance from 'this' variable
        var thisVar = scope.getVariable("this");
        if (thisVar == null || !Std.is(thisVar.value, YClassInstance)) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super() can only be called in class constructors", context.location, context.scriptPath);
        }

        var instance:YClassInstance = cast thisVar.value;
        if (!instance.isInConstructor) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super() can only be called during constructor execution", context.location, context.scriptPath);
        }

        // Evaluate arguments
        var argValues:Array<Dynamic> = [];
        for (arg in args) {
            argValues.push(evaluateExpression(arg));
        }

        // Handle Haxe class extension
        if (instance.classDef.isHaxeClass && instance.classDef.haxeClassType != null) {
            try {
                instance.haxeInstance = Type.createInstance(instance.classDef.haxeClassType, argValues);
                instance.superCalled = true;
                return instance.haxeInstance;
            } catch (e:Dynamic) {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Failed to call super constructor: $e', context.location, context.scriptPath);
            }
        }
        // Handle YScript class extension
        else if (instance.classDef.superClassDef != null) {
            var superClassDef = instance.classDef.superClassDef;

            // Find matching constructor in superclass
            if (superClassDef.constructors.length > 0) {
                var superConstructor = findMatchingConstructor(superClassDef.constructors, argValues);
                if (superConstructor != null) {
                    // Call superclass constructor
                    callYFunctionOnInstance(superConstructor, argValues, instance);
                    instance.superCalled = true;
                    return instance;
                }
            }

            // If no constructor found, just mark as called
            instance.superCalled = true;
            return instance;
        }
        else {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super() can only be used when extending a class", context.location, context.scriptPath);
        }
    }

    private function executeSuperMemberAccess(member:String):Dynamic {
        // Get current instance from 'this' variable
        var thisVar = scope.getVariable("this");
        if (thisVar == null || !Std.is(thisVar.value, YClassInstance)) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super.field can only be used in class methods", context.location, context.scriptPath);
        }

        var instance:YClassInstance = cast thisVar.value;

        // Handle Haxe class extension
        if (instance.classDef.isHaxeClass && instance.haxeInstance != null) {
            try {
                return Reflect.field(instance.haxeInstance, member);
            } catch (e:Dynamic) {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Failed to access super.$member: $e', context.location, context.scriptPath);
            }
        }
        // Handle YScript class extension
        else if (instance.classDef.superClassDef != null) {
            var superField = instance.classDef.superClassDef.getField(member);
            if (superField != null) {
                return superField.value;
            } else {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Super field $member not found', context.location, context.scriptPath);
            }
        }
        else {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super.field can only be used when extending a class", context.location, context.scriptPath);
        }
    }

    private function executeSuperMethodCall(method:String, args:Array<YExpression>):Dynamic {
        // Get current instance from 'this' variable
        var thisVar = scope.getVariable("this");
        if (thisVar == null || !Std.is(thisVar.value, YClassInstance)) {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super.method() can only be used in class methods", context.location, context.scriptPath);
        }

        var instance:YClassInstance = cast thisVar.value;

        // Evaluate arguments
        var argValues:Array<Dynamic> = [];
        for (arg in args) {
            argValues.push(evaluateExpression(arg));
        }

        // Handle Haxe class extension
        if (instance.classDef.isHaxeClass && instance.haxeInstance != null) {
            try {
                var superMethod = Reflect.field(instance.haxeInstance, method);
                if (superMethod != null && Reflect.isFunction(superMethod)) {
                    return Reflect.callMethod(instance.haxeInstance, superMethod, argValues);
                } else {
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('Super method $method not found or not callable', context.location, context.scriptPath);
                }
            } catch (e:Dynamic) {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Failed to call super.$method(): $e', context.location, context.scriptPath);
            }
        }
        // Handle YScript class extension
        else if (instance.classDef.superClassDef != null) {
            var superMethods = instance.classDef.superClassDef.getMethod(method);
            if (superMethods != null && superMethods.length > 0) {
                // Find matching method based on argument count
                var superMethod = findMatchingMethod(superMethods, argValues);
                if (superMethod != null) {
                    return callYFunctionOnInstance(superMethod, argValues, instance);
                } else {
                    var context = scope.getExecutionContext();
                    throw new YScriptRuntimeError('No matching super method $method found', context.location, context.scriptPath);
                }
            } else {
                var context = scope.getExecutionContext();
                throw new YScriptRuntimeError('Super method $method not found', context.location, context.scriptPath);
            }
        }
        else {
            var context = scope.getExecutionContext();
            throw new YScriptRuntimeError("super.method() can only be used when extending a class", context.location, context.scriptPath);
        }
    }

    // ═══════════════════════════════════════════════════════════════════════════════════════
    // TYPE CHECKING SYSTEM
    // ═══════════════════════════════════════════════════════════════════════════════════════

    private function validateAssignment(targetType:YType, value:Dynamic, ?location:YLocation):Void {
        var valueType = inferTypeFromValue(value);
        if (!isTypeCompatible(targetType, valueType)) {
            var context = scope.getExecutionContext();
            var useLocation = location ?? context.location;
            var scriptPath = context.scriptPath;
            var msg = 'Type mismatch: cannot assign ${YTypeHelper.toString(valueType)} to ${YTypeHelper.toString(targetType)}';
            trace('YScript: ' + msg + ' at ${useLocation.file}:${useLocation.line}:${useLocation.column}');
            // forwardErrorToPlayState('YScript Error: ' + msg, true);
            throw new YScriptTypeError(msg, useLocation, scriptPath);
        }
    }

    private function isTypeCompatible(targetType:YType, valueType:YType):Bool {
        // Exact match
        if (Type.enumEq(targetType, valueType)) return true;

        // Dynamic accepts anything
        if (targetType == YType.Dynamic || valueType == YType.Dynamic) return true;

        // Null can be assigned to any type (for now)
        if (valueType == YType.Dynamic && targetType != YType.YInt && targetType != YType.YFloat && targetType != YType.YBool) {
            return true; // Null assignment
        }

        // Numeric compatibility
        switch [targetType, valueType] {
            case [YType.YFloat, YType.YInt]: return true; // Int -> Float allowed
            case [YType.YInt, YType.YFloat]: return false; // Float -> Int not allowed without cast
            default:
        }

        // Array element compatibility
        switch [targetType, valueType] {
            case [YType.YArray(targetElement), YType.YArray(valueElement)]:
                return isTypeCompatible(targetElement, valueElement);
            default:
        }

        // Enhanced class inheritance compatibility
        switch [targetType, valueType] {
            case [YType.HaxeClass(targetClass), YType.HaxeClass(valueClass)]:
                return isHaxeClassInheritanceCompatible(targetClass, valueClass);
            case [YType.YClass(targetName), YType.YClass(valueName)]:
                return isYScriptClassInheritanceCompatible(targetName, valueName);
            case [YType.HaxeClass(targetClass), YType.YClass(valueName)]:
                // YScript class instance being assigned to Haxe class type
                var yscriptClassDef = scope.getClass(valueName);
                return yscriptClassDef != null && yscriptClassDef.extendsHaxeClass(targetClass);
            case [YType.YClass(targetName), YType.HaxeClass(valueClass)]:
                // Check if the target YClass actually refers to an imported Haxe type
                var registeredType = scope.getType(targetName);
                if (registeredType != null) {
                    switch (registeredType) {
                        case HaxeClass(registeredClass):
                            return isHaxeClassInheritanceCompatible(registeredClass, valueClass);
                        default:
                    }
                }
                return false;
            default:
        }

        // Abstract type compatibility via @:from / @:to implicit conversions
        // Uses TypeHandler for comprehensive from/to function checking
        switch (targetType) {
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;

                    // Convert valueType to a type string for TypeHandler
                    var valueTypeStr = yTypeToString(valueType);
                    if (valueTypeStr != null) {
                        // Use TypeHandler to check all @:from conversions comprehensively
                        if (yutautil.TypeHandler.canAssignToAbstract(valueTypeStr, interp.abstractPath)) return true;
                    }

                    // Direct probe check for primitives (handles runtime value matching)
                    switch (valueType) {
                        case YInt:
                            if (interp.matchesUnderlyingType(0) || interp.canConvertFrom(0)) return true;
                        case YFloat:
                            if (interp.matchesUnderlyingType(0.0) || interp.canConvertFrom(0.0)) return true;
                        case YString:
                            if (interp.matchesUnderlyingType("") || interp.canConvertFrom("")) return true;
                        case YBool:
                            if (interp.matchesUnderlyingType(true) || interp.canConvertFrom(true)) return true;
                        case HaxeAbstract(otherAbstract):
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                // Same abstract path
                                if (interp.abstractPath == otherInterp.abstractPath) return true;
                                // Check if the other abstract's output types can feed into this abstract's @:from
                                var otherToTypes = otherInterp.getToTypes();
                                for (toEntry in otherToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, interp.abstractPath)) return true;
                                }
                                // Check underlying type of the source abstract
                                if (otherInterp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(otherInterp.underlyingType, interp.abstractPath)) return true;
                                }
                            }
                        case HaxeClass(cls):
                            // Check if the class can be accepted by the abstract's @:from
                            var className = Type.getClassName(cls);
                            if (className != null && yutautil.TypeHandler.canAssignToAbstract(className, interp.abstractPath)) return true;
                        case _:
                    }
                }
            default:
        }

        // If the value is an abstract type, check if it can be converted TO the target
        switch (valueType) {
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;

                    // Convert targetType to a type string for TypeHandler
                    var targetTypeStr = yTypeToString(targetType);
                    if (targetTypeStr != null) {
                        // Use TypeHandler to check all @:to conversions comprehensively
                        if (yutautil.TypeHandler.canAbstractOutputType(interp.abstractPath, targetTypeStr)) return true;
                    }

                    // Direct @:to checks for primitives
                    switch (targetType) {
                        case YInt:
                            if (interp.canConvertTo("Int")) return true;
                        case YFloat:
                            if (interp.canConvertTo("Float")) return true;
                        case YString:
                            if (interp.canConvertTo("String")) return true;
                        case YBool:
                            if (interp.canConvertTo("Bool")) return true;
                        case HaxeClass(cls):
                            var className = Type.getClassName(cls);
                            if (className != null && interp.canConvertTo(className)) return true;
                        case HaxeAbstract(otherAbstract):
                            // Check if this abstract's @:to outputs can be accepted by the target abstract's @:from
                            if (Std.isOfType(otherAbstract, yutautil.typeregistry.AbstractInterpreter)) {
                                var otherInterp:yutautil.typeregistry.AbstractInterpreter = cast otherAbstract;
                                var myToTypes = interp.getToTypes();
                                for (toEntry in myToTypes) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(toEntry.typeName, otherInterp.abstractPath)) return true;
                                }
                                // Check underlying type chain
                                if (interp.underlyingType != null) {
                                    if (yutautil.TypeHandler.canAssignToAbstract(interp.underlyingType, otherInterp.abstractPath)) return true;
                                }
                            }
                        case _:
                    }
                }
            default:
        }

        // Typedef compatibility: if target or source is a struct/typedef string from YStruct
        switch [targetType, valueType] {
            case [YType.YStruct(targetStructName), YType.YStruct(valueStructName)]:
                // Check if both resolve to compatible typedefs or structures
                var resolvedTarget = yutautil.TypeHandler.resolveTypedef(targetStructName);
                var resolvedValue = yutautil.TypeHandler.resolveTypedef(valueStructName);
                if (resolvedTarget != null && resolvedValue != null) {
                    return yutautil.TypeHandler.isCompatible(resolvedValue, resolvedTarget);
                }
                // If one is a structure type string, compare structurally
                return targetStructName == valueStructName;
            default:
        }

        return false;
    }

    /**
     * Convert a YType to a type string for use with TypeHandler.
     * Returns null if the YType cannot be meaningfully converted.
     */
    private function yTypeToString(ytype:YType):Null<String> {
        return switch (ytype) {
            case YInt: "Int";
            case YFloat: "Float";
            case YString: "String";
            case YBool: "Bool";
            case Dynamic: "Dynamic";
            case Void: "Void";
            case YArray(elementType): "Array";
            case YFunction(_, _): "Function";
            case YClass(name): name;
            case YEnum(name): name;
            case YStruct(name): name;
            case HaxeClass(c): Type.getClassName(c);
            case HaxeEnum(e): Type.getEnumName(e);
            case HaxeAbstract(abstractType):
                if (Std.isOfType(abstractType, yutautil.typeregistry.AbstractInterpreter)) {
                    var interp:yutautil.typeregistry.AbstractInterpreter = cast abstractType;
                    interp.abstractPath;
                } else null;
            case HaxeType(t): Std.string(t);
            case Unknown: null;
        };
    }

    /**
     * Get superclass chain for inheritance checking
     */
    private function getSuperClasses(ytype:YType):Array<YType> {
        var supers = [];
        switch (ytype) {
            case YType.HaxeClass(c):
                var superClass = Type.getSuperClass(c);
                while (superClass != null) {
                    supers.push(YType.HaxeClass(superClass));
                    superClass = Type.getSuperClass(superClass);
                }
            case _:
        }
        return supers;
    }

    /**
     * Check Haxe class inheritance compatibility at runtime
     */
    private function isHaxeClassInheritanceCompatible(targetClass:Class<Dynamic>, valueClass:Class<Dynamic>):Bool {
        if (targetClass == valueClass) return true;

        try {
            // Check inheritance chain
            var currentClass = valueClass;
            while (currentClass != null) {
                if (currentClass == targetClass) return true;
                currentClass = Type.getSuperClass(currentClass);
            }
            return false;
        } catch (e:Dynamic) {
            // If reflection fails, be conservative
            return targetClass == valueClass;
        }
    }

    /**
     * Check YScript class inheritance compatibility at runtime
     */
    private function isYScriptClassInheritanceCompatible(targetName:String, valueName:String):Bool {
        if (targetName == valueName) return true;

        var valueClassDef = scope.getClass(valueName);
        return valueClassDef != null && valueClassDef.extendsClass(targetName);
    }

    /**
     * Infer YScript type from Haxe value (runtime version with enhanced checking)
     */
    private function inferTypeFromValue(value:Dynamic):YType {
        if (value == null) return YType.Dynamic;

        // Check for AbstractValue first (before generic class check)
        if (Std.isOfType(value, yutautil.typeregistry.AbstractValue)) {
            var absVal:yutautil.typeregistry.AbstractValue = cast value;
            return YType.HaxeAbstract(absVal.interpreter);
        }

        // Check for AbstractInterpreter (the type itself, not a value)
        if (Std.isOfType(value, yutautil.typeregistry.AbstractInterpreter)) {
            var interp:yutautil.typeregistry.AbstractInterpreter = cast value;
            return YType.HaxeAbstract(interp);
        }

        // Check for AbstractRuntimeInfo (the backing class of Abstract abstract)
        if (Std.isOfType(value, yutautil.Abstract.AbstractRuntimeInfo)) {
            var info:yutautil.Abstract.AbstractRuntimeInfo = cast value;
            return YType.HaxeAbstract(info.interpreter);
        }

        return switch (Type.typeof(value)) {
            case TInt: YType.YInt;
            case TFloat: YType.YFloat;
            case TBool: YType.YBool;
            case TClass(String): YType.YString;
            case TClass(Array):
                var arr:Array<Dynamic> = cast value;
                if (arr.length == 0) {
                    YType.YArray(YType.Dynamic);
                } else {
                    // Sample first element for type
                    var elementType = inferTypeFromValue(arr[0]);
                    YType.YArray(elementType);
                }
            case TClass(c): YType.HaxeClass(c);
            case TEnum(e): YType.HaxeEnum(e);
            case TFunction: YType.YFunction([], YType.Dynamic);
            case TObject: YType.Dynamic;
            case TNull: YType.Dynamic;
            case TUnknown: YType.Unknown;
        };
    }

    /**
     * Convert a value to string with special handling for abstract types
     */
    private function convertValueToString(value:Dynamic):String {
        if (value == null) return "null";
        if (Std.isOfType(value, String)) return cast value;

        // Check if value is an AbstractValue with string conversion
        if (Std.isOfType(value, yutautil.typeregistry.AbstractValue)) {
            var absVal:yutautil.typeregistry.AbstractValue = cast value;
            if (absVal.interpreter.canConvertTo("String")) {
                try {
                    var converted = absVal.interpreter.applyToConversion(absVal.rawValue, "String");
                    if (Std.isOfType(converted, String)) return cast converted;
                } catch (e:Dynamic) {
                    // Fall through to default conversion
                }
            }
        }

        // Check for toString method
        if (Reflect.hasField(value, "toString")) {
            try {
                var toStringMethod = Reflect.field(value, "toString");
                if (Reflect.isFunction(toStringMethod)) {
                    return cast Reflect.callMethod(value, toStringMethod, []);
                }
            } catch (e:Dynamic) {
                // Fall through to default
            }
        }

        // Default conversion
        return Std.string(value);
    }
}
