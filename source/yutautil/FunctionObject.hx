package yutautil;

/**
 * FunctionObject - A simplified function capture and storage system
 *
 * This system provides a way to store functions with serializable representations
 * that can be saved to files and restored at runtime. It supports three function types:
 * - StaticFunc: Static functions that don't require an instance
 * - InstFunc: Instance methods that require a class instance
 * - AnonFunc: Anonymous functions with flexible context
 *
 * Functions are stored with their metadata and expression tree representation,
 * allowing them to be serialized to JSON and emulated when original references are lost.
 *
 * Usage:
 *   // Store a runtime function
 *   var func = FunctionObject.store(myFunction, StaticFunc, null, "myFunction");
 *
 *   // Call the stored function
 *   var result = func.call([arg1, arg2]);
 *
 *   // Save all functions to file
 *   FunctionStorage.saveToFile("functions.json");
 *
 *   // Load functions from file
 *   FunctionStorage.loadFromFile("functions.json");
 */

#if macro
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
#end

// Import expression tree system for function representation
import yutautil.save.ExpressionTree;

/**
 * Function types for the simplified system
 */
enum FuncType {
    StaticFunc;
    InstFunc;
    AnonFunc;
}

/**
 * Function information including signature and representation
 */
typedef FunctionInfo = {
    var name:String;
    var className:Null<String>;
    var returnType:String;
    var args:Array<FunctionArg>;
    var isStatic:Bool;
    var isInline:Bool;
}

/**
 * Function argument information
 */
typedef FunctionArg = {
    var name:String;
    var type:String;
    var isOptional:Bool;
    var defaultValue:Null<String>;
}

/**
 * Complete function representation that can be serialized
 */
typedef SerializableFunction = {
    var id:Int;
    var info:FunctionInfo;
    var type:FuncType;
    var body:ExpressionTree;
    var bodyString:String;  // String version for debugging/fallback
    var originalFunction:Null<Dynamic>;  // Keep original for performance (null after serialization)
}

/**
 * Abstract wrapper for stored functions with enhanced call capability and debugging
 */
abstract FunctionObject(Int) {

    /**
     * Create a new FunctionObject from a function ID
     */
    public inline function new(id:Int) {
        this = id;
    }

    /**
     * Store a runtime function and return a FunctionObject
     * @param func The function to store
     * @param type Function type (StaticFunc, InstFunc, AnonFunc)
     * @param className Class name for InstFunc validation
     * @param name Optional function name for debugging
     */
    public static function store(func:Dynamic, type:FuncType, ?className:String, ?name:String):FunctionObject {
        var id = FunctionStorage.storeRuntimeFunction(func, type, className, name);
        return new FunctionObject(id);
    }

    /**
     * Store a captured function (from macro) and return a FunctionObject
     */
    public static function storeCaptured(capturedFunc:SerializableFunction):FunctionObject {
        var id = FunctionStorage.storeCapturedFunction(capturedFunc);
        return new FunctionObject(id);
    }

    /**
     * Call the function with arguments
     * @param args Arguments to pass to the function
     * @param instance Instance object (required for InstFunc)
     * @return Function result
     */
    public function call(?args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        return FunctionStorage.callFunction(this, args, instance);
    }

    /**
     * Get function information
     */
    public function getInfo():SerializableFunction {
        return FunctionStorage.getFunction(this);
    }

    /**
     * Get function type
     */
    public function getType():FuncType {
        var func = FunctionStorage.getFunction(this);
        return func != null ? func.type : null;
    }

    /**
     * Get the function name for debugging
     */
    public function getName():String {
        var stored = FunctionStorage.getFunction(this);
        return stored != null ? stored.info.name : "invalid";
    }

    /**
     * Get the class name if this is an instance function
     */
    public function getClassName():String {
        var stored = FunctionStorage.getFunction(this);
        return stored != null ? stored.info.className : null;
    }

    /**
     * Check if this function object is valid (function exists)
     */
    public function isValid():Bool {
        return FunctionStorage.getFunction(this) != null;
    }

    /**
     * Check if this function requires an instance
     */
    public function needsInstance():Bool {
        return getType() == InstFunc;
    }

    /**
     * Get the function ID
     */
    public function getId():Int {
        return this;
    }

    /**
     * Get function signature information
     */
    public function getFunctionInfo():FunctionInfo {
        var func = FunctionStorage.getFunction(this);
        return func != null ? func.info : null;
    }

    /**
     * Prepare this function for serialization (removes runtime references)
     */
    public function prepareForSerialization():Void {
        FunctionStorage.prepareForSerialization(this);
    }

    /**
     * Get a string representation of this function object
     */
    public function toString():String {
        var stored = FunctionStorage.getFunction(this);
        if (stored == null) {
            return 'FunctionObject(${this}: INVALID)';
        }

        var className = stored.info.className != null ? '${stored.info.className}.' : '';
        return 'FunctionObject(${this}: ${className}${stored.info.name}[${stored.type}])';
    }

    /**
     * Create a FunctionObject from a macro-captured function
     * @param funcExpr The function expression
     * @param type Function type
     * @param className Optional class name for InstFunc
     * @return Function ID (wrapped in FunctionObject constructor)
     */
    public static macro function capture(funcExpr:Expr, type:Expr, ?className:Expr):Expr {
        var capturedFunc = FunctionCapture.captureFunctionFromExpr(funcExpr, type, className);

        return macro {
            var id = FunctionStorage.storeCapturedFunction($capturedFunc);
            new FunctionObject(id);
        };
    }

    /**
     * Store a runtime function with minimal information
     * @param func The function to store
     * @param type Function type
     * @param className Optional class name for InstFunc
     * @return New FunctionObject
     */
    public static function store(func:Dynamic, type:FuncType, ?className:String, ?name:String):FunctionObject {
        var id = FunctionStorage.storeRuntimeFunction(func, type, className, name);
        return new FunctionObject(id);
    }
}

