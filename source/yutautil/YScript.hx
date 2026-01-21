package yutautil;

import haxe.Constraints.Function;
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Type;

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
            case HaxeAbstract(a): Std.string(a);
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
    Native(func:Dynamic); // Direct Haxe function reference
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// AST SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript Abstract Syntax Tree
 */
enum YStatement {
    // Declarations
    VarDecl(name:String, type:YType, init:Null<YExpression>);
    FuncDecl(name:String, params:Array<YVar>, returnType:YType, body:YFunctionBody);
    ClassDecl(name:String, extend:Null<String>, implement:Array<String>, body:Array<YStatement>);

    // Control flow
    If(condition:YExpression, thenStmt:YStatement, elseStmt:Null<YStatement>);
    While(condition:YExpression, body:YStatement);
    For(init:Null<YStatement>, condition:Null<YExpression>, increment:Null<YExpression>, body:YStatement);
    Return(value:Null<YExpression>);
    Break;
    Continue;

    // Blocks and expressions
    Block(statements:Array<YStatement>);
    Expression(expr:YExpression);

    // Embedded code
    HaxeBlock(code:String);
    LuaBlock(code:String);
}

enum YExpression {
    // Literals
    IntLiteral(value:Int);
    FloatLiteral(value:Float);
    StringLiteral(value:String);
    BoolLiteral(value:Bool);

    // Identifiers and access
    Identifier(name:String);
    MemberAccess(object:YExpression, member:String);
    ArrayAccess(array:YExpression, index:YExpression);

    // Operations
    BinaryOp(left:YExpression, op:String, right:YExpression);
    UnaryOp(op:String, operand:YExpression);
    Assignment(left:YExpression, right:YExpression);

    // Function and constructor calls
    FunctionCall(func:YExpression, args:Array<YExpression>);
    New(type:YType, args:Array<YExpression>);

    // Type operations
    Cast(expr:YExpression, type:YType);
    Is(expr:YExpression, type:YType);
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// ERROR SYSTEM
// ═══════════════════════════════════════════════════════════════════════════════════════

class YScriptError extends haxe.Exception {
    public var location:Null<YLocation>;

    public function new(message:String, ?location:YLocation) {
        super(message);
        this.location = location;
    }
}

class YScriptParseError extends YScriptError {
    public function new(message:String, ?location:YLocation) {
        super('Parse Error: $message', location);
    }
}

class YScriptRuntimeError extends YScriptError {
    public function new(message:String, ?location:YLocation) {
        super('Runtime Error: $message', location);
    }
}

class YScriptTypeError extends YScriptError {
    public function new(message:String, ?location:YLocation) {
        super('Type Error: $message', location);
    }
}

typedef YLocation = {
    file:String,
    line:Int,
    column:Int
};

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

    public var scriptPath:String;
    public var isReady:Bool = false;
    public var hasErrors:Bool = false;
    public var lastError:String;

    public function new() {
        parser = new YScriptParser();
        runtime = new YScriptRuntime();
        scope = new YScope();
        setupBuiltins();
    }

    /**
     * ✅ INTEGRATION: Load script from source code
     */
    public function loadFromSource(source:String, ?path:String):Bool {
        try {
            this.scriptPath = path ?? "<inline>";
            var program = parser.parse(source);
            runtime.initialize(program, scope);
            isReady = true;
            hasErrors = false;
            return true;
        } catch (e:YScriptError) {
            hasErrors = true;
            lastError = e.message;
            trace('YScript: Failed to load script: ${e.message}');
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
            return null;
        }
    }

    /**
     * ✅ INTEGRATION: Check if function exists
     */
    public function hasFunction(name:String):Bool {
        return isReady && scope.hasFunction(name);
    }

