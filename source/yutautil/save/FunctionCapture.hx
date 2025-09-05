package yutautil.save;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexTypeTools;
import haxe.macro.TypeTools;
import haxe.macro.ExprTools;
using haxe.macro.Tools;
#end

/**
 * Types for function serialization
 */
enum FunctionType {
    Static;
    Instance;
    Lambda;
    Anonymous;
}

typedef CapturedFunction = {
    var id:String;
    var className:String;
    var functionName:String;
    var functionType:FunctionType;
    var args:Array<CapturedArg>;
    var returnType:String;
    var body:ExpressionTree;  // Changed from String to ExpressionTree
    var bodyHScript:String;   // HScript version for when needed
    var isInline:Bool;
    var access:Array<String>;
}

typedef CapturedArg = {
    var name:String;
    var type:String;
    var isOptional:Bool;
    var defaultValue:Null<String>;
}

typedef CapturedConstructor = {
    var className:String;
    var args:Array<CapturedArg>;
    var body:ExpressionTree;
    var bodyHScript:String;
}

/**
 * Runtime function simulation and execution system
 */
class FunctionCapture {

    // Registry of captured functions
    private static var _capturedFunctions:Map<String, CapturedFunction> = new Map();
    private static var _capturedConstructors:Map<String, CapturedConstructor> = new Map();

    /**
     * Register a captured function
     */
    public static function registerFunction(func:CapturedFunction):Void {
        _capturedFunctions.set(func.id, func);
        trace('Registered function: ${func.id} (${func.functionType})');
    }

    /**
     * Register a captured constructor
     */
    public static function registerConstructor(constructor:CapturedConstructor):Void {
        _capturedConstructors.set(constructor.className, constructor);
        trace('Registered constructor for: ${constructor.className}');
    }

    /**
     * Execute a captured function by ID
     */
    public static function executeFunction(functionId:String, args:Array<Dynamic>, ?instance:Dynamic):Dynamic {
        var func = _capturedFunctions.get(functionId);
        if (func == null) {
            throw 'Function not found: ${functionId}';
        }

        return FunctionExecutor.execute(func, args, instance);
    }

    /**
     * Create an instance using captured constructor
     */
    public static function createInstance(className:String, args:Array<Dynamic>):Dynamic {
        var constructor = _capturedConstructors.get(className);
        if (constructor == null) {
            throw 'Constructor not found for class: ${className}';
        }

        // Create empty instance first
        var classType = Type.resolveClass(className);
        if (classType == null) {
            throw 'Class not found: ${className}';
        }

        var instance = Type.createEmptyInstance(classType);

        // Execute constructor body with instance context
        var constructorFunc:CapturedFunction = {
            id: '${className}.new_instance',
            className: className,
            functionName: 'new',
            functionType: Instance,
            args: constructor.args,
            returnType: 'Void',
            body: constructor.body,
            bodyHScript: constructor.bodyHScript,
            isInline: false,
            access: ['public']
        };

        FunctionExecutor.execute(constructorFunc, args, instance);
        return instance;
    }

    /**
     * Get function information
     */
    public static function getFunctionInfo(functionId:String):CapturedFunction {
        return _capturedFunctions.get(functionId);
    }

    /**
     * List all captured functions
     */
    public static function listFunctions():Array<String> {
        return [for (key in _capturedFunctions.keys()) key];
    }

    /**
     * List all captured constructors
     */
    public static function listConstructors():Array<String> {
        return [for (key in _capturedConstructors.keys()) key];
    }

    #if macro
    /**
     * Build macro for @:captureConstructor
     */
    public static function captureConstructor():Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass().get();

        // Find constructor
        var constructor:Field = null;
        for (field in fields) {
            if (field.name == "new") {
                constructor = field;
                break;
            }
        }

        if (constructor == null) {
            Context.error("No constructor found for @:captureConstructor", Context.currentPos());
            return fields;
        }

        // Capture constructor information
        var capturedConstructor = buildCapturedConstructor(localClass.name, constructor);

        // Add field to store constructor arguments
        var constructorArgsField:Field = {
            name: "__constructorArgs",
            access: [APublic],
            kind: FVar(macro:Array<Dynamic>, macro []),
            pos: Context.currentPos(),
            doc: "Stores constructor arguments for reconstruction"
        };