/**
 * Macro utilities for capturing function representations
 */
class FunctionCapture {

    #if macro

    /**
     * Capture a function expression and convert to SerializableFunction
     */
    public static function captureFunctionFromExpr(funcExpr:Expr, typeExpr:Expr, ?classNameExpr:Expr):Expr {
        var typeStr = ExprTools.toString(typeExpr);
        var className = classNameExpr != null ? ExprTools.toString(classNameExpr) : null;

        // Remove quotes if present
        if (className != null && className.charAt(0) == '"' && className.charAt(className.length-1) == '"') {
            className = className.substring(1, className.length-1);
        }

        var funcType = switch (typeStr) {
            case "StaticFunc": FuncType.StaticFunc;
            case "InstFunc": FuncType.InstFunc;
            case "AnonFunc": FuncType.AnonFunc;
            case _: Context.error('Invalid function type: ${typeStr}', typeExpr.pos);
        };

        // Extract function information based on expression type
        return switch (funcExpr.expr) {
            case EFunction(kind, func):
                // Inline function definition - capture full structure
                captureFunctionDefinition(func, funcType, className, "anonymous");

            case EField(e, fieldName):
                // Method reference - capture method info
                captureMethodReference(e, fieldName, funcType, className);

            case _:
                // Other expression types - treat as runtime function
                captureRuntimeFunction(funcExpr, funcType, className);
        };
    }

    private static function captureFunctionDefinition(func:Function, type:FuncType, ?className:String, ?name:String):Expr {
        var functionInfo = buildFunctionInfo(func, className, name);
        var bodyTree = convertExpressionToTree(func.expr);
        var bodyString = func.expr != null ? ExprTools.toString(func.expr) : "";

        return macro {
            var serializableFunc:yutautil.FunctionObject.SerializableFunction = {
                id: -1, // Will be set by storage
                info: $v{functionInfo},
                type: $v{type},
                body: $v{bodyTree},
                bodyString: $v{bodyString},
                originalFunction: null
            };
            serializableFunc;
        };
    }

    private static function captureMethodReference(objectExpr:Expr, methodName:String, type:FuncType, ?className:String):Expr {
        // For method references, we create a placeholder function that will be resolved at runtime
        var functionInfo:FunctionInfo = {
            name: methodName,
            className: className,
            returnType: "Dynamic",
            args: [], // Will be determined at runtime
            isStatic: type == StaticFunc,
            isInline: false
        };

        return macro {
            var serializableFunc:yutautil.FunctionObject.SerializableFunction = {
                id: -1,
                info: $v{functionInfo},
                type: $v{type},
                body: yutautil.save.ExpressionTree.ECall(
                    yutautil.save.ExpressionTree.EField(
                        yutautil.save.ExpressionTree.EConst(yutautil.save.ExpressionTree.ConstantTree.CIdent("__instance")),
                        $v{methodName}
                    ),
                    [yutautil.save.ExpressionTree.EConst(yutautil.save.ExpressionTree.ConstantTree.CIdent("__args"))]
                ),
                bodyString: 'return __instance.${methodName}(__args);',
                originalFunction: $objectExpr.$methodName
            };
            serializableFunc;
        };
    }