    /**
     * ✅ INTEGRATION: Set variable from external system
     */
    public function setVariable(name:String, value:Dynamic, ?type:YType):Void {
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
    public function registerHaxeFunction(name:String, func:Dynamic):Void {
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
        registerHaxeFunction("trace", function(msg:Dynamic) { trace(msg); });
        registerHaxeFunction("print", function(msg:Dynamic) { Sys.println(Std.string(msg)); });

        // Built-in types
        scope.setType("Int", YType.YInt);
        scope.setType("Float", YType.YFloat);
        scope.setType("String", YType.YString);
        scope.setType("Bool", YType.YBool);
        scope.setType("Dynamic", YType.Dynamic);
        scope.setType("Void", YType.Void);
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

    public function new(name:String, superClass:Null<String>, interfaces:Array<String>) {
        this.name = name;
        this.superClass = superClass;
        this.interfaces = interfaces;
        this.fields = new StringMap();
        this.methods = new StringMap();
        this.constructors = [];
        this.isHaxeClass = false;
        this.haxeClassName = null;
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
}

/**
 * YScript class instance
 */
class YClassInstance {
    public var className:String;
    public var fields:StringMap<Dynamic>;
    public var classDef:YClassDefinition;
    public var haxeInstance:Null<Dynamic>; // Haxe instance if extending Haxe class

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
    }

    public function getField(name:String):Dynamic {
        if (fields.exists(name)) {
            return fields.get(name);
        }

        // Check Haxe instance if extending Haxe class
        if (haxeInstance != null) {
            return Reflect.field(haxeInstance, name);
        }

        return null;
    }

    public function setField(name:String, value:Dynamic):Void {
        if (classDef.fields.exists(name)) {
            fields.set(name, value);
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
    private var parent:Null<YScope>;

    public function new(?parent:YScope) {
        this.parent = parent;
        variables = new StringMap();
        functions = new StringMap();
        types = new StringMap();
        classes = new StringMap();
    }

    public function setVariable(name:String, variable:YVar):Void {
        variables.set(name, variable);
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
        functions.set(name, func);
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

    public function setType(name:String, type:YType):Void {
        types.set(name, type);
    }

    public function getType(name:String):Null<YType> {
        if (types.exists(name)) {
            return types.get(name);
        }
        return parent != null ? parent.getType(name) : null;
    }

    public function setClass(name:String, classDef:YClassDefinition):Void {
        classes.set(name, classDef);
    }

    public function getClass(name:String):Null<YClassDefinition> {
        if (classes.exists(name)) {
            return classes.get(name);
        }
        return parent != null ? parent.getClass(name) : null;
    }

    public function createChild():YScope {
        return new YScope(this);
    }

    public function createChildScope():YScope {
        return createChild();
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

        // Two-character operators
        var twoChar = source.substr(pos, 2);
        switch (twoChar) {
            case "==", "!=", "<=", ">=", "&&", "||", "++", "--":
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
            case '.': advance(); return makeToken(TDot, startLine, startColumn);
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
            "new", "this", "super", "null", "void", "cast", "is", "as",
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

    public function new() {}

    public function parse(source:String):Array<YStatement> {
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

        return statements;
    }

    private function parseStatement():Null<YStatement> {
        try {
            return switch (peek().type) {
                case TKeyword("var"): parseVarDeclaration();
                case TKeyword("function"): parseFunctionDeclaration();
                case TKeyword("class"): parseClassDeclaration();
                case TKeyword("if"): parseIfStatement();
                case TKeyword("while"): parseWhileStatement();
                case TKeyword("for"): parseForStatement();
                case TKeyword("return"): parseReturnStatement();
                case TKeyword("break"): advance(); YStatement.Break;
                case TKeyword("continue"): advance(); YStatement.Continue;
                case TLeftBrace: parseBlockStatement();
                case THaxeBlock(code): advance(); YStatement.HaxeBlock(code);
                case TLuaBlock(code): advance(); YStatement.LuaBlock(code);
                default: parseExpressionStatement();
            }
        } catch (e:YScriptError) {
            // Error recovery - skip to next statement
            synchronize();
            return null;
        }
    }

    private function parseVarDeclaration():YStatement {
        advance(); // consume 'var'

        var name = consumeIdentifier("Expected variable name");
        consume(TColon, "Expected ':' after variable name");
        var type = parseType();

        var init:Null<YExpression> = null;
        if (match([TAssign])) {
            init = parseExpression();
        }

        consume(TSemicolon, "Expected ';' after variable declaration");
        return YStatement.VarDecl(name, type, init);
    }

    private function parseFunctionDeclaration():YStatement {
        advance(); // consume 'function'

        var name = consumeIdentifier("Expected function name");
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
        consume(TColon, "Expected ':' before return type");
        var returnType = parseType();

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
            consume(TLeftBrace, "Expected '{' or haxe/lua block before function body");
            var statements:Array<YStatement> = [];

            while (!check(TRightBrace) && !isAtEnd()) {
                if (match([TNewline])) continue;
                var stmt = parseStatement();
                if (stmt != null) statements.push(stmt);
            }

            consume(TRightBrace, "Expected '}' after function body");
            body = YFunctionBody.YScript(statements);
        }

        return YStatement.FuncDecl(name, params, returnType, body);
    }

    private function parseClassDeclaration():YStatement {
        advance(); // consume 'class'

        var name = consumeIdentifier("Expected class name");

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

        var body:Array<YStatement> = [];
        while (!check(TRightBrace) && !isAtEnd()) {
            if (match([TNewline])) continue;
            var stmt = parseStatement();
            if (stmt != null) body.push(stmt);
        }

        consume(TRightBrace, "Expected '}' after class body");

        return YStatement.ClassDecl(name, extend, implement, body);
    }

    private function parseIfStatement():YStatement {
        advance(); // consume 'if'

        consume(TLeftParen, "Expected '(' after 'if'");
        var condition = parseExpression();
        consume(TRightParen, "Expected ')' after if condition");

        var thenStmt = parseStatement();
        var elseStmt:Null<YStatement> = null;

        if (match([TKeyword("else")])) {
            elseStmt = parseStatement();
        }

        return YStatement.If(condition, thenStmt, elseStmt);
    }

    private function parseWhileStatement():YStatement {
        advance(); // consume 'while'

        consume(TLeftParen, "Expected '(' after 'while'");
        var condition = parseExpression();
        consume(TRightParen, "Expected ')' after while condition");

        var body = parseStatement();
        return YStatement.While(condition, body);
    }

    private function parseForStatement():YStatement {
        advance(); // consume 'for'

        consume(TLeftParen, "Expected '(' after 'for'");

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
        return YStatement.For(init, condition, increment, body);
    }

    private function parseReturnStatement():YStatement {
        advance(); // consume 'return'

        var value:Null<YExpression> = null;
        if (!check(TSemicolon)) {
            value = parseExpression();
        }

        consume(TSemicolon, "Expected ';' after return value");
        return YStatement.Return(value);
    }

    private function parseBlockStatement():YStatement {
        consume(TLeftBrace, "Expected '{'");

        var statements:Array<YStatement> = [];
        while (!check(TRightBrace) && !isAtEnd()) {
            if (match([TNewline])) continue;
            var stmt = parseStatement();
            if (stmt != null) statements.push(stmt);
        }

        consume(TRightBrace, "Expected '}'");
        return YStatement.Block(statements);
    }

    private function parseExpressionStatement():YStatement {
        var expr = parseExpression();
        consume(TSemicolon, "Expected ';' after expression");
        return YStatement.Expression(expr);
    }

    private function parseExpression():YExpression {
        return parseAssignment();
    }

    private function parseAssignment():YExpression {
        var expr = parseLogicalOr();

        if (match([TAssign])) {
            var right = parseAssignment();
            return YExpression.Assignment(expr, right);
        }

        return expr;
    }

    private function parseLogicalOr():YExpression {
        var expr = parseLogicalAnd();

        while (matchOperator("||")) {
            var op = previous().type;
            var right = parseLogicalAnd();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseLogicalAnd():YExpression {
        var expr = parseEquality();

        while (matchOperator("&&")) {
            var op = previous().type;
            var right = parseEquality();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseEquality():YExpression {
        var expr = parseComparison();

        while (matchOperator("==") || matchOperator("!=")) {
            var op = previous().type;
            var right = parseComparison();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseComparison():YExpression {
        var expr = parseAddition();

        while (matchOperator(">") || matchOperator(">=") || matchOperator("<") || matchOperator("<=")) {
            var op = previous().type;
            var right = parseAddition();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseAddition():YExpression {
        var expr = parseMultiplication();

        while (matchOperator("+") || matchOperator("-")) {
            var op = previous().type;
            var right = parseMultiplication();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseMultiplication():YExpression {
        var expr = parseUnary();

        while (matchOperator("*") || matchOperator("/") || matchOperator("%")) {
            var op = previous().type;
            var right = parseUnary();
            expr = YExpression.BinaryOp(expr, getOperatorString(op), right);
        }

        return expr;
    }

    private function parseUnary():YExpression {
        if (matchOperator("!") || matchOperator("-") || matchOperator("+")) {
            var op = previous().type;
            var right = parseUnary();
            return YExpression.UnaryOp(getOperatorString(op), right);
        }

        return parseCall();
    }

    private function parseCall():YExpression {
        var expr = parsePrimary();

        while (true) {
            if (match([TLeftParen])) {
                expr = finishCall(expr);
            } else if (match([TDot])) {
                var name = consumeIdentifier("Expected property name after '.'");
                expr = YExpression.MemberAccess(expr, name);
            } else if (match([TLeftBracket])) {
                var index = parseExpression();
                consume(TRightBracket, "Expected ']' after array index");
                expr = YExpression.ArrayAccess(expr, index);
            } else {
                break;
            }
        }

        return expr;
    }

    private function finishCall(callee:YExpression):YExpression {
        var args:Array<YExpression> = [];

        if (!check(TRightParen)) {
            do {
                args.push(parseExpression());
            } while (match([TComma]));
        }

        consume(TRightParen, "Expected ')' after arguments");
        return YExpression.FunctionCall(callee, args);
    }

    private function parsePrimary():YExpression {
        return switch (peek().type) {
            case TBool(value): advance(); YExpression.BoolLiteral(value);
            case TInt(value): advance(); YExpression.IntLiteral(value);
            case TFloat(value): advance(); YExpression.FloatLiteral(value);
            case TString(value): advance(); YExpression.StringLiteral(value);
            case TIdentifier(name): advance(); YExpression.Identifier(name);
            case TKeyword("null"): advance(); YExpression.Identifier("null");
            case TKeyword("this"): advance(); YExpression.Identifier("this");
            case TKeyword("new"): parseNewExpression();
            case TLeftParen: parseGrouping();
            default: throw new YScriptParseError('Unexpected token: ${peek().type}', getCurrentLocation());
        }
    }

    private function parseNewExpression():YExpression {
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
        return YExpression.New(type, args);
    }

    private function parseGrouping():YExpression {
        consume(TLeftParen, "Expected '('");
        var expr = parseExpression();
        consume(TRightParen, "Expected ')' after expression");
        return expr;
    }

    private function parseType():YType {
        if (match([TIdentifier("Int")])) return YType.YInt;
        if (match([TIdentifier("Float")])) return YType.YFloat;
        if (match([TIdentifier("String")])) return YType.YString;
        if (match([TIdentifier("Bool")])) return YType.YBool;
        if (match([TIdentifier("Dynamic")])) return YType.Dynamic;
        if (match([TIdentifier("Void")])) return YType.Void;

        // Array type
        if (match([TIdentifier("Array")])) {
            consume(TOperator("<"), "Expected '<' after Array");
            var elementType = parseType();
            consume(TOperator(">"), "Expected '>' after Array element type");
            return YType.YArray(elementType);
        }

        // Custom or Haxe type
        var typeName = consumeIdentifier("Expected type name");
        return YType.YClass(typeName); // Will be resolved later
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
            case TIdentifier(_):
                switch (peek().type) {
                    case TIdentifier(_): true;
                    default: false;
                }
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
            file: "unknown",
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
}

// ═══════════════════════════════════════════════════════════════════════════════════════
// RUNTIME
// ═══════════════════════════════════════════════════════════════════════════════════════

/**
 * YScript runtime execution engine with Haxe integration
 */
class YScriptRuntime {
    public var scope:YScope;
    private var returnValue:Dynamic = null;
    private var shouldReturn:Bool = false;
    private var shouldBreak:Bool = false;
    private var shouldContinue:Bool = false;

    #if LUA_ALLOWED
    private var luaState:State = null;
    #end

    public function new(?scope:YScope) {
        this.scope = scope ?? new YScope();

        #if LUA_ALLOWED
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
        throw new YScriptRuntimeError('Function not found: $name', null);
    }

    public function destroy():Void {
        #if LUA_ALLOWED
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
        try {
            switch (stmt) {
                case VarDecl(name, type, init):
                    var value:Dynamic = null;
                    if (init != null) {
                        value = evaluateExpression(init);
                    } else {
                        value = getDefaultValue(type);
                    }

                    scope.setVariable(name, new YVar(name, type, value));

                case FuncDecl(name, params, returnType, body):
                    var func = new YFunction(name, params, returnType, body);
                    scope.setFunction(name, func);

                case ClassDecl(name, extend, implement, body):
                    var classDef = new YClassDefinition(name, extend, implement);

                    // Check if extending a Haxe class
                    if (extend != null) {
                        var haxeClass = Type.resolveClass(extend);
                        if (haxeClass != null) {
                            classDef.isHaxeClass = true;
                            classDef.haxeClassName = extend;
                        }
                    }

                    // Process class body
                    var classScope = scope.createChild();
                    var oldScope = this.scope;
                    this.scope = classScope;

                    for (statement in body) {
                        switch (statement) {
                            case VarDecl(fieldName, fieldType, fieldInit):
                                var field = new YVar(fieldName, fieldType);
                                if (fieldInit != null) {
                                    field.value = evaluateExpression(fieldInit);
                                }
                                classDef.addField(field);

                            case FuncDecl(methodName, params, returnType, methodBody):
                                var method = new YFunction(methodName, params, returnType, methodBody);
                                if (methodName == name) {
                                    classDef.addConstructor(method);
                                } else {
                                    classDef.addMethod(method);
                                }

                            default:
                                throw new YScriptRuntimeError('Invalid statement in class body', null);
                        }
                    }

                    this.scope = oldScope;
                    scope.setClass(name, classDef);

                case If(condition, thenStmt, elseStmt):
                    var condValue = evaluateExpression(condition);
                    if (isTruthy(condValue)) {
                        executeStatement(thenStmt);
                    } else if (elseStmt != null) {
                        executeStatement(elseStmt);
                    }

                case While(condition, body):
                    while (isTruthy(evaluateExpression(condition))) {
                        executeStatement(body);

                        if (shouldReturn || shouldBreak) break;
                        if (shouldContinue) {
                            shouldContinue = false;
                            continue;
                        }
                    }

                case For(init, condition, increment, body):
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

                case Return(value):
                    returnValue = value != null ? evaluateExpression(value) : null;
                    shouldReturn = true;

                case Break:
                    shouldBreak = true;

                case Continue:
                    shouldContinue = true;

                case Block(statements):
                    var blockScope = scope.createChild();
                    var oldScope = this.scope;
                    this.scope = blockScope;

                    for (statement in statements) {
                        executeStatement(statement);
                        if (shouldReturn || shouldBreak || shouldContinue) break;
                    }

                    this.scope = oldScope;

                case Expression(expr):
                    evaluateExpression(expr);

                case HaxeBlock(code):
                    executeHaxeCode(code);

                case LuaBlock(code):
                    #if LUA_ALLOWED
                    executeLuaCode(code);
                    #else
                    throw new YScriptRuntimeError("Lua support not enabled", null);
                    #end
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Runtime error: $e', null);
        }
    }

    public function evaluateExpression(expr:YExpression):Dynamic {
        return switch (expr) {
            case IntLiteral(value): value;
            case FloatLiteral(value): value;
            case StringLiteral(value): value;
            case BoolLiteral(value): value;

            case Identifier(name):
                if (scope.hasVariable(name)) {
                    scope.getVariable(name).value;
                } else {
                    // Try to resolve as Haxe type or global
                    resolveHaxeIdentifier(name);
                }

            case BinaryOp(left, op, right):
                var leftValue = evaluateExpression(left);
                var rightValue = evaluateExpression(right);
                evaluateBinaryOperation(leftValue, op, rightValue);

            case UnaryOp(op, operand):
                var value = evaluateExpression(operand);
                evaluateUnaryOperation(op, value);

            case Assignment(target, value):
                var val = evaluateExpression(value);
                assignToTarget(target, val);
                val;

            case FunctionCall(callee, args):
                var argValues = [for (arg in args) evaluateExpression(arg)];
                callFunctionExpression(callee, argValues);

            case MemberAccess(object, member):
                var objValue = evaluateExpression(object);
                accessMember(objValue, member);

            case ArrayAccess(array, index):
                var arrayValue = evaluateExpression(array);
                var indexValue = evaluateExpression(index);
                accessArrayElement(arrayValue, indexValue);

            case New(type, args):
                var argValues = [for (arg in args) evaluateExpression(arg)];
                createInstance(type, argValues);

            case Cast(expr, type):
                var value = evaluateExpression(expr);
                // For now, just return the value as casting is complex
                value;

            case Is(expr, type):
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

    private function isTruthy(value:Dynamic):Bool {
        if (value == null) return false;
        if (Std.is(value, Bool)) return value;
        if (Std.is(value, Float) || Std.is(value, Int)) return value != 0;
        if (Std.is(value, String)) return cast(value, String).length > 0;
        return true;
    }

    private function evaluateBinaryOperation(left:Dynamic, op:String, right:Dynamic):Dynamic {
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
            default: throw new YScriptRuntimeError('Unknown binary operator: $op', null);
        }
    }

    private function evaluateUnaryOperation(op:String, operand:Dynamic):Dynamic {
        return switch (op) {
            case "-": -operand;
            case "+": operand;
            case "!": !isTruthy(operand);
            default: throw new YScriptRuntimeError('Unknown unary operator: $op', null);
        }
    }

    private function assignToTarget(target:YExpression, value:Dynamic):Void {
        switch (target) {
            case Identifier(name):
                if (scope.hasVariable(name)) {
                    var variable = scope.getVariable(name);
                    variable.value = value;
                } else {
                    throw new YScriptRuntimeError('Undefined variable: $name', null);
                }

            case MemberAccess(object, member):
                var objValue = evaluateExpression(object);
                setMember(objValue, member, value);

            case ArrayAccess(array, index):
                var arrayValue = evaluateExpression(array);
                var indexValue = evaluateExpression(index);
                setArrayElement(arrayValue, indexValue, value);

            default:
                throw new YScriptRuntimeError('Invalid assignment target', null);
        }
    }

    private function callFunctionExpression(callee:YExpression, args:Array<Dynamic>):Dynamic {
        switch (callee) {
            case Identifier(name):
                // YScript function
                if (scope.hasFunction(name)) {
                    var func = scope.getFunction(name);
                    return callYFunction(func, args);
                }

                // Haxe function
                return callHaxeFunction(name, args);

            case MemberAccess(object, method):
                var objValue = evaluateExpression(object);
                return callMethod(objValue, method, args);

            default:
                throw new YScriptRuntimeError('Cannot call this expression as a function', null);
        }
    }

    private function callYFunction(func:YFunction, args:Array<Dynamic>):Dynamic {
        // Create new scope for function execution
        var functionScope = scope.createChild();

        // Bind parameters - only validate argument count for non-native functions
        if (!func.isNative && args.length != func.parameters.length) {
            throw new YScriptRuntimeError('Function "${func.name}" expected ${func.parameters.length} arguments, got ${args.length}', null);
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
                    #if LUA_ALLOWED
                    result = executeLuaCode(code);
                    #else
                    throw new YScriptRuntimeError("Lua support not enabled", null);
                    #end

                case Native(nativeFunc):
                    result = Reflect.callMethod(null, nativeFunc, args);
            }
        } catch (e:YScriptError) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            throw e;
        } catch (e:Dynamic) {
            this.scope = oldScope;
            shouldReturn = oldReturn;
            throw new YScriptRuntimeError('Runtime error: $e', null);
        }

        this.scope = oldScope;
        shouldReturn = oldReturn;

        return result;
    }

    private function resolveHaxeIdentifier(name:String):Dynamic {
        try {
            // Try to resolve as a Haxe type or global
            var type = Type.resolveClass(name);
            if (type != null) return type;

            var enumType = Type.resolveEnum(name);
            if (enumType != null) return enumType;

            // Check for static fields
            return Reflect.field(Type.resolveClass("Std"), name);
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Unknown identifier: $name', null);
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

            throw new YScriptRuntimeError('Unknown function: $name', null);
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error calling function $name: $e', null);
        }
    }

    private function callMethod(object:Dynamic, method:String, args:Array<Dynamic>):Dynamic {
        try {
            var methodFunction = Reflect.field(object, method);
            if (methodFunction != null && Reflect.isFunction(methodFunction)) {
                return Reflect.callMethod(object, methodFunction, args);
            } else {
                throw new YScriptRuntimeError('Method $method not found', null);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error calling method $method: $e', null);
        }
    }

    private function accessMember(object:Dynamic, member:String):Dynamic {
        try {
            return Reflect.field(object, member);
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error accessing member $member: $e', null);
        }
    }

    private function setMember(object:Dynamic, member:String, value:Dynamic):Void {
        try {
            Reflect.setField(object, member, value);
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error setting member $member: $e', null);
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
                throw new YScriptRuntimeError('Array index out of bounds: $idx', null);
            } else {
                throw new YScriptRuntimeError('Cannot index non-array type', null);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error accessing array element: $e', null);
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
                    throw new YScriptRuntimeError('Array index out of bounds: $idx', null);
                }
            } else {
                throw new YScriptRuntimeError('Cannot index non-array type', null);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error setting array element: $e', null);
        }
    }

    private function createInstance(type:YType, args:Array<Dynamic>):Dynamic {
        try {
            switch (type) {
                case YClass(className):
                    var classDef = scope.getClass(className);
                    if (classDef != null) {
                        var instance = new YClassInstance(className, classDef);

                        // If extending Haxe class, create Haxe instance
                        if (classDef.isHaxeClass && classDef.haxeClassName != null) {
                            var haxeClass = Type.resolveClass(classDef.haxeClassName);
                            if (haxeClass != null) {
                                instance.haxeInstance = Type.createInstance(haxeClass, args);
                            }
                        }

                        // Call YScript constructor if available
                        if (classDef.constructors.length > 0) {
                            var constructor = findMatchingConstructor(classDef.constructors, args);
                            if (constructor != null) {
                                callYFunctionOnInstance(constructor, args, instance);
                            }
                        }

                        return instance;
                    } else {
                        throw new YScriptRuntimeError('Unknown YScript class: $className', null);
                    }

                case HaxeClass(classType):
                    if (classType != null) {
                        return Type.createInstance(classType, args);
                    } else {
                        throw new YScriptRuntimeError('Null Haxe class type', null);
                    }

                case YArray(elementType):
                    return [];

                case YEnum(_):
                    throw new YScriptRuntimeError('Cannot instantiate enum type directly', null);

                case YStruct(_):
                    throw new YScriptRuntimeError('Struct instantiation not implemented yet', null);

                case HaxeType(_):
                    throw new YScriptRuntimeError('Cannot instantiate raw Haxe type', null);

                case HaxeEnum(_):
                    throw new YScriptRuntimeError('Cannot instantiate Haxe enum directly', null);

                case Unknown:
                    throw new YScriptRuntimeError('Cannot instantiate unknown type', null);

                default:
                    throw new YScriptRuntimeError('Cannot instantiate type: $type', null);
            }
        } catch (e:YScriptError) {
            throw e;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('Error creating instance: $e', null);
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

    private function callYFunctionOnInstance(func:YFunction, args:Array<Dynamic>, instance:YClassInstance):Dynamic {
        var functionScope = scope.createChild();

        // Add 'this' reference
        functionScope.setVariable("this", new YVar("this", YType.YClass(instance.className), instance));

        // Bind parameters - only validate argument count for non-native functions
        if (!func.isNative && args.length != func.parameters.length) {
            throw new YScriptRuntimeError('Method "${func.name}" expected ${func.parameters.length} arguments, got ${args.length}', null);
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
                    #if LUA_ALLOWED
                    result = executeLuaCode(code);
                    #else
                    throw new YScriptRuntimeError("Lua support not enabled", null);
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
            throw new YScriptRuntimeError('Runtime error: $e', null);
        }

        this.scope = oldScope;
        shouldReturn = oldReturn;
				return result;
    }

    private function executeHaxeCode(code:String):Dynamic {
        return executeHaxeCodeWithHScript(code);
    }

    #if LUA_ALLOWED
    private function executeLuaCode(code:String):Dynamic {
        try {
            if (luaState == null) {
                throw new YScriptRuntimeError("Lua state not initialized", null);
            }

            // Execute Lua code
            var result = LuaL.dostring(luaState, code);

            if (result != 0) {
                var error = Lua.tostring(luaState, -1);
                Lua.pop(luaState, 1);
                throw new YScriptRuntimeError('Lua error: $error', null);
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
            throw new YScriptRuntimeError('Error executing Lua code: $e', null);
        }
    }
    #end

    public function cleanup():Void {
        #if LUA_ALLOWED
        if (luaState != null) {
            Lua.close(luaState);
            luaState = null;
        }
        #end
    }

    /**
     * ✅ HSCRIPT INTEGRATION: Execute Haxe code using HScript
     */
    private function executeHaxeCodeWithHScript(code:String):Dynamic {
        #if HSCRIPT_ALLOWED
        try {
            var parser = new hscript.Parser();
            var interp = new hscript.Interp();

            // Sync YScript variables to HScript environment
						@:privateAccess
            for (varName in scope.variables.keys()) {
                var yvar = scope.variables.get(varName);
                interp.variables.set(varName, yvar.value);
            }

            // Parse and execute the code
            var program = parser.parseString(code);
            var result = interp.execute(program);

            // Sync variables back to YScript scope
            for (varName in interp.variables.keys()) {
                if (scope.hasVariable(varName)) {
                    var yvar = scope.getVariable(varName);
                    yvar.value = interp.variables.get(varName);
                }
            }

            return result;
        } catch (e:Dynamic) {
            throw new YScriptRuntimeError('HScript execution error: $e', null);
        }
        #else
        throw new YScriptRuntimeError("HScript support not enabled", null);
        #end
    }
}