        // Add static method to reconstruct instance
        var reconstructorMethod:Field = {
            name: "reconstructInstance",
            access: [APublic, AStatic],
            kind: FFun({
                args: [{name: "args", type: macro:Array<Dynamic>}],
                ret: macro:Dynamic,
                expr: macro {
                    return yutautil.save.FunctionCapture.createInstance($v{localClass.name}, args);
                }
            }),
            pos: Context.currentPos(),
            doc: "Reconstructs an instance using captured constructor"
        };

        // Modify constructor to capture arguments and register itself
        if (constructor.kind.match(FFun(func))) {
            var captureExprs = generateCaptureExprs(func.args);
            var registerExpr = macro yutautil.save.FunctionCapture.registerConstructor($v{capturedConstructor});

            var newBody = macro {
                $registerExpr;
                $b{captureExprs};
                ${func.expr};
            };
            func.expr = newBody;
        }

        fields.push(constructorArgsField);
        fields.push(reconstructorMethod);

        return fields;
    }

    /**
     * Build macro for @:captureFunctions
     */
    public static function captureFunctions():Array<Field> {
        var fields = Context.getBuildFields();
        var localClass = Context.getLocalClass().get();

        var registrations:Array<Expr> = [];

        for (field in fields) {
            switch (field.kind) {
                case FFun(func):
                    if (field.name != "new") { // Skip constructor (handled separately)
                        var capturedFunc = buildCapturedFunction(localClass.name, field);

                        // Add registration call
                        registrations.push(macro yutautil.save.FunctionCapture.registerFunction($v{capturedFunc}));
                    }
                case FVar(type, expr) if (isFunctionVar(type)):
                    // Handle function variables
                    if (expr != null) {
                        var capturedFunc = buildCapturedFunctionVar(localClass.name, field);
                        registrations.push(macro yutautil.save.FunctionCapture.registerFunction($v{capturedFunc}));
                    }
                default:
                    // Skip non-function fields
            }
        }

        // Add static initialization method if we have registrations
        if (registrations.length > 0) {
            var initField:Field = {
                name: "__initFunctionCapture",
                access: [AStatic],
                kind: FFun({
                    args: [],
                    ret: macro:Void,
                    expr: macro $b{registrations}
                }),
                pos: Context.currentPos(),
                doc: "Initializes function capture registry"
            };
            fields.push(initField);

            // Add call to init in static constructor or first static method
            addStaticInitCall(fields);
        }

        return fields;
    }

    private static function buildCapturedConstructor(className:String, constructor:Field):CapturedConstructor {
        return switch (constructor.kind) {
            case FFun(func):
                var args = buildCapturedArgs(func.args);
                var bodyTree = convertExpressionToTree(func.expr);
                var bodyHScript = func.expr != null ? ExprTools.toString(func.expr) : "";

                {
                    className: className,
                    args: args,
                    body: bodyTree,
                    bodyHScript: bodyHScript
                };
            default:
                Context.error("Constructor must be a function", constructor.pos);
                null;
        }
    }

    private static function buildCapturedFunction(className:String, field:Field):CapturedFunction {
        return switch (field.kind) {
            case FFun(func):
                var functionType = determineFunctionType(field);
                var functionId = generateFunctionId(className, field.name, functionType);
                var args = buildCapturedArgs(func.args);
                var bodyTree = convertExpressionToTree(func.expr);
                var bodyHScript = func.expr != null ? ExprTools.toString(func.expr) : "";

                {
                    id: functionId,
                    className: className,
                    functionName: field.name,
                    functionType: functionType,
                    args: args,
                    returnType: func.ret != null ? ComplexTypeTools.toString(func.ret) : "Void",
                    body: bodyTree,
                    bodyHScript: bodyHScript,
                    isInline: field.access.indexOf(AInline) != -1,
                    access: [for (acc in field.access) acc.getName()]
                };
            default:
                Context.error("Field must be a function", field.pos);
                null;
        }
    }

    private static function buildCapturedFunctionVar(className:String, field:Field):CapturedFunction {
        var functionId = generateFunctionId(className, field.name, Lambda);

        // For function variables, we need to analyze the expression
        var bodyTree = field.kind.match(FVar(_, expr)) ? convertExpressionToTree(expr) : ExpressionTree.ENull;
        var bodyHScript = field.kind.match(FVar(_, expr)) && expr != null ? ExprTools.toString(expr) : "";

        return {
            id: functionId,
            className: className,
            functionName: field.name,
            functionType: Lambda,
            args: [], // Will be determined at runtime from the lambda expression
            returnType: "Dynamic",
            body: bodyTree,
            bodyHScript: bodyHScript,
            isInline: false,
            access: [for (acc in field.access) acc.getName()]
        };
    }

    private static function buildCapturedArgs(args:Array<FunctionArg>):Array<CapturedArg> {
        return args.map(function(arg) {
            return {
                name: arg.name,
                type: arg.type != null ? ComplexTypeTools.toString(arg.type) : "Dynamic",
                isOptional: arg.opt,
                defaultValue: arg.value != null ? ExprTools.toString(arg.value) : null
            };
        });
    }

    private static function convertExpressionToTree(expr:Expr):ExpressionTree {
        if (expr == null) {
            return ExpressionTree.ENull;
        }

        return switch (expr.expr) {
            case EConst(c):
                convertConstant(c);
            case EArray(e1, e2):
                ExpressionTree.EArray(convertExpressionToTree(e1), convertExpressionToTree(e2));
            case EBinop(op, e1, e2):
                ExpressionTree.EBinop(op.getName(), convertExpressionToTree(e1), convertExpressionToTree(e2));
            case EField(e, field):
                ExpressionTree.EField(convertExpressionToTree(e), field);
            case EParentheses(e):
                convertExpressionToTree(e); // Unwrap parentheses
            case EObjectDecl(fields):
                var fieldTrees = fields.map(f -> {field: f.field, expr: convertExpressionToTree(f.expr)});
                ExpressionTree.EObjectDecl(fieldTrees);
            case EArrayDecl(values):
                var valueTrees = values.map(convertExpressionToTree);
                ExpressionTree.EArrayDecl(valueTrees);
            case ECall(e, params):
                var paramTrees = params.map(convertExpressionToTree);
                ExpressionTree.ECall(convertExpressionToTree(e), paramTrees);
            case ENew(t, params):
                var paramTrees = params.map(convertExpressionToTree);
                ExpressionTree.ENew(t.name, t.pack, paramTrees);
            case EUnop(op, postFix, e):
                ExpressionTree.EUnop(op.getName(), postFix, convertExpressionToTree(e));
            case EVars(vars):
                var varTrees = vars.map(v -> {
                    name: v.name,
                    type: v.type != null ? ComplexTypeTools.toString(v.type) : null,
                    expr: v.expr != null ? convertExpressionToTree(v.expr) : ExpressionTree.ENull
                });
                ExpressionTree.EVars(varTrees);
            case EFunction(kind, f):
                var funcTree = convertFunctionToTree(f);
                ExpressionTree.EFunction(kind != null ? kind.getName() : "anonymous", funcTree);
            case EBlock(exprs):
                var exprTrees = exprs.map(convertExpressionToTree);
                ExpressionTree.EBlock(exprTrees);
            case EFor(it, expr):
                ExpressionTree.EFor(convertExpressionToTree(it), convertExpressionToTree(expr));
            case EIf(econd, eif, eelse):
                var elseTree = eelse != null ? convertExpressionToTree(eelse) : ExpressionTree.ENull;
                ExpressionTree.EIf(convertExpressionToTree(econd), convertExpressionToTree(eif), elseTree);
            case EWhile(econd, e, normalWhile):
                ExpressionTree.EWhile(convertExpressionToTree(econd), convertExpressionToTree(e), normalWhile);
            case ESwitch(e, cases, edef):
                var caseTrees = cases.map(convertCaseToTree);
                var defaultTree = edef != null ? convertExpressionToTree(edef) : ExpressionTree.ENull;
                ExpressionTree.ESwitch(convertExpressionToTree(e), caseTrees, defaultTree);
            case ETry(e, catches):
                var catchTrees = catches.map(convertCatchToTree);
                ExpressionTree.ETry(convertExpressionToTree(e), catchTrees);
            case EReturn(e):
                var returnTree = e != null ? convertExpressionToTree(e) : ExpressionTree.ENull;
                ExpressionTree.EReturn(returnTree);
            case EBreak:
                ExpressionTree.EBreak;
            case EContinue:
                ExpressionTree.EContinue;
            case EThrow(e):
                ExpressionTree.EThrow(convertExpressionToTree(e));
            case ECast(e, t):
                var typeStr = t != null ? ComplexTypeTools.toString(t) : null;
                ExpressionTree.ECast(convertExpressionToTree(e), typeStr);
            case EDisplay(e, displayKind):
                convertExpressionToTree(e); // Ignore display information
            case EDisplayNew(t):
                ExpressionTree.ENew(t.name, t.pack, []);
            case ETernary(econd, eif, eelse):
                ExpressionTree.ETernary(convertExpressionToTree(econd), convertExpressionToTree(eif), convertExpressionToTree(eelse));
            case ECheckType(e, t):
                ExpressionTree.ECheckType(convertExpressionToTree(e), ComplexTypeTools.toString(t));
            case EMeta(s, e):
                // For now, ignore metadata and just process the expression
                convertExpressionToTree(e);
            case EIs(e, t):
                ExpressionTree.EIs(convertExpressionToTree(e), ComplexTypeTools.toString(t));
        };
    }

    private static function convertConstant(c:Constant):ExpressionTree {
        var constTree = switch (c) {
            case CInt(v): ConstantTree.CInt(v);
            case CFloat(f): ConstantTree.CFloat(f);
            case CString(s, kind): ConstantTree.CString(s);
            case CIdent(s): ConstantTree.CIdent(s);
            case CRegexp(r, opt): ConstantTree.CRegexp(r, opt);
        };
        return ExpressionTree.EConst(constTree);
    }

    private static function convertFunctionToTree(func:Function):FunctionTree {
        var argTrees = func.args.map(arg -> {
            name: arg.name,
            type: arg.type != null ? ComplexTypeTools.toString(arg.type) : "Dynamic",
            opt: arg.opt,
            value: arg.value != null ? ExprTools.toString(arg.value) : null
        });

        return {
            args: argTrees,
            ret: func.ret != null ? ComplexTypeTools.toString(func.ret) : "Dynamic",
            expr: convertExpressionToTree(func.expr)
        };
    }

    private static function convertCaseToTree(caseItem:Case):CaseTree {
        return {
            values: caseItem.values.map(convertExpressionToTree),
            guard: caseItem.guard != null ? convertExpressionToTree(caseItem.guard) : ExpressionTree.ENull,
            expr: convertExpressionToTree(caseItem.expr)
        };
    }

    private static function convertCatchToTree(catchItem:Catch):CatchTree {
        return {
            name: catchItem.name,
            type: catchItem.type != null ? ComplexTypeTools.toString(catchItem.type) : null,
            expr: convertExpressionToTree(catchItem.expr)
        };
    }

    private static function generateCaptureExprs(args:Array<FunctionArg>):Array<Expr> {
        var exprs:Array<Expr> = [];

        for (i in 0...args.length) {
            var arg = args[i];
            var argName = arg.name;
            exprs.push(macro this.__constructorArgs.push($i{argName}));
        }

        return exprs;
    }

    private static function determineFunctionType(field:Field):FunctionType {
        if (field.access.indexOf(AStatic) != -1) {
            return Static;
        } else if (field.access.indexOf(AInline) != -1) {
            return Instance; // Inline functions are still instance methods
        } else {
            return Instance;
        }
    }

    private static function generateFunctionId(className:String, functionName:String, type:FunctionType):String {
        return '${className}.${functionName}.${type.getName()}';
    }

    private static function isFunctionVar(type:ComplexType):Bool {
        if (type == null) return false;
        return switch (type) {
            case TFunction(_, _): true;
            case _: false;
        };
    }

    private static function addStaticInitCall(fields:Array<Field>):Void {
        // Look for existing static constructor or add one
        var hasStaticConstructor = false;
        for (field in fields) {
            if (field.name == "__init__" && field.access.indexOf(AStatic) != -1) {
                hasStaticConstructor = true;
                if (field.kind.match(FFun(func))) {
                    var initCall = macro __initFunctionCapture();
                    if (func.expr.expr.match(EBlock(exprs))) {
                        exprs.unshift(initCall);
                    } else {
                        func.expr = macro {
                            $initCall;
                            ${func.expr};
                        };
                    }
                }
                break;
            }
        }

        if (!hasStaticConstructor) {
            var staticInit:Field = {
                name: "__init__",
                access: [AStatic],
                kind: FFun({
                    args: [],
                    ret: macro:Void,
                    expr: macro __initFunctionCapture()
                }),
                pos: Context.currentPos(),
                doc: "Static initializer for function capture"
            };
            fields.push(staticInit);
        }
    }
    #end
}