    private static function captureRuntimeFunction(funcExpr:Expr, type:FuncType, ?className:String):Expr {
        // For runtime functions, create minimal representation
        var functionInfo:FunctionInfo = {
            name: "runtime",
            className: className,
            returnType: "Dynamic",
            args: [],
            isStatic: type == StaticFunc,
            isInline: false
        };

        return macro {
            var serializableFunc:yutautil.FunctionObject.SerializableFunction = {
                id: -1,
                info: $v{functionInfo},
                type: $v{type},
                body: yutautil.save.ExpressionTree.EConst(yutautil.save.ExpressionTree.ConstantTree.CIdent("__runtime")),
                bodyString: "/* runtime function */",
                originalFunction: $funcExpr
            };
            serializableFunc;
        };
    }

    private static function buildFunctionInfo(func:Function, ?className:String, ?name:String):FunctionInfo {
        var args:Array<FunctionArg> = [];
        for (arg in func.args) {
            args.push({
                name: arg.name,
                type: arg.type != null ? ComplexTypeTools.toString(arg.type) : "Dynamic",
                isOptional: arg.opt,
                defaultValue: arg.value != null ? ExprTools.toString(arg.value) : null
            });
        }

        return {
            name: name != null ? name : "anonymous",
            className: className,
            returnType: func.ret != null ? ComplexTypeTools.toString(func.ret) : "Dynamic",
            args: args,
            isStatic: false, // Will be determined by type
            isInline: false
        };
    }

    private static function convertExpressionToTree(expr:Expr):ExpressionTree {
        if (expr == null) {
            return ExpressionTree.ENull;
        }

        return switch (expr.expr) {
            case EConst(c):
                convertConstant(c);
            case EBinop(op, e1, e2):
                ExpressionTree.EBinop(op.getName(), convertExpressionToTree(e1), convertExpressionToTree(e2));
            case ECall(e, params):
                var paramTrees = params.map(convertExpressionToTree);
                ExpressionTree.ECall(convertExpressionToTree(e), paramTrees);
            case EField(e, field):
                ExpressionTree.EField(convertExpressionToTree(e), field);
            case EReturn(e):
                var returnTree = e != null ? convertExpressionToTree(e) : ExpressionTree.ENull;
                ExpressionTree.EReturn(returnTree);
            case EBlock(exprs):
                var exprTrees = exprs.map(convertExpressionToTree);
                ExpressionTree.EBlock(exprTrees);
            case EIf(econd, eif, eelse):
                var elseTree = eelse != null ? convertExpressionToTree(eelse) : ExpressionTree.ENull;
                ExpressionTree.EIf(convertExpressionToTree(econd), convertExpressionToTree(eif), elseTree);
            case EVars(vars):
                var varTrees = vars.map(v -> {
                    name: v.name,
                    type: v.type != null ? ComplexTypeTools.toString(v.type) : null,
                    expr: v.expr != null ? convertExpressionToTree(v.expr) : ExpressionTree.ENull
                });
                ExpressionTree.EVars(varTrees);
            // Add more cases as needed
            case _:
                // Fallback for unhandled expression types
                ExpressionTree.EConst(ExpressionTree.ConstantTree.CString(ExprTools.toString(expr)));
        };
    }

    private static function convertConstant(c:Constant):ExpressionTree {
        var constTree = switch (c) {
            case CInt(v): ExpressionTree.ConstantTree.CInt(v);
            case CFloat(f): ExpressionTree.ConstantTree.CFloat(f);
            case CString(s, kind): ExpressionTree.ConstantTree.CString(s);
            case CIdent(s): ExpressionTree.ConstantTree.CIdent(s);
            case CRegexp(r, opt): ExpressionTree.ConstantTree.CRegexp(r, opt);
        };
        return ExpressionTree.EConst(constTree);
    }

    #end
}

/**
 * Enhanced stored function representation with serializable components
 */
typedef StoredFunction = SerializableFunction;

/**
 * Global function storage and execution system
 */
class FunctionStorage {

    private static var _functions:Array<SerializableFunction> = [];
    private static var _nextId:Int = 0;

    /**
     * Store a captured function (from macro)
     * @param capturedFunc The captured function representation
     * @return Function ID
     */
    public static function storeCapturedFunction(capturedFunc:SerializableFunction):Int {
        var id = _nextId++;
        capturedFunc.id = id;
        _functions[id] = capturedFunc;

        trace('Stored captured function ID ${id}: ${capturedFunc.info.name} (${capturedFunc.type})');
        return id;
    }

    /**
     * Store a runtime function with minimal representation
     * @param func The runtime function
     * @param type Function type
     * @param className Optional class name
     * @param name Optional function name
     * @return Function ID
     */
    public static function storeRuntimeFunction(func:Dynamic, type:FuncType, ?className:String, ?name:String):Int {
        if (func == null || !Reflect.isFunction(func)) {
            throw "Cannot store null or non-function object";
        }

        var id = _nextId++;

        var functionInfo:FunctionInfo = {
            name: name != null ? name : "runtime",
            className: className,
            returnType: "Dynamic",
            args: [], // Runtime functions don't have compile-time arg info
            isStatic: type == StaticFunc,
            isInline: false
        };

        var stored:SerializableFunction = {
            id: id,
            info: functionInfo,
            type: type,
            body: ExpressionTree.EConst(ExpressionTree.ConstantTree.CIdent("__runtime")),
            bodyString: "/* runtime function */",
            originalFunction: func
        };

        _functions[id] = stored;

        trace('Stored runtime function ID ${id}: ${functionInfo.name} (${type})');
        return id;
    }

    /**
     * Get a stored function by ID
     */
    public static function getFunction(id:Int):SerializableFunction {
        if (id < 0 || id >= _functions.length) {
            return null;
        }
        return _functions[id];
    }

    /**
     * Call a stored function by ID using emulation or original function
     * @param id Function ID
     * @param args Arguments array
     * @param instance Instance for InstFunc calls
     * @return Function result
     */
    public static function callFunction(id:Int, ?args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        var stored = getFunction(id);
        if (stored == null) {
            throw 'Function with ID ${id} not found';
        }

        var finalArgs = args != null ? args : [];

        // Try original function first if available (performance optimization)
        if (stored.originalFunction != null) {
            return callOriginalFunction(stored, finalArgs, instance);
        }

        // Fall back to emulation
        return FunctionEmulator.emulate(stored, finalArgs, instance);
    }

    /**
     * Call the original stored function (faster path)
     */
    private static function callOriginalFunction(stored:SerializableFunction, args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        switch (stored.type) {
            case StaticFunc:
                return Reflect.callMethod(null, stored.originalFunction, args);

            case InstFunc:
                if (instance == null) {
                    throw 'Instance function (ID ${stored.id}) requires an instance of ${stored.info.className}';
                }

                // Validate instance type if className is specified
                if (stored.info.className != null) {
                    var instanceClass = Type.getClass(instance);
                    var expectedClass = Type.resolveClass(stored.info.className);

                    if (instanceClass == null || expectedClass == null || instanceClass != expectedClass) {
                        var actualClassName = instanceClass != null ? Type.getClassName(instanceClass) : "null";
                        throw 'Instance type mismatch for function ID ${stored.id}. Expected ${stored.info.className}, got ${actualClassName}';
                    }
                }

                return Reflect.callMethod(instance, stored.originalFunction, args);

            case AnonFunc:
                if (instance != null) {
                    return Reflect.callMethod(instance, stored.originalFunction, args);
                } else {
                    return Reflect.callMethod(null, stored.originalFunction, args);
                }
        }
    }

    /**
     * Remove original function references to prepare for serialization
     * @param id Function ID to prepare for serialization
     */
    public static function prepareForSerialization(id:Int):Void {
        var stored = getFunction(id);
        if (stored != null) {
            stored.originalFunction = null;
        }
    }

    /**
     * Remove original function references from all stored functions
     */
    public static function prepareAllForSerialization():Void {
        for (func in _functions) {
            if (func != null) {
                func.originalFunction = null;
            }
        }
    }

    /**
     * Serialize all functions to JSON-compatible format
     */
    public static function serialize():Array<Dynamic> {
        prepareAllForSerialization();
        return [for (func in _functions) if (func != null) func];
    }

    /**
     * Restore functions from serialized data
     */
    public static function deserialize(serializedFunctions:Array<Dynamic>):Void {
        clearAll();

        for (funcData in serializedFunctions) {
            if (funcData != null) {
                var func:SerializableFunction = cast funcData;
                if (func.id >= _nextId) {
                    _nextId = func.id + 1;
                }
                _functions[func.id] = func;
            }
        }

        trace('Deserialized ${getCount()} functions');
    }

    /**
     * Save all functions to a JSON file
     * @param filePath Path to save the functions file
     */
    public static function saveToFile(filePath:String):Bool {
        try {
            var serialized = serialize();
            var json = haxe.Json.stringify(serialized, null, "  ");
            sys.io.File.saveContent(filePath, json);
            trace('Saved ${getCount()} functions to ${filePath}');
            return true;
        } catch (e:Dynamic) {
            trace('Failed to save functions to ${filePath}: ${e}');
            return false;
        }
    }

    /**
     * Load functions from a JSON file
     * @param filePath Path to load the functions file from
     */
    public static function loadFromFile(filePath:String):Bool {
        try {
            if (!sys.FileSystem.exists(filePath)) {
                trace('Functions file does not exist: ${filePath}');
                return false;
            }

            var json = sys.io.File.getContent(filePath);
            var serialized:Array<Dynamic> = haxe.Json.parse(json);
            deserialize(serialized);
            trace('Loaded functions from ${filePath}');
            return true;
        } catch (e:Dynamic) {
            trace('Failed to load functions from ${filePath}: ${e}');
            return false;
        }
    }

    /**
     * Get all stored functions
     */
    public static function getAllFunctions():Array<StoredFunction> {
        return _functions.copy();
    }

    /**
     * Get functions by type
     */
    public static function getFunctionsByType(type:FuncType):Array<StoredFunction> {
        return _functions.filter(f -> f != null && f.type == type);
    }

    /**
     * Get functions by class name
     */
    public static function getFunctionsByClass(className:String):Array<StoredFunction> {
        return _functions.filter(f -> f != null && f.className == className);
    }

    /**
     * Remove a function from storage
     */
    public static function removeFunction(id:Int):Bool {
        if (id < 0 || id >= _functions.length || _functions[id] == null) {
            return false;
        }

        _functions[id] = null;
        return true;
    }

    /**
     * Clear all stored functions
     */
    public static function clearAll():Void {
        _functions = [];
        _nextId = 0;
    }

    /**
     * Get the number of stored functions
     */
    public static function getCount():Int {
        return _functions.filter(f -> f != null).length;
    }

    /**
     * Debug: Print all stored functions
     */
    public static function debugPrint():Void {
        trace('=== Function Storage Debug ===');
        trace('Total functions: ${getCount()}');

        for (info in getDebugInfo()) {
            trace(info);
        }

        trace('=== End Function Storage Debug ===');
    }

    /**
     * Get debug info for all stored functions
     */
    public static function getDebugInfo():Array<String> {
        var info:Array<String> = [];
        for (i in 0..._functions.length) {
            if (_functions[i] != null) {
                var func = _functions[i];
                info.push('ID ${i}: ${func.info.name} (${func.type}) - ${func.info.className != null ? func.info.className : "global"}');
            }
        }
        return info;
    }
}

/**
 * Function emulation system for executing serialized functions
 */
class FunctionEmulator {

    /**
     * Emulate function execution from ExpressionTree
     */
    public static function emulate(stored:SerializableFunction, args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        // Set up execution context
        var context = new Map<String, Dynamic>();

        // Add arguments to context
        for (i in 0...stored.info.args.length) {
            if (i < args.length) {
                context.set(stored.info.args[i].name, args[i]);
            }
        }

        // Add instance to context if needed
        if (instance != null) {
            context.set("this", instance);
        }

        // Execute the expression tree
        return executeExpressionTree(stored.body, context);
    }

    /**
     * Execute an ExpressionTree with given context
     */
    private static function executeExpressionTree(expr:ExpressionTree, context:Map<String, Dynamic>):Dynamic {
        switch (expr) {
            case EConst(c):
                return executeConstant(c, context);

            case ECall(func, args):
                var funcValue = executeExpressionTree(func, context);
                var argValues = [for (arg in args) executeExpressionTree(arg, context)];
                return Reflect.callMethod(null, funcValue, argValues);

            case EField(obj, field):
                var objValue = executeExpressionTree(obj, context);
                return Reflect.field(objValue, field);

            case EBinop(op, left, right):
                var leftValue = executeExpressionTree(left, context);
                var rightValue = executeExpressionTree(right, context);
                return executeBinop(op, leftValue, rightValue);

            case EUnop(op, prefix, expr):
                var exprValue = executeExpressionTree(expr, context);
                return executeUnop(op, exprValue, prefix);

            case EVar(name, type, init):
                var initValue = init != null ? executeExpressionTree(init, context) : null;
                context.set(name, initValue);
                return initValue;

            case EBlock(exprs):
                var result:Dynamic = null;
                for (blockExpr in exprs) {
                    result = executeExpressionTree(blockExpr, context);
                }
                return result;

            case EReturn(returnExpr):
                return returnExpr != null ? executeExpressionTree(returnExpr, context) : null;

            case EIf(condition, then, elseExpr):
                var condValue = executeExpressionTree(condition, context);
                if (condValue) {
                    return executeExpressionTree(then, context);
                } else if (elseExpr != null) {
                    return executeExpressionTree(elseExpr, context);
                }
                return null;

            case EWhile(condition, body):
                var result:Dynamic = null;
                while (executeExpressionTree(condition, context)) {
                    result = executeExpressionTree(body, context);
                }
                return result;

            case EFor(variable, iterable, body):
                var iterValue = executeExpressionTree(iterable, context);
                var result:Dynamic = null;
                // Simple iteration - could be enhanced
                if (Std.isOfType(iterValue, Array)) {
                    var arr:Array<Dynamic> = cast iterValue;
                    for (item in arr) {
                        context.set(variable, item);
                        result = executeExpressionTree(body, context);
                    }
                }
                return result;

            case EArray(arrayExpr, indexExpr):
                var arrayValue = executeExpressionTree(arrayExpr, context);
                var indexValue = executeExpressionTree(indexExpr, context);
                return Reflect.field(arrayValue, Std.string(indexValue));

            case EArrayDecl(elements):
                return [for (elem in elements) executeExpressionTree(elem, context)];

            case EObjectDecl(fields):
                var obj = {};
                for (field in fields) {
                    var value = executeExpressionTree(field.expr, context);
                    Reflect.setField(obj, field.field, value);
                }
                return obj;

            case ECast(expr, type):
                // Simple cast - just return the value
                return executeExpressionTree(expr, context);

            default:
                trace('Warning: Unhandled expression type in emulation: ${expr}');
                return null;
        }
    }

    /**
     * Execute constant expressions
     */
    private static function executeConstant(constant:ExpressionTree.ConstantTree, context:Map<String, Dynamic>):Dynamic {
        switch (constant) {
            case CIdent(name):
                if (name == "__runtime") {
                    throw "Cannot emulate runtime function - original function reference lost";
                }
                return context.get(name);

            case CInt(value):
                return value;

            case CFloat(value):
                return value;

            case CString(value):
                return value;

            case CBool(value):
                return value;

            case CNull:
                return null;
        }
    }

    /**
     * Execute binary operations
     */
    private static function executeBinop(op:String, left:Dynamic, right:Dynamic):Dynamic {
        switch (op) {
            case "+": return left + right;
            case "-": return left - right;
            case "*": return left * right;
            case "/": return left / right;
            case "%": return left % right;
            case "==": return left == right;
            case "!=": return left != right;
            case "<": return left < right;
            case ">": return left > right;
            case "<=": return left <= right;
            case ">=": return left >= right;
            case "&&": return left && right;
            case "||": return left || right;
            case "&": return left & right;
            case "|": return left | right;
            case "^": return left ^ right;
            case "<<": return left << right;
            case ">>": return right >> right;
            case ">>>": return left >>> right;
            default:
                trace('Warning: Unhandled binary operation: ${op}');
                return null;
        }
    }

    /**
     * Execute unary operations
     */
    private static function executeUnop(op:String, value:Dynamic, prefix:Bool):Dynamic {
        switch (op) {
            case "-": return -value;
            case "!": return !value;
            case "~": return ~value;
            case "++": return prefix ? ++value : value++;
            case "--": return prefix ? --value : value--;
            default:
                trace('Warning: Unhandled unary operation: ${op}');
                return value;
        }
    }
}
